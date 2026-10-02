// Load test for the profile pages, where an attendee's friends are listed
// with their images. One iteration is one page view, alternating for each
// attendee between a friend's page (/@:handle, as after exchanging profiles by
// QR code) and their own /profiles: the HTML, /sw.js (the browser checks it on
// every page load), and the assets and images the page refers to.
//
// Prepare staging with `bin/rails load_test:seed` (lib/tasks/load_test.rake),
// which makes every test user a friend of FRIENDS_PER_USER others, then, from
// the repository root:
//
//   BASE_URL=https://app-staging.kaigionrails.org \
//   LOAD_TEST_PASSWORD=... PROFILE=step \
//   K6_WEB_DASHBOARD=true K6_WEB_DASHBOARD_EXPORT=tmp/load_test/report.html \
//   k6 run script/load_test/profile.js
//
// Options (environment variables):
//   BASE_URL            where to send requests (required)
//   ORIGIN_SECRET       X-Origin-Secret, needed when BASE_URL is the origin
//   APP_URL             absolute URLs on this host are fetched from BASE_URL
//                       instead (default: https://app-staging.kaigionrails.org)
//   USERS               attendees, matching load_test:seed (default: 1000)
//   FRIENDS_PER_USER    friends per attendee, matching load_test:seed
//                       (default: 90)
//   MOBILE_RATIO        share with a smartphone user agent (default: 0.8)
//   LOAD_TEST_PASSWORD  the password load_test:seed was given (required)
//   PROFILE             step | peak | smoke (default: step)
//   SUBRESOURCES        always | first-visit | never (default: always)
//   ABORT_LATENCY_MS    abort the whole test once a profile page takes longer
//                       than this, 0 to never abort (default: 10000)
//   MAX_VUS             default: 300
//
// Every attendee is logged in: /profiles requires it. Images are all fetched,
// those in the closed <details> of past events included, and by default on
// every page view, since a friend's page lists different people each time.
//
// Staging shares its host with production. The test aborts itself on the first
// profile page that fails or takes longer than ABORT_LATENCY_MS.

import http from "k6/http";
import { check, fail } from "k6";
import exec from "k6/execution";

const BASE_URL = required("BASE_URL").replace(/\/$/, "");
const ORIGIN_SECRET = __ENV.ORIGIN_SECRET || "";
const APP_URL = (__ENV.APP_URL || "https://app-staging.kaigionrails.org").replace(/\/$/, "");
const USERS = number("USERS", 1000);
const FRIENDS_PER_USER = number("FRIENDS_PER_USER", 90);
const MOBILE_RATIO = number("MOBILE_RATIO", 0.8);
const SUBRESOURCES = __ENV.SUBRESOURCES || "always";
const ABORT_LATENCY_MS = number("ABORT_LATENCY_MS", 10000);
const PROFILE = __ENV.PROFILE || "step";

const SESSION_COOKIE = "_conference_app_session";
const LOGIN_BATCH = 10;
const MOBILE_UA =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1";
const DESKTOP_UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36";

// Page views per second.
const PROFILES = {
  // One step a minute, to find the rate at which latency breaks down.
  step: [2, 4, 6, 8, 10, 12, 15, 20].flatMap((rate) => [
    { target: rate, duration: "10s" },
    { target: rate, duration: "50s" },
  ]),
  // The target: 20 page views per second held for five minutes.
  peak: [
    { target: 20, duration: "1m" },
    { target: 20, duration: "5m" },
  ],
  // Checks the script and the data before a real run.
  smoke: [{ target: 1, duration: "30s" }],
};

if (!PROFILES[PROFILE]) fail(`unknown PROFILE: ${PROFILE}`);
if (FRIENDS_PER_USER % 2 !== 0 || FRIENDS_PER_USER >= USERS) fail("FRIENDS_PER_USER must be even and less than USERS");

export const options = {
  setupTimeout: "10m",
  scenarios: {
    page_views: {
      executor: "ramping-arrival-rate",
      startRate: 1,
      timeUnit: "1s",
      preAllocatedVUs: 50,
      maxVUs: number("MAX_VUS", 300),
      stages: PROFILES[PROFILE],
    },
  },
  // Listed so that the summary reports each kind of request on its own.
  thresholds: {
    "http_req_duration{page:user}": ["p(95)<3000"],
    "http_req_duration{page:profiles}": ["p(95)<3000"],
    "http_req_duration{page:sw}": ["p(95)<3000"],
    "http_req_duration{page:asset}": ["p(95)<3000"],
    "http_req_duration{page:image}": ["p(95)<3000"],
    "http_req_failed{page:user}": ["rate<0.01"],
    "http_req_failed{page:profiles}": ["rate<0.01"],
  },
  summaryTrendStats: ["avg", "med", "p(90)", "p(95)", "p(99)", "max"],
};

