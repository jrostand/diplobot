module Bot
  class BaseModule
    def initialize(event)
      @event = event

      @channel = @event.channel
      @text = @event.text
      @user = @event.user
    end
  end
end
