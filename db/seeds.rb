# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

%w[organizer participant operator].each do |role|
  User.find_or_create_by!(role: role) do |user|
    # Prefixed so that seeding does not collide with a real GitHub handle such
    # as "organizer", which uniqueness now compares case-insensitively.
    user.name = "seed-#{role}"
    user.build_profile(name: role.capitalize)
    user.build_authentication_provider_email_and_password(email: "#{role}@example.invalid", password: "password", password_confirmation: "password")
  end
end

event_2023 = Event.find_or_create_by!(name: "Kaigi on Rails 2023", slug: "2023") do |event|
  event.start_date = Time.zone.parse("2023-10-27 00:00:00 +0900")
  event.end_date = Time.zone.parse("2023-10-28 23:59:59 +0900")
end

TalkImporter.new(event: event_2023).import! if event_2023.talks.empty?

if OngoingEvent.count.zero?
  OngoingEvent.create!(event: event_2023)
end

event_2024 = Event.find_or_create_by!(name: "Kaigi on Rails 2024", slug: "2024") do |event|
  event.start_date = Time.zone.parse("2024-10-25 00:00:00 +0900")
  event.end_date = Time.zone.parse("2024-10-26 23:59:59 +0900")
end

TalkImporter.new(event: event_2024).import! if event_2024.talks.empty?

event_2025 = Event.find_or_create_by!(name: "Kaigi on Rails 2025", slug: "2025") do |event|
  event.start_date = Time.zone.parse("2025-09-26 00:00:00 +0900")
  event.end_date = Time.zone.parse("2025-09-27 23:59:59 +0900")
end

TalkImporter.new(event: event_2025).import! if event_2025.talks.empty?

event_2026 = Event.find_or_create_by!(name: "Kaigi on Rails 2026", slug: "2026") do |event|
  event.start_date = Time.zone.parse("2026-10-16 00:00:00 +0900")
  event.end_date = Time.zone.parse("2026-10-17 23:59:59 +0900")
end

TalkImporter.new(event: event_2026).import! if event_2026.talks.empty?

ongoing_event = OngoingEvent.first

if ongoing_event.event != event_2026
  ongoing_event.update!(event: event_2026)
end
