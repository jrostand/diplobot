module Bot
  class Channel
    attr_reader :id

    def initialize(event)
      @client ||= Client.new
      @id = event[:channel]
    end

    def self.new_by_id(id)
      new({ channel: id })
    end

    def dm?
      id[0] == 'D'
    end

    def public?
      id[0] == 'C'
    end

    def msg(text)
      @client.message(id, text)
    end
  end
end
