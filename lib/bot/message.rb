module Bot
  class Message
    attr_reader :channel, :text, :user

    def initialize(event)
      @channel = Channel.new(event)
      @text = event[:text]
      @user = User.new(event)
    end

    def admin_command?
      text.start_with? '!'
    end
  end
end
