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

The app is built with Ruby on Rails 7. It uses `importmap-rails`, `turbo-rails`, `stimulus-rails` and `tailwindcss-rails` for front end development.

## Setup dev environment
### Environment variables
See [`.env.sample`](.env.sample) for required/optional environment variables.

### Create GitHub App
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

After that, you can see 2023's event talks and speakers.

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
