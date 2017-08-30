module Bot
  class Order
    def initialize(event)
      @event = event
      @channel = @event[:channel]
      @text = @event[:text].split[1..-1].join(' ')
      @uid = @event[:user]
    end

    def clear!
      orders = $redis.smembers("orders:#{nation}").join(' ; ')

      if locked?
        msg 'You have locked in your orders and cannot clear them'
        return
      elsif orders.size == 0
        msg 'You had no orders to clear'
      else
        msg "I have cleared your previous orders. They were: #{orders}"
      end

      $redis.del "orders:#{nation}"
    end

    def lock!
      if locked?
        msg 'You have already locked in your orders'
        return
      elsif !Util.orders_open?
        msg 'Orders are not currently being accepted'
        return
      elsif $redis.scard("orders:#{nation}") == 0
        msg 'You have not submitted any orders'
        return
      end

      $redis.set "lock:#{nation}", 'true'
      msg 'Your orders have been locked in'
      player_orders
    end

    def locked?
      !!$redis.get("lock:#{nation}")
    end

    def player_orders
      orders = $redis.smembers "orders:#{nation}"

      if !Util.orders_open?
        msg 'I am not currently accepting orders'
      elsif orders.size == 0
        msg 'You have not submitted any orders'
      else
        msg "_Here are your current orders_\n#{Order.format(nation, orders)}"
      end
    end

    def self.reveal!(channel)
      if Util.orders_open?
        Util.message channel, 'I cannot reveal orders while orders are still open'
        return
      end

      if $redis.keys('lock:*').size == 0
        Util.message channel, 'No nation locked in their orders, all units will *hold*.'
        return
      end

      if $redis.keys('orders:*').size == 0
        Util.message channel, "I did not receive any orders! Did something go wrong? Please help #{Util.tag_user($chief_admin)} I'm scared! :fearful: :fearful: :fearful:"
        return
      end

      output = ['_Here are the locked-in orders I received_']

      $redis.keys("lock:*").each do |key|
        country = key.match(/:(\w+)$/)[1]
        orders = $redis.smembers "orders:#{country}"

        output << Order.format(country, orders)
      end

      $redis.del(*$redis.keys('orders:*'))
      $redis.del(*$redis.keys('lock:*'))

      Util.message channel, output.join("\n")
    end

    def store!
      if Util.orders_open?
        if locked?
          msg "You have already locked in your orders. Only an administrator can unlock them."
          return
        end

        @text =~ /;/ ? store_orders : store_order
      else
        msg "I'm not currently accepting orders"
      end
    end

    private

    def self.format(country, orders)
      output = ["*#{country}*"]

      output += orders.map { |order| "- #{order}" }

      output.join("\n")
    end

    def msg(text)
      Util.message(@channel, text)
    end

    def nation
      @nation ||= $redis.hgetall('players').invert[@uid]
    end

    def store_orders
      orders = @text.split(';').map(&:strip)

      $redis.sadd "orders:#{nation}", orders

      player_orders
    end

    def store_order
      if $redis.sadd "orders:#{nation}", @text
        msg "I have stored your \"#{@text}\" order"
      else
        msg "It looks like I already had \"#{@text}\" stored. You can say `myorders` to see your current orders."
      end
    end
  end
end
