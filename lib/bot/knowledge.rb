module Bot
  class Knowledge
    class << self
      def learn!
        return unless $redis.get 'bot_token'

        cache_users!

        setup_admins!

        ready_msg!
      end

      private

      def cache_users!
        Util.cache_users
        $im_cache = {}
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
