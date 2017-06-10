RSpec.describe 'Configuration' do
  context 'when no env vars are set' do
    before do
      Bot::SLACK_CONFIG = {
        client_id: nil,
        api_secret: nil,
        redirect_uri: nil,
        verification_token: nil
      }
    end

    it 'fails with a message' do
      expect {
        Bot::Config.start!
      }.to raise_error(ArgumentError, /Missing Slack config/)
    end
  end

  describe 'critical config' do
    before do
      Bot::SLACK_CONFIG = {
        client_id: 'test',
        api_secret: 'secret',
        redirect_uri: 'https://slack.com',
        verification_token: 'token'
      }
    end

    %w(client_id api_secret redirect_uri verification_token).each do |item|
      context "when missing '#{item}'" do
        before { Bot::SLACK_CONFIG[item] = nil }

        it 'fails with a message' do
          expect {
            Bot::Config.start!
          }.to raise_error(ArgumentError, "Missing Slack config: #{item.upcase}")
        end
      end
    end

    context 'when missing Redis config' do
      before { ENV['REDIS_URL'] = nil }

      it 'fails with a message' do
        expect {
          Bot::Config.start!
        }.to raise_error(ArgumentError, "Missing REDIS_URL")
      end
    end

    context 'when chief admin is missing' do
      before { ENV['REDIS_URL'] = 'redis://localhost' }

      it 'fails with a message' do
        expect {
          Bot::Config.start!
        }.to raise_error(ArgumentError, "Missing CHIEF_ADMIN")
      end
    end
  end
end
