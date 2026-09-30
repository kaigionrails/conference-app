# Test data for load testing staging with script/load_test/talks.js.
#
#   kamal app exec -d staging --reuse 'env LOAD_TEST_PASSWORD=... bin/rails load_test:seed'
#   kamal app exec -d staging --reuse 'bin/rails load_test:clean'
#
# Staging runs with RAILS_ENV=production, so the guard looks at SENTRY_ENV, the
# one variable that tells the two destinations apart.
namespace :load_test do
  user_prefix = "loadtest-"
  announcement_prefix = "[load test] "

  task guard: :environment do
    if Rails.env.production? && ENV["SENTRY_ENV"] != "staging"
      abort "load_test tasks only run on staging (SENTRY_ENV=#{ENV["SENTRY_ENV"].inspect})"
    end
  end

  desc "Create users with profile images, unread announcements and bookmarks for load testing"
  task seed: :guard do
    require "vips"

    user_count = Integer(ENV.fetch("USERS", "1000"))
    announcement_count = Integer(ENV.fetch("ANNOUNCEMENTS", "30"))
    bookmarks_per_user = Integer(ENV.fetch("BOOKMARKS_PER_USER", "5"))
    password = ENV.fetch("LOAD_TEST_PASSWORD")

    # The same event the header counts unread announcements for.
    event = OngoingEvent.first&.event || Event.find_by(slug: Event::ONGOING_EVENT_SLUG) or abort "no current event"
    now = Time.current

    # Logging in is not what is under test, so the digest uses the cheapest cost
    # and is shared by everyone. k6 logs every user in before the test starts.
    password_digest = BCrypt::Password.create(password, cost: BCrypt::Engine::MIN_COST)

    names = (1..user_count).map { |i| format("%s%04d", user_prefix, i) }
    User.insert_all(names.map { |name| {name:, role: "participant", created_at: now, updated_at: now} })
    users = User.where(name: names).order(:name).to_a
    user_ids = users.map(&:id)

    with_profile = Profile.where(user_id: user_ids).pluck(:user_id).to_set
    profiles = users.reject { |user| with_profile.include?(user.id) }
      .map { |user| {user_id: user.id, name: user.name, description: "", created_at: now, updated_at: now} }
    Profile.insert_all(profiles) if profiles.any?
    AuthenticationProviderEmailAndPassword.insert_all(
      users.map { |user| {user_id: user.id, email: "#{user.name}@example.invalid", password_digest:, created_at: now, updated_at: now} }
    )

    # A distinct image per user, as real profiles have, so that every header
    # icon is a variant of its own. The blob is marked as analyzed to keep an
    # AnalyzeJob per user off the job container.
    Profile.where(user_id: user_ids).where.missing(:images_attachments).find_each.with_index do |profile, i|
      noise = Array.new(3) { Vips::Image.gaussnoise(460, 460).gaussblur(1.5) }
      image = noise.first.bandjoin(noise.drop(1)).cast(:uchar)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(image.jpegsave_buffer(Q: 80)),
        filename: "#{profile.name}.jpg",
        content_type: "image/jpeg",
        metadata: {identified: true, analyzed: true, width: 460, height: 460}
      )
      profile.images.attach(blob)
      puts "profile images: #{i + 1}" if (i + 1) % 100 == 0
    end

    missing = announcement_count - Announcement.where(event:).published.count
    if missing > 0
      Announcement.insert_all(
        (1..missing).map { |i| {event_id: event.id, title: "#{announcement_prefix}#{i}", status: "published", published_at: now, created_at: now, updated_at: now} }
      )
    end
    announcement_ids = Announcement.where(event:).published.ids
    unread = user_ids.product(announcement_ids).map { |user_id, announcement_id| {user_id:, announcement_id:, created_at: now, updated_at: now} }
    UnreadAnnouncement.insert_all(unread) if unread.any?

    # Bookmarks only: TalkBookmarksController would also create reminders, and
    # those would make the job container send push notifications at talk time.
    talk_ids = event.talks.ids
    with_bookmarks = TalkBookmark.where(user_id: user_ids).distinct.pluck(:user_id).to_set
    bookmarks = (user_ids - with_bookmarks.to_a).flat_map do |user_id|
      talk_ids.sample(bookmarks_per_user).map { |talk_id| {user_id:, talk_id:, created_at: now, updated_at: now} }
    end
    TalkBookmark.insert_all(bookmarks) if bookmarks.any?

    speaker_count = Speaker.joins(:talks).where(talks: {event:}).distinct.count
    puts "event=#{event.slug} users=#{users.size} talks=#{talk_ids.size} speakers=#{speaker_count} " \
      "announcements=#{announcement_ids.size} unread=#{UnreadAnnouncement.where(user_id: user_ids).count} " \
      "bookmarks=#{TalkBookmark.where(user_id: user_ids).count} " \
      "profile_images=#{Profile.where(user_id: user_ids).joins(:images_attachments).count}"
  end

  desc "Delete what load_test:seed created"
  task clean: :guard do
    users = User.where("name LIKE ?", "#{user_prefix}%")
    puts "deleting #{users.count} users"
    users.find_each(&:destroy!)

    announcements = Announcement.where("title LIKE ?", "#{announcement_prefix}%")
    puts "deleting #{announcements.count} announcements"
    UnreadAnnouncement.where(announcement: announcements).delete_all
    announcements.find_each(&:destroy!)
  end
end
