module Bot
  class Util
    class << self
      def message(channel, text)
        client.message(channel, text)
      end

      def add_admin(username)
        uid = user_id(username)
        $redis.sadd('admins', uid)
      end

      def admins
        $redis.smembers('admins')
      end

      def admin_tags
        admins.map { |admin| tag_user(admin) }
      end

      def cache_users
        $users = client.users_list.members.map do |user|
          {
            id: user.id,
            username: user.name
          }
        end
      end

      def im_channel(uid)
        unless $im_cache[uid]
          $im_cache[uid] = client.im_list.ims.find { |i| i.user == uid }.id
        end

        $im_cache[uid]
      end

      def is_admin?(uid)
        admins.include? uid
      end

      def is_player?(uid)
        $redis.hvals('players').include? uid
      end

      def news_open?
        PhaseManager.new.news?
      end

      def orders_open?
        PhaseManager.new.orders?
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

      def remove_admin(username)
        uid = user_id(username)

        raise InvalidUserError if uid == $chief_admin

        $redis.srem('admins', uid)
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
        return username.scan(/[A-Z0-9]+/)[0] if username[0] == '<'

        if user = $users.find { |u| u[:username] == username }
          user[:id]
        else
          cache_users

          $users.find { |u| u[:username] == username }[:id] || raise(NotFoundError, "Could not find user `#{username}`")
        end
      end

      private

      def client
        @client ||= Client.new
      end
    end
  end
end
