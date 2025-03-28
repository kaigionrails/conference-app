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
      name: "Kaigi on Rails 2024 conference-app",
      short_name: "Kaigi on Rails",
      description: "Web application for Kaigi on Rails attendees.",
      theme_color: "#d7d2d0",
      background_color: "#d7d2d0",
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
