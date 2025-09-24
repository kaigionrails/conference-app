# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

%w[organizer participant operator].each do |role|
  User.find_or_create_by!(role: role) do |user|
    user.name = role.capitalize
    user.build_profile(name: user.name)
    user.build_authentication_provider_email_and_password(email: "#{role}@example.invalid", password: "password", password_confirmation: "password")
  end
end

event_2023 = Event.find_or_create_by!(name: "Kaigi on Rails 2023", slug: "2023") do |event|
  event.start_date = Time.zone.parse("2023-10-27 00:00:00 +0900")
  event.end_date = Time.zone.parse("2023-10-28 23:59:59 +0900")
end

if event_2023.talks.empty?
  talks_2023 = YAML.unsafe_load_file(Rails.root.join("db/seeds/2023.yaml"), symbolize_names: true)

  ApplicationRecord.transaction do
    talks_2023[:talks].each do |talk_data|
      talk = Talk.create!(
        event: event_2023,
        title: talk_data[:title],
        abstract: talk_data[:abstract],
        start_at: talk_data[:start_at],
        duration_minutes: talk_data[:duration_minutes],
        track: talk_data[:track]
      )

      talk.speakers << talk_data[:speakers].map do |speaker_data|
        Speaker.find_or_create_by!(
          name: speaker_data[:name],
          slug: speaker_data[:slug],
          github_username: speaker_data[:github_username],
          gravatar_hash: speaker_data[:gravatar_hash],
          bio: speaker_data[:bio]
        )
      end
    end
  end
end

if OngoingEvent.count.zero?
  OngoingEvent.create!(event: event_2023)
end

event_2024 = Event.find_or_create_by!(name: "Kaigi on Rails 2024", slug: "2024") do |event|
  event.start_date = Time.zone.parse("2024-10-25 00:00:00 +0900")
  event.end_date = Time.zone.parse("2024-10-26 23:59:59 +0900")
end

if event_2024.talks.empty?
  talks_2024 = YAML.unsafe_load_file(Rails.root.join("db/seeds/2024.yaml"), symbolize_names: true)

  ApplicationRecord.transaction do
    talks_2024[:talks].each do |talk_data|
      talk = Talk.create!(
        event: event_2024,
        title: talk_data[:title],
        abstract: talk_data[:abstract],
        start_at: talk_data[:start_at],
        duration_minutes: talk_data[:duration_minutes],
        track: talk_data[:track]
      )

      talk.speakers << talk_data[:speakers].map do |speaker_data|
        Speaker.find_or_create_by!(slug: speaker_data[:slug]) do |speaker|
          speaker.name = speaker_data[:name]
          speaker.github_username = speaker_data[:github_username]
          speaker.gravatar_hash = speaker_data[:gravatar_hash]
          speaker.bio = speaker_data[:bio]
        end
      end

      Rails.logger.info "Created talk: #{talk.title}"
    end
  end
end

event_2025 = Event.find_or_create_by!(name: "Kaigi on Rails 2025", slug: "2025") do |event|
  event.start_date = Time.zone.parse("2025-09-26 00:00:00 +0900")
  event.end_date = Time.zone.parse("2025-09-27 23:59:59 +0900")
end

if event_2025.talks.empty?
  talks_2025 = YAML.unsafe_load_file(Rails.root.join("db/seeds/2025.yaml"), symbolize_names: true)

  ApplicationRecord.transaction do
    talks_2025[:talks].each do |talk_data|
      talk = Talk.create!(
        event: event_2025,
        title: talk_data[:title],
        abstract: talk_data[:abstract],
        start_at: talk_data[:start_at],
        duration_minutes: talk_data[:duration_minutes],
        track: talk_data[:track]
      )

      talk.speakers << talk_data[:speakers].map do |speaker_data|
        speaker = Speaker.find_or_initialize_by(slug: speaker_data[:slug])
        speaker.name = speaker_data[:name]
        speaker.github_username = speaker_data[:github_username]
        speaker.gravatar_hash = speaker_data[:gravatar_hash]
        speaker.bio = speaker_data[:bio]
        speaker.save! if speaker.new_record? || speaker.changed?
        speaker
      end

      Rails.logger.info "Created talk: #{talk.title}"
    end
  end
end

ongoing_event = OngoingEvent.first

if ongoing_event != event_2025
  ongoing_event.update!(event: event_2025)
end
