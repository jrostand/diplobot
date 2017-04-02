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
        uid == $admin
      end

      def is_player?(uid)
        $redis.hkeys('players').include? uid
      end

      def news_open?
        $redis.get('news_status') == 'open'
      end

      def orders_open?
        $redis.get('orders_status') == 'open'
      end

      def oxfordise(list)
        case list.size
        when 0 then 'no one'
        when 1 then list.first
        when 2 then list.join(' and ')
        else
          list.last.prepend('and ')
          list.join(', ')
        end
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
