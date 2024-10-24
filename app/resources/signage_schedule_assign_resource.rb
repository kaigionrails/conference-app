class SignageScheduleAssignResource
  include Alba::Resource

  # attributes :signage_panel_id
  many :signage_schedule, key: :schedule, resource: SignageScheduleResource
end
