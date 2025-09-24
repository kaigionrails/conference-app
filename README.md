# README

## 日本語

[こちら](README_ja.md)

## About

Conference app is an app for (yes) conferences. The scope of this app is audiences and the interaction between them and organizers.

It's built with Ruby on Rails.

## Features

* Talk list
* Announcements
* Profile
* Push notification

## Planned features

* Anonymous Q&A for each talk
* Forum for each talk and the whole event

## Stack

The app is built with Ruby on Rails 8. It uses `importmap-rails`, `turbo-rails`, `stimulus-rails` and `tailwindcss-rails` for front end development.

## Setup dev environment

### Setup user

#### Seed user login

Visit http://localhost:3000/login and you can login with the seed users. Note that this page is not linked from anywhere so you have to enter the URL manually.

#### GitHub login

##### Environment variables
See [`.env.sample`](.env.sample) for required/optional environment variables.

##### Create GitHub App
Current implementation requires GitHub App when you create a user.

<https://github.com/settings/apps/new>

* Callback URL: `http://localhost:3000/auth/github/callback`
* Webhook: inactive
* Permissions: Allow read-only access for "Organization permissions" -> "Members"

Then, fill these environment variables.

* App ID -> `GITHUB_APP_ID`
* Client ID -> `GITHUB_KEY`
* Client secret -> `GITHUB_SECRET`
* Private key (encoded) -> `GITHUB_PRIVATE_KEY` (See [`.env.sample`](.env.sample))

### Load seed data

```shell
$ bin/rails db:seed
```

After that, you can see event talks and speakers for 2023 and beyond.

- 2023: http://localhost:3000/2023/talks
- 2024: http://localhost:3000/2024/talks

## Setup dev environment with docker
```bash
$ cp .env.sample .env
```

Generate required environment variables
```bash
$ docker compose exec -it conference-app rails c

$ vapid_key = WebPush.generate_key
$ vapid_key.public_key
#=> "YOUR_PUBLIC_KEY"
$ vapid_key.private_key
#=> "YOUR_PRIVATE_KEY"
```

Copy to `.env`
```bash
VAPID_PUBLIC_KEY=YOUR_PUBLIC_KEY
VAPID_PRIVATE_KEY=YOUR_PRIVATE_KEY
```

And then execute below
```bash
$ docker compose up
$ docker compose exec conference-app rails db:prepare
```

## Acknowledgment
### Scout APM

![Scout APM logo](https://github.com/kaigionrails/conference-app/assets/4487291/7c300827-25ad-4fde-9f04-54a6419a3b61)

This app uses <https://scoutapm.com/> for performance monitoring.
