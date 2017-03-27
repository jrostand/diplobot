module Bot
  class Knowledge
    class << self
      def fetch!
        return unless $redis.get 'bot_token'

        map_users
        ready_msg!
      end

      private

      def map_users
        $redis.del 'nations'

        raise 'No USER_MAP found' if ENV['USER_MAP'].nil?

        users = ENV['USER_MAP'].split('|').map { |pair|
          pair.split(':')
        }.flatten

        $redis.hmset 'nations', *users
      end

      def ready_msg!
        imid = Util.user_im_channel ENV['DIP_ADMIN']

        Util.message imid, 'DiploBot awaiting orders'
      end
    end
  end
end
