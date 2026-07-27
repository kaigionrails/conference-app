# Rejects requests that did not come through CloudFront.
#
# The origin hostname is discoverable through Certificate Transparency logs, so
# CloudFront stamps every request it forwards with a shared secret header. This
# middleware sits in front of everything else and drops anything without it.
#
# Verification is skipped entirely when CLOUDFRONT_ORIGIN_SECRET is unset, so the
# app can be brought up before CloudFront exists.
class OriginVerification
  # kamal-proxy health checks reach the container directly, without the header.
  HEALTHCHECK_PATH = "/up"

  def initialize(app)
    @app = app
    @secret = ENV["CLOUDFRONT_ORIGIN_SECRET"]
    @application_url = ENV["APPLICATION_URL"]
  end

  def call(env)
    return @app.call(env) if @secret.blank?

    request = Rack::Request.new(env)
    return @app.call(env) if request.path == HEALTHCHECK_PATH
    return @app.call(env) if Rack::Utils.secure_compare(env["HTTP_X_ORIGIN_SECRET"].to_s, @secret)

    reject(request, env)
  end

  private

  def reject(request, env)
    # This runs before ActionDispatch::RemoteIp, so request.ip cannot be trusted
    # here. Log the header as-is instead.
    forwarded_for = env["HTTP_X_FORWARDED_FOR"] || env["REMOTE_ADDR"]
    Rails.logger.warn("OriginVerification: rejected path=#{request.path} forwarded_for=#{forwarded_for}")

    if request.get? || request.head?
      [301, {"location" => "#{@application_url}#{request.fullpath}"}, []]
    else
      [403, {"content-type" => "text/plain"}, []]
    end
  end
end
