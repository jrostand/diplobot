module Bot
  class Order
    def initialize(event)
      @event = event
      @channel = @event[:channel]
      @text = @event[:text].split[1..-1].join(' ')
      @uid = @event[:user]
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

      if $redis.keys('orders:*').size == 0
        Util.message channel, "I did not receive any orders! Did something go wrong? Please help #{Util.tag_user($admins.first)} I'm scared! :fearful: :fearful: :fearful:"
        return
      end

      output = ['_Here are the orders I received_']

      $redis.keys("orders:*").each do |key|
        orders = $redis.smembers key
        country = key.match(/:(\w+)$/)[1]

        output << Order.format(country, orders)

        $redis.del key
      end

      Util.message channel, output.join("\n")
    end

    def store!
      if Util.orders_open?
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
      @nation ||= $redis.hget 'players', @uid
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
