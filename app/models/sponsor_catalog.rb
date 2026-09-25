class SponsorCatalog
  REQUIRED_ATTRIBUTES = %i[key name plan logo].freeze

  # Catalogs are loaded once per year in each process. Restart the app after
  # updating a sponsor file to reload it in production.
  def self.for_year(year)
    year = Integer(year)
    @sponsors_by_year ||= {} #: Hash[Integer, Array[Hash[Symbol, untyped]]]
    @sponsors_by_year[year] ||= load_sponsors(year)
  end

  def self.with_booth(year)
    for_year(year).select { |sponsor| sponsor[:booth] }
  end

  def self.logo_url(year, sponsor)
    "#{Rails.configuration.x.official_site_url}/#{Integer(year)}/images/sponsors/#{sponsor.fetch(:logo)}.png"
  end

  def self.load_sponsors(year)
    sponsors = YAML.safe_load_file(
      Rails.root.join("data/sponsors/#{year}.yaml"),
      permitted_classes: [Symbol],
      aliases: false
    ).fetch(:sponsors)

    sponsors.each do |sponsor|
      missing_attributes = REQUIRED_ATTRIBUTES.reject { |attribute| sponsor[attribute].present? }
      raise KeyError, "Missing sponsor attributes: #{missing_attributes.join(", ")}" if missing_attributes.any?
    end

    duplicate_keys = sponsors.group_by { |sponsor| sponsor[:key] }.select { |_key, entries| entries.many? }.keys
    raise KeyError, "Duplicate sponsor keys: #{duplicate_keys.join(", ")}" if duplicate_keys.any?

    sponsors.map do |sponsor|
      labels = Array(sponsor[:labels]) #: Array[Hash[Symbol, untyped]]
      sponsor.merge(booth: labels.any? { |label| label[:type] == "booth" })
    end
  end

  private_class_method :load_sponsors
end
