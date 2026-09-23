class SponsorVisitProgress
  attr_reader :visited_count, :total_count

  def initialize(visited_count:, total_count:)
    @visited_count = visited_count
    @total_count = total_count
  end

  def current_milestone
    milestones.reverse.find { |milestone| visited_count >= milestone[:count] }
  end

  def completed?
    visited_count >= total_count
  end

  def milestones
    [
      {count: [total_count / 4, 1].max, key: :hello_sponsors},
      {count: (total_count / 2) + 1, key: :halfway}
    ].uniq { |milestone| milestone[:count] }
      .select { |milestone| milestone[:count] < total_count } + [{count: total_count, key: :complete}]
  end

  def percentage(count = visited_count)
    total_count.positive? ? (count * 100.0 / total_count).round(2) : 0
  end
end
