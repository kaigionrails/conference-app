# Imports the talks of an event and their speakers from a YAML file such as db/seeds/2026.yaml.
# db:seed, bin/rails talks:import and Maintenance::ImportTalksTask all go through this class.
#
# An event is imported once. Talks are fixed afterwards on the admin pages, as importing again
# could not tell an edited talk from a new one.
class TalkImporter
  AVATAR_FETCH_TIMEOUTS = {open_timeout: 10, read_timeout: 30}.freeze #: Hash[Symbol, Integer]

  # @rbs @event: Event
  # @rbs @path: Pathname
  # @rbs @avatar_dir: Pathname

  # @rbs event: Event
  # @rbs path: Pathname -- the YAML file of the talks
  # @rbs avatar_dir: Pathname -- where avatar images named after speaker slugs are, if it exists
  # @rbs return: void
  def initialize(event:, path: Rails.root.join("db/seeds/#{event.slug}.yaml"), avatar_dir: Rails.root.join("db/seeds", event.slug))
    @event = event
    @path = path
    @avatar_dir = avatar_dir
  end

  # Creates the talks and the speakers, and attaches avatars to speakers without one. Nothing is
  # changed when this raises.
  #
  # @rbs return: Array[Talk]
  def import!
    talks_data = load_talks
    ensure_not_imported

    avatars = {} #: Hash[String, ActiveStorage::Blob]
    begin
      upload_avatars(talks_data, avatars)
      ApplicationRecord.transaction do
        # Two imports of the same event wait for each other here, and the second one finds the talks.
        @event.lock!
        ensure_not_imported
        talks_data.map { |talk_data| create_talk(talk_data, avatars) }
      end
    ensure
      # Uploaded avatars left unattached by a failure, or by a speaker who got an avatar meanwhile.
      avatars.each_value { |blob| blob.purge unless blob.attachments.exists? }
    end
  end

  # @rbs return: Array[Hash[Symbol, untyped]]
  private def load_talks
    data = YAML.safe_load_file(@path, permitted_classes: [Symbol, Time], aliases: false, symbolize_names: true)
    talks = data.fetch(:talks)
    problems = problems_in(talks, tracks: data[:tracks])
    raise StandardError, "Invalid talks in #{@path.relative_path_from(Rails.root)}: #{problems.join("; ")}" if problems.any?

    talks
  end

  # Missing attributes are left to the constraints of the database. These are what it cannot catch.
  #
  # @rbs talks: Array[Hash[Symbol, untyped]]
  # @rbs tracks: Array[String]? -- the tracks talks may be in; any track when nil
  # @rbs return: Array[String]
  private def problems_in(talks, tracks:)
    talks.each_with_index.flat_map do |talk, index|
      label = "talks[#{index}] #{talk[:title].inspect}"
      speakers = talk[:speakers] || [] #: Array[Hash[Symbol, untyped]]
      problems = [] #: Array[String]

      if tracks && !tracks.include?(talk[:track])
        problems << "#{label}: track #{talk[:track].inspect} is not in tracks (#{tracks.join(", ")})"
      end
      problems << "#{label}: no speakers" if speakers.empty?
      speakers.each do |speaker|
        # An empty slug passes NOT NULL, and every speaker without one would become the same speaker.
        problems << "#{label}: speaker #{speaker[:name].inspect} has no slug" if speaker[:slug].blank?

        url = speaker[:avatar_url]
        next if url.nil? || https_url?(url)

        problems << "#{label}: speaker #{speaker[:slug].inspect} avatar_url #{url.inspect} is not an https URL"
      end
      problems
    end
  end

  # @rbs url: untyped
  # @rbs return: bool
  private def https_url?(url)
    return false unless url.is_a?(String)

    uri = URI.parse(url)
    uri.is_a?(URI::HTTPS) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end

  # @rbs return: void
  private def ensure_not_imported
    raise StandardError, "Talks of event #{@event.slug} are already imported" if @event.talks.exists?
  end

  # Uploads the avatars before the transaction. A file attached with io: is uploaded in the
  # after_commit of the record, and a failed upload there would leave an attachment without its
  # file, which importing again cannot fix as the talks are already there.
  #
  # @rbs talks_data: Array[Hash[Symbol, untyped]]
  # @rbs avatars: Hash[String, ActiveStorage::Blob] -- receives the uploaded blobs by speaker slug
  # @rbs return: void
  private def upload_avatars(talks_data, avatars)
    # The first appearance of a speaker wins.
    speakers_data = talks_data.flat_map { |talk| talk.fetch(:speakers) }.uniq { |speaker| speaker[:slug] }
    with_avatar = Speaker.joins(:avatar_attachment).where(slug: speakers_data.pluck(:slug)).pluck(:slug)

    speakers_data.each do |speaker|
      slug = speaker[:slug]
      next if with_avatar.include?(slug)

      blob = speaker[:avatar_url] ? fetch_avatar(slug, speaker[:avatar_url]) : read_avatar(slug)
      avatars[slug] = blob if blob
    end
  end

  # @rbs slug: String
  # @rbs url: String
  # @rbs return: ActiveStorage::Blob
  private def fetch_avatar(slug, url)
    # The URL is checked to be https beforehand, so this never falls back to Kernel#open. The
    # signature of URI.open takes the options as a positional Hash after the mode and the permission.
    # standard:disable Security/Open
    URI.open(url, **AVATAR_FETCH_TIMEOUTS) do |io| # steep:ignore
      content_type = Marcel::MimeType.for(io)
      # Such as a not found page served with 200.
      raise StandardError, "Avatar of speaker #{slug.inspect} at #{url} is not an image (#{content_type})" unless content_type.start_with?("image/")

      io.rewind
      extension = File.extname(URI.parse(url).path.to_s).presence || ".#{content_type.split("/").last}"
      ActiveStorage::Blob.create_and_upload!(io:, filename: "#{slug}#{extension}")
    end
    # standard:enable Security/Open
  end

  # @rbs slug: String
  # @rbs return: ActiveStorage::Blob?
  private def read_avatar(slug)
    file = @avatar_dir.glob("#{slug}.*").min
    return unless file

    file.open("rb") { |io| ActiveStorage::Blob.create_and_upload!(io:, filename: file.basename.to_s) }
  end

  # @rbs talk_data: Hash[Symbol, untyped]
  # @rbs avatars: Hash[String, ActiveStorage::Blob]
  # @rbs return: Talk
  private def create_talk(talk_data, avatars)
    talk = @event.talks.create!(
      title: talk_data[:title],
      abstract: talk_data[:abstract],
      start_at: talk_data[:start_at],
      duration_minutes: talk_data[:duration_minutes],
      track: talk_data[:track]
    )
    talk.speakers << talk_data.fetch(:speakers).map { |speaker_data| save_speaker(speaker_data, avatars) }
    Rails.logger.info "Created talk: #{talk.title}"
    talk
  end

  # Speakers who spoke in earlier years take the attributes in this file.
  #
  # @rbs speaker_data: Hash[Symbol, untyped]
  # @rbs avatars: Hash[String, ActiveStorage::Blob]
  # @rbs return: Speaker
  private def save_speaker(speaker_data, avatars)
    speaker = Speaker.find_or_initialize_by(slug: speaker_data[:slug])
    speaker.name = speaker_data[:name]
    speaker.github_username = speaker_data[:github_username]
    speaker.gravatar_hash = speaker_data[:gravatar_hash]
    speaker.bio = speaker_data[:bio]
    speaker.save! if speaker.new_record? || speaker.changed?

    blob = avatars[speaker.slug]
    speaker.avatar.attach(blob) if blob && !speaker.avatar.attached?
    speaker
  end
end