export function setup() {
  if (!__ENV.LOAD_TEST_PASSWORD) fail("LOAD_TEST_PASSWORD is required to log users in");

  const sessions = [];
  for (let first = 0; first < USERS; first += LOGIN_BATCH) {
    const users = range(first, Math.min(first + LOGIN_BATCH, USERS));
    const jars = users.map(() => new http.CookieJar());

    const forms = http.batch(users.map((_, i) => ["GET", `${BASE_URL}/login`, null, params({ jar: jars[i], tags: { page: "setup" } })]));
    const logins = http.batch(
      users.map((user, i) => {
        const token = forms[i].html().find('form[action="/auth/email"] input[name="authenticity_token"]').attr("value");
        if (!token) fail(`no login form for ${email(user)}: ${forms[i].status}`);
        const body = { email: email(user), password: __ENV.LOAD_TEST_PASSWORD, authenticity_token: token };
        return ["POST", `${BASE_URL}/auth/email`, body, params({ jar: jars[i], redirects: 0, tags: { page: "setup" } })];
      }),
    );

    logins.forEach((res, i) => {
      const location = res.headers.Location || "";
      if (res.status !== 302 || location.includes("/login")) fail(`login failed for ${email(users[i])}: ${res.status} ${location}`);
      sessions.push(jars[i].cookiesForURL(BASE_URL)[SESSION_COOKIE][0]);
    });
  }
  console.log(`logged in ${sessions.length} users`);
  return { sessions };
}

export default function (data) {
  // Attendees take turns, so each of them comes back every USERS page views
  // and the first USERS page views are everyone's first visit. Each comes back
  // to the other kind of page than the last time.
  const n = exec.scenario.iterationInTest;
  const user = n % USERS;
  const visit = Math.floor(n / USERS);
  const firstVisit = visit === 0;
  const page = (user + visit) % 2 === 0 ? "user" : "profiles";

  // A browser of its own, with nothing left over from whoever this VU played
  // before.
  const jar = new http.CookieJar();
  jar.set(BASE_URL, SESSION_COOKIE, data.sessions[user]);
  const userAgent = (user * 37) % 100 < MOBILE_RATIO * 100 ? MOBILE_UA : DESKTOP_UA;
  const request = (tag, extra = {}) => params({ jar, headers: { "User-Agent": userAgent }, tags: { page: tag }, ...extra });

  const path = page === "user" ? `/@${handle(friendOf(user))}` : "/profiles";
  const res = http.get(`${BASE_URL}${path}`, request(page, { redirects: 0 }));
  check(res, {
    "profile page is 200": (r) => r.status === 200,
    // The logout button is only there for a logged-in attendee.
    "logged in as expected": (r) => r.status !== 200 || r.body.includes('action="/logout"'),
  });
  abortIfDown(res, path);

  http.get(`${BASE_URL}/sw.js`, request("sw"));

  if (SUBRESOURCES === "always" || (SUBRESOURCES === "first-visit" && firstVisit)) {
    const requests = subresources(res).map(({ url, tag }) => ["GET", url, null, request(tag)]);
    if (requests.length > 0) http.batch(requests);
  }
}

// One of the FRIENDS_PER_USER / 2 attendees on either side of this one, in the
// ring load_test:seed lays the users out in.
function friendOf(user) {
  const distance = 1 + Math.floor(Math.random() * (FRIENDS_PER_USER / 2));
  const offset = Math.random() < 0.5 ? -distance : distance;
  return (((user + offset) % USERS) + USERS) % USERS;
}

// Stylesheets, scripts and images served by the app, as a browser would fetch
// them. Other hosts (Gravatar, jsDelivr) are left out.
function subresources(res) {
  const doc = res.html();
  const found = [];
  doc.find('script[src], link[rel="stylesheet"][href]').each((_, el) => found.push({ src: el.getAttribute("src") || el.getAttribute("href"), tag: "asset" }));
  doc.find("img[src]").each((_, el) => found.push({ src: el.getAttribute("src"), tag: "image" }));

  const seen = new Set();
  return found
    .map(({ src, tag }) => ({ url: resolve(src), tag }))
    .filter(({ url }) => url && !seen.has(url) && seen.add(url));
}

function resolve(src) {
  if (!src) return null;
  if (src.startsWith("/") && !src.startsWith("//")) return `${BASE_URL}${src}`;
  if (src.startsWith(`${APP_URL}/`)) return `${BASE_URL}${src.slice(APP_URL.length)}`;
  if (src.startsWith(`${BASE_URL}/`)) return src;
  return null;
}

function abortIfDown(res, path) {
  if (ABORT_LATENCY_MS <= 0) return;
  if (res.status !== 200 || res.timings.duration > ABORT_LATENCY_MS) {
    exec.test.abort(`${path} returned ${res.status} in ${Math.round(res.timings.duration)}ms at iteration ${exec.scenario.iterationInTest}`);
  }
}

function params({ headers = {}, ...rest }) {
  return {
    timeout: "30s",
    headers: ORIGIN_SECRET ? { "X-Origin-Secret": ORIGIN_SECRET, ...headers } : headers,
    ...rest,
  };
}

function handle(user) {
  return `loadtest-${String(user + 1).padStart(4, "0")}`;
}

function email(user) {
  return `${handle(user)}@example.invalid`;
}

function range(from, to) {
  return Array.from({ length: to - from }, (_, i) => from + i);
}

function required(name) {
  if (!__ENV[name]) fail(`${name} is required`);
  return __ENV[name];
}

function number(name, fallback) {
  return __ENV[name] === undefined ? fallback : Number(__ENV[name]);
}
