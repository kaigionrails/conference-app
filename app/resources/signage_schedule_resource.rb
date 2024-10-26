class SignageScheduleResource
  include Alba::Resource

  # @rbs! extend Alba::Resource::ClassMethods

  attributes :id

  attribute :start_at do |resource|
    resource.start_at.iso8601
  end

  attribute :end_at do |resource|
    resource.end_at.iso8601
  end

  many :signage_pages, key: :pages, resource: SignagePageResource
  many :signage_schedule_assigns, key: :assigns, resource: SignagePanelAssignResource
end
