module Bot
  class Order
    def initialize(event)
      @event = event
      @channel = @event[:channel]
      @text = @event[:text].split[1..-1].join(' ')
      @uid = @event[:user]
    end

    def process!
      if Util.orders_open?
        store_order
      else
        msg "I'm not currently accepting orders"
      end
    end

    def self.reveal!(channel)
      if Util.orders_open?
        Util.message channel, 'I cannot reveal orders while orders are still open'
        return
      end

      output = ['_Orders received, in no particular order_']

      $redis.hkeys('orders').each do |player|
        output << "*#{$redis.hget('nations', player)}*"

        output += JSON.parse($redis.hget('orders', player)).map { |order| "- #{order}" }
      end

      $redis.del 'orders'

      Util.message channel, output.join("\n")
    end

    private

    def msg(text)
      Util.message(@channel, text)
    end

    def store_order
      username = Util.userinfo(@uid).name

      orders = if $redis.hexists('orders', username)
                 JSON.parse($redis.hget('orders', username))
               else
                 []
               end

      orders << @text

      $redis.hset('orders', username, JSON.generate(orders))

      msg "I have stored your \"#{@text}\" order"
    end
  end
end
