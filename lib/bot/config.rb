module Bot
  SLACK_CONFIG = {
    client_id: ENV['SLACK_CLIENT_ID'],
    api_secret: ENV['SLACK_API_SECRET'],
    redirect_uri: ENV['SLACK_REDIRECT_URI'],
    verification_token: ENV['SLACK_VERIFICATION_TOKEN'],
    oauth_scope: %w(bot channels:history chat:write:bot usergroups:read users:read)
  }

  class Config
    def self.start!
      missing_params = SLACK_CONFIG.select { |_, v| v.nil? }
      raise ArgumentError, "Missing Slack config: #{missing_params.keys.join(', ').upcase}" if missing_params.any?

      raise ArgumentError, 'Missing REDIS_URL' if ENV['REDIS_URL'].nil?

      raise ArgumentError, 'Missing DIP_ADMINS' if ENV['DIP_ADMINS'].nil?

      $redis = Redis.new(url: ENV['REDIS_URL'])
    end
  end
end
