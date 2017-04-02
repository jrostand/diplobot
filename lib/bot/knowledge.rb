module Bot
  class Knowledge
    class << self
      def learn!
        return unless $redis.get 'bot_token'

        $admin = Util.user_id(ENV['DIP_ADMIN'])

        map_users
        ready_msg!
      end

      private

      def map_users
        $redis.del 'players'

        raise 'No USER_MAP found' if ENV['USER_MAP'].nil?

        users = ENV['USER_MAP'].split('|').map { |pair|
          pair.split(':')
        }.to_h

        users.each do |username, nation|
          uid = Util.user_id(username)

          $redis.hset 'players', uid, nation
        end
      end

      def ready_msg!
        imid = Util.im_channel $admin

        Util.message imid, 'DiploBot awaiting orders'
      end
    end
  end
end
