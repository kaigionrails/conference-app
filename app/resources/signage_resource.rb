class SignageResource
  include Alba::Resource

  # @rbs! extend Alba::Resource::ClassMethods

  many :signage_schedules, key: :schedules, resource: SignageScheduleResource
end
