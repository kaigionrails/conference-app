FactoryBot.define do
  factory :speaker do
    name { "David Heinemeier Hansson" }
    slug { "dhh" }
    github_username { "dhh" }
    gravatar_hash { "c4b8d5a87142f97a74fa9f055b99222e" } # dhh@hey.com
    bio {
      # https://dhh.dk/
      <<~DHH
        I am the creator of Ruby on Rails, cofounder of Basecamp &
        HEY, best-selling author, Le Mans class-winning racing
        driver, antitrust advocate, investor in Danish startups,
        frequent podcast guest, and family man.
      DHH
    }
  end
end
