# @rbs module-self ActionController::Base
module Authenticatable
  extend ActiveSupport::Concern

  # Establishes the session for a user who has just authenticated. Redirecting
  # is left to the caller: each entry point has its own landing page.
  #
  # @rbs user: User
  # @rbs return: void
  private def complete_login!(user)
    ticketholder = session[:ticketholder]

    reset_session
    session[:user_id] = user.id

    return if ticketholder.nil?

    # Checking in before logging in puts the ticket in the session. Without
    # carrying it across reset_session the viewer loses access the moment they
    # log in and is sent back to check-in.
    session[:ticketholder] = ticketholder
    # Conditional, so a ticket claimed by someone else between check-in and
    # login stays theirs. The session entry is kept either way, which leaves
    # access exactly as it was before logging in.
    TitoTicket.where(id: ticketholder.to_i, user_id: nil).update_all(user_id: user.id)
  end

  # Path and query of an untrusted return_to, or the default when it is not a
  # path on this site.
  #
  # @rbs value: untyped
  # @rbs default: String
  # @rbs return: String
  private def safe_return_to(value, default:)
    uri = parse_return_to(value)
    return default if uri.nil?

    uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path.to_s
  end

  # Path only, for callers that build their own query.
  #
  # @rbs value: untyped
  # @rbs default: String
  # @rbs return: String
  private def safe_return_to_path(value, default:)
    uri = parse_return_to(value)
    return default if uri.nil?

    uri.path.to_s
  end

  # @rbs value: untyped
  # @rbs return: URI::Generic?
  private def parse_return_to(value)
    return nil if value.blank?

    uri = URI.parse(value.to_s)
    path = uri.path
    # A URI with no hierarchical part has no path at all: URI.parse
    # ("javascript:alert(1)").path is nil. "////evil.com" parses with no host
    # and keeps the slashes in the path, which redirect_to rejects as an open
    # redirect. Anything with a host is fine to accept, because only the path
    # and query are used.
    return nil if path.nil? || !path.start_with?("/") || path.start_with?("//")

    uri
  rescue URI::InvalidURIError
    nil
  end
end
