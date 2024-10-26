class SignagePanelResource
  include Alba::Resource

  # @rbs! extend Alba::Resource::ClassMethods

  attributes :id, :name
  many :signage_schedules, key: :schedules, resource: SignageScheduleResource
end
