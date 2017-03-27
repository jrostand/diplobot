module Bot
  class Util
    class << self
      def message(channel, text)
        client.chat_postMessage({
          channel: channel,
          text: text
        })
      end

      def im_channel(uid)
        client.im_list.ims.find { |i| i.user == uid }.id
      end

      def is_admin?(uid)
        userinfo(uid).name == ENV['DIP_ADMIN']
      end

      def is_player?(uid)
        $redis.hkeys('nations').include? Util.userinfo(uid).name
      end

      def orders_open?
        $redis.get('orders_status') == 'open'
      end

      def tag_user(user)
        unless user =~ /^U/
          user = user_id(user)
        end

        "<@#{user}>"
      end

      def user_im_channel(username)
        begin
          im_channel(user_id(username))
        rescue => e
          raise "Could not find expected user #{username}"
        end
      end

      def user_id(username)
        client.users_list.members.find { |u| u.name == username }.id
      end

      def userinfo(uid)
        client.users_info(user: uid).user
      end

      private

      def client
        @client ||= Client.init
      end
    end
  end
end
