module Bot
  class Knowledge
    class << self
      def learn!
        return unless $redis.get 'bot_token'

        $admins = []

        ENV['DIP_ADMINS'].strip.split(',').each do |admin|
          $admins << Util.user_id(admin)
        end

        $admin_tags = $admins.map { |admin| Util.tag_user(admin) }

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
        imid = Util.im_channel $admins.first

        Util.message imid, 'DiploBot is ready for commands. You are the prime administrator.'
      end
    end
  end
end
