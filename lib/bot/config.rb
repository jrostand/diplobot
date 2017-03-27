SLACK_CONFIG = {
  client_id: ENV['SLACK_CLIENT_ID'],
  api_secret: ENV['SLACK_API_SECRET'],
  redirect_uri: ENV['SLACK_REDIRECT_URI'],
  verification_token: ENV['SLACK_VERIFICATION_TOKEN'],
  oauth_scope: %w(bot channels:history chat:write:bot usergroups:read users:read)
}

missing_params = SLACK_CONFIG.select { |_, v| v.nil? }
raise "Missing Slack config: #{missing_params.keys.join(', ').upcase}" if missing_params.any?

raise 'Missing REDIS_URI' if ENV['REDIS_URI'].nil?

raise 'Missing DIP_ADMIN' if ENV['DIP_ADMIN'].nil?

$redis = Redis.new(url: ENV['REDIS_URI'])
