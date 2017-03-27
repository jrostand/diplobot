module Bot

  def self.slack_button
    <<-EOF
    <a href=\"https://slack.com/oauth/authorize?scope=#{SLACK_CONFIG[:oauth_scope].join(',')}&client_id=#{SLACK_CONFIG[:client_id]}&redirect_uri=#{SLACK_CONFIG[:redirect_uri]}\">
      <img title="Add to Slack" height="40" width="139" src="https://platform.slack-edge.com/img/add_to_slack.png" />
    </a>
    EOF
  end

  class Auth < Sinatra::Base
    get '/' do
      redirect '/auth/start'
    end

    get '/auth/start' do
      status 200
      body Bot.slack_button
    end

    get '/auth/finish' do
      client = Slack::Web::Client.new

      begin
        response = client.oauth_access({
          client_id: SLACK_CONFIG[:client_id],
          client_secret: SLACK_CONFIG[:api_secret],
          redirect_uri: SLACK_CONFIG[:redirect_uri],
          code: params[:code]
        })

        $redis.mset('team_id', response['team_id'],
                    'bot_token', response['bot']['bot_access_token'],
                    'bot_user', response['bot']['bot_user_id'],
                    'user_token', response['access_token'])

        status 200
        body 'Auth success!'
      rescue Slack::Web::Api::Error => e
        status 500
        body "Auth failed! Reason: #{e.message}<br />#{Bot.slack_button}"
      rescue ArgumentError => e
        status 500
        body "Auth failed! Reason: Install declined.<br />#{Bot.slack_button}"
      end
    end
  end
end
