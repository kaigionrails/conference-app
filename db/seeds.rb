# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

event_2023 = Event.find_or_create_by(
  name: "Kaigi on Rails 2023",
  slug: "2023",
  start_date: Time.zone.parse("2023-10-27 00:00:00 +0900"),
  end_date: Time.zone.parse("2023-10-28 23:59:59 +0900"),
)
