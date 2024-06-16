# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

event_2023 = Event.find_or_create_by!(
  name: "Kaigi on Rails 2023",
  slug: "2023",
  start_date: Time.zone.parse("2023-10-27 00:00:00 +0900"),
  end_date: Time.zone.parse("2023-10-28 23:59:59 +0900")
)

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
