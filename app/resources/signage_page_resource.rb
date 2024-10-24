class SignagePageResource
  include Alba::Resource

  attributes :order, :duration_second

  attribute :page_image_url do |resource|
    # https://github.com/rails/rails/issues/40855
    application_url = URI.parse(Rails.application.config.application_url)
    ActiveStorage::Current.url_options ||= {protocol: application_url.scheme, host: application_url.host, port: application_url.port}
    resource.page_image.url
  end
end
