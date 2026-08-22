module Social
  class PostError < StandardError; end

  Result = Data.define(:remote_id, :remote_url)

  # @rbs return: bool
  def self.dry_run?
    Rails.configuration.x.social.dry_run == true
  end
end
