module Bot
  class Responder < Sinatra::Base
    post '/events' do
      data = JSON.parse(request.body.read, symbolize_names: true)

      unless data[:token] == SLACK_CONFIG[:verification_token]
        halt 403, "Invalid token received: #{data[:token]}"
      end

      if data[:type] == 'url_verification'
        body data[:challenge]
      elsif data[:type] == 'event_callback' && data[:event][:type] == 'message'
        event = data[:event]

        return if event[:bot_id] || event[:user] == $redis.get('bot_user')
        return unless event[:text]

        msg = Message.new(event)

        Event.new(msg).dispatch!
      else
        puts 'Got unexpected event:'
        puts JSON.pretty_generate(data)
      end

      status 200
    end
  end
end
