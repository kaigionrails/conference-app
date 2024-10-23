class SignageDeviceResource
  include Alba::Resource

  attribute :panel do |resource|
    SignagePanelResource.new(resource.signage_panel).to_h
  end
end
