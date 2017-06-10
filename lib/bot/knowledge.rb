module Bot
  class Knowledge
    class << self
      def learn!
        return unless $redis.get 'bot_token'

        cache_users!

        setup_admins!

        map_users!

        ready_msg!
      end

      private

      def cache_users!
        Util.cache_users
        $im_cache = {}
      end

      def map_users!
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
        imid = Util.im_channel $chief_admin

        Util.message imid, 'DiploBot is ready for commands. You are the chief administrator.'
      end

      def setup_admins!
        $chief_admin = Util.user_id(ENV['CHIEF_ADMIN'])

        $redis.sadd 'admins', $chief_admin
      end
    end
  end
end
