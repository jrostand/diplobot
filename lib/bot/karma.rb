module Bot
  class Karma

    # Karma change timeouts (seconds)
    DECREMENT_TIMEOUT = 120
    INCREMENT_TIMEOUT = 600

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

      def can_decr?(user)
        Time.now.to_i - last_of(user) >= INCREMENT_TIMEOUT
      end

      def can_incr?(user)
        Time.now.to_i - last_of(user) >= INCREMENT_TIMEOUT
      end

      def decrement(user, step = 1, force = false)
        if $redis.hexists('last_karma', user) && force == false
          raise KarmaDecayError unless can_decr?(user)
        end

        $redis.hset('last_karma', user, Time.now.to_i)

        $redis.hincrby('karma', user, (step * -1))
      end

      def increment(user, step = 1)
        if $redis.hexists('last_karma', user)
          raise KarmaDecayError unless can_incr?(user)
        end

        $redis.hset('last_karma', user, Time.now.to_i)

        $redis.hincrby('karma', user, step)
      end

      def last_of(user)
        $redis.hget('last_karma', user).to_i
      end

      def of(user)
        $redis.hget('karma', user)
      end
    end
  end
end
