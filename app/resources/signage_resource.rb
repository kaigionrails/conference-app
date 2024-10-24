class SignageResource
  include Alba::Resource

  many :signage_schedules, key: :schedules, resource: SignageScheduleResource
end
