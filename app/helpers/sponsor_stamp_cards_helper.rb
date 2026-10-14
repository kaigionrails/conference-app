module SponsorStampCardsHelper
  def completion_badge_icon_path(completion)
    slug = completion.event.slug
    (slug == "2026") ? "2026/logos/hachiko.svg" : "icons/#{slug}/512.png"
  end
end
