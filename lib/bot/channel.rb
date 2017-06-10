module Bot
  class Channel
    attr_reader :id

    def initialize(event)
      @client ||= Client.new
      @id = event[:channel]
    end

    def is_dm?
      id[0] == 'D'
    end

    def is_public?
      id[0] == 'C'
    end

    def msg(text)
      @client.message(id, text)
    end
  end
end
