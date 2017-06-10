module Bot
  class Util
    class << self
      def message(channel, text)
        client.message(channel, text)
      end

      def allow_news(bool)
        status = bool ? 'open' : 'closed'

        $redis.set 'news_status', status
      end

      def allow_orders(bool)
        status = bool ? 'open' : 'closed'

        $redis.set 'orders_status', status
      end

      def im_channel(uid)
        client.im_list.ims.find { |i| i.user == uid }.id
      end

      def is_admin?(uid)
        $admins.include? uid
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

      def oxfordise(list, join_word = 'and')
        case list.size
        when 0 then 'no one'
        when 1 then list.first
        when 2 then list.join(" #{join_word} ")
        else
          list.last.prepend("#{join_word} ")
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
        @client ||= Client.new
      end
    end
  end
end
