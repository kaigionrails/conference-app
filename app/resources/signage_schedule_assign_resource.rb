class SignageScheduleAssignResource
  include Alba::Resource

  # @rbs! extend Alba::Resource::ClassMethods

  # attributes :signage_panel_id
  many :signage_schedule, key: :schedule, resource: SignageScheduleResource
end
