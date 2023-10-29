module TalksHelper
  def time_with_zone_to_anchor(time_with_zone)
    time_with_zone.in_time_zone("Tokyo").strftime("%m%d-%H%M")
  end
end
