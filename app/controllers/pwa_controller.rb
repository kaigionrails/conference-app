class PwaController < ApplicationController
  protect_from_forgery except: :service_worker
  layout false

  # @rbs return: void
  def service_worker
    response.headers["Cache-Control"] = "no-cache"
  end

  # @rbs return: void
  def manifest
    response.headers["Cache-Control"] = "no-cache"

    render json: {
      name: "Kaigi on Rails 2025 conference-app", # MEMO: change every year
      short_name: "Kaigi on Rails",
      description: "Web application for Kaigi on Rails attendees.",
      theme_color: "#292220", # MEMO: change every year
      background_color: "#292220", # MEMO: change every year
      display: "standalone",
      orientation: "portrait",
      scope: "/",
      start_url: "/",
      icons: [
        {
          src: view_context.image_path("icons/2024/512.png"),
          type: "image/png",
          sizes: "512x512"
        },
        {
          src: view_context.image_path("icons/2024/512_maskable.png"),
          type: "image/png",
          sizes: "512x512",
          purpose: "maskable"
        }
      ]
    }
  end
end
