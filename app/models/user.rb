class User < ApplicationRecord
  class HandleGenerationError < StandardError; end

  # users.name is the public handle: it addresses /@:username and is the issuer
  # of the profile exchange QR token. GitHub used to guarantee its uniqueness
  # for us, which stops being true as soon as a user arrives from anywhere else.
  HANDLE_FORMAT = /\A[a-zA-Z0-9][a-zA-Z0-9_-]{0,38}\z/

  # Four-digit numbers stand in for event slugs (2023, 2024, ...) so that a
  # future one cannot be squatted. Listing them in reserved_handles.yml would
  # only duplicate this.
  RESERVED_HANDLE_FORMAT = /\A\d{4}\z/

  RESERVED_HANDLES = YAML.load_file(Rails.root.join("config/reserved_handles.yml")).map(&:downcase).freeze

  HANDLE_GENERATION_ATTEMPTS = 10

  has_one :authentication_provider_github, dependent: :destroy
  has_one :authentication_provider_google, dependent: :destroy
  has_one :authentication_provider_email_and_password, dependent: :destroy
  has_one :profile, dependent: :destroy
  has_one :locale_setting, dependent: :destroy
  has_many :webpush_subscriptions, dependent: :destroy
  has_many :unread_announcements, dependent: :destroy
  has_many :talk_bookmarks, dependent: :destroy
  has_many :profile_exchanges, dependent: :destroy
  has_many :friends, through: :profile_exchanges, class_name: "User"
  has_many :talk_reminders, dependent: :destroy
  has_many :tito_tickets, dependent: :nullify

  enum :role, {organizer: "organizer", participant: "participant", operator: "operator"}

  # The handle is stored as typed (GitHub's "Octocat" stays "Octocat"); only
  # uniqueness and lookup are case-insensitive.
  validates :name, presence: true, uniqueness: {case_sensitive: false}, format: {with: HANDLE_FORMAT}
  validate :name_must_not_be_reserved

  scope :name_starts_with, ->(name) {
    where("users.name ILIKE ?", "#{sanitize_sql_like(name.strip)}%")
  }

  # @rbs handle: String
  # @rbs return: User
  def self.find_by_handle!(handle)
    where("lower(users.name) = ?", handle.to_s.downcase).first!
  end

  # @rbs return: String
  def self.generate_handle
    HANDLE_GENERATION_ATTEMPTS.times do
      candidate = "user-#{SecureRandom.alphanumeric(6).downcase}"
      return candidate unless where("lower(users.name) = ?", candidate).exists?
    end

    raise HandleGenerationError, "could not generate an unused handle in #{HANDLE_GENERATION_ATTEMPTS} attempts"
  end

  # @rbs return: bool
  def have_unread_announcements?
    unread_announcement_count > 0
  end

  def unread_announcement_count
    unread_announcements.joins(:announcement).where(announcement: {event: current_event}).count
  end

  def mark_all_announcement_unread!(event = nil)
    event ||= current_event
    insert_ary = Announcement.published.where(event: event).ids.map do |ann_id|
      {announcement_id: ann_id, user_id: id}
    end
    UnreadAnnouncement.insert_all!(insert_ary) unless insert_ary.empty?
  end

  def send_push_notification(message)
    webpush_subscriptions.each do |subscription|
      subscription.send_webpush!(message)
    rescue WebPush::ExpiredSubscription
      subscription.destroy!
      next
    end
  end

  # @rbs id: Integer
  # @rbs return: bool
  def destroy_talk_bookmark_with_reminder!(id)
    talk_bookmark = talk_bookmarks.find(id)

    talk = talk_bookmark.talk
    transaction do
      talk_bookmark.destroy!
      talk_reminders.find_by(talk: talk)&.destroy!
    end
    true
  end

  # @rbs return: void
  private def name_must_not_be_reserved
    return if name.blank?

    if RESERVED_HANDLES.include?(name.downcase) || name.match?(RESERVED_HANDLE_FORMAT)
      errors.add(:name, :reserved)
    end
  end
end
