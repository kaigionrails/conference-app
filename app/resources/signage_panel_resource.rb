class SignagePanelResource
  include Alba::Resource

  attributes :id, :name
  many :signage_schedules, key: :schedules, resource: SignageScheduleResource
end
