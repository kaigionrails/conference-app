class SignageDeviceResource
  include Alba::Resource

  # @rbs! extend Alba::Resource::ClassMethods

  attribute :panel do |resource|
    SignagePanelResource.new(resource.signage_panel).to_h
  end
end
