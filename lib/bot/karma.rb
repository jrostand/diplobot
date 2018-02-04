module Bot
  class Karma
    class << self
      def all
        if $redis.hkeys('karma').size == 0
          return 'No users have any karma.'
        end

        str = ''

        $redis.hgetall('karma').each do |k, v|
          str += "#{Util.tag_user(k)}\t\t#{v}\n"
        end

        "```#{str}```"
      end

      def decrement(user, step = 1)
        $redis.hincrby('karma', user, (step * -1))
      end

      def increment(user, step = 1)
        $redis.hincrby('karma', user, step)
      end

      def of(user)
        $redis.hget('karma', user)
      end
    end
  end
end
