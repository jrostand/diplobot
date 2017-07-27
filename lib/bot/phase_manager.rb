module Bot
  class PhaseManager
    attr_accessor :current_phase

    def initialize
      @current_phase = $redis.get('phase')&.to_sym

      if !@current_phase
        $redis.set('phase', 'wait')
        @current_phase = :wait
      end
    end

    def news?
      news_phases.include? current_phase.to_s
    end

    def orders?
      orders_phases.include? current_phase.to_s
    end

    def phases
      allowed_transitions.keys
    end

    def transition!(new_phase)
      new_phase = new_phase.to_sym

      raise InvalidPhaseError unless phases.include? new_phase

      raise Bot::IllegalTransitionError unless allowed_transitions[current_phase].include?(new_phase)

      $redis.set('phase', new_phase.to_s)
      @current_phase = new_phase
    end

    def to_s
      case current_phase
      when :build then 'Build/Disband'
      when :demo then 'Bot Demonstration/Practice'
      when :diplomacy then 'Diplomacy'
      when :maps then 'Cartography'
      when :orders then 'Orders'
      when :resolution then 'Order Resolution'
      when :retreat then 'Retreat'
      when :reveal then 'Order Reveal'
      when :wait then 'Game Hold'
      end
    end

    private

    def allowed_transitions
      {
        build: [:diplomacy, :reveal],
        demo: [:wait],
        diplomacy: [:orders],
        maps: [:diplomacy, :retreat, :build, :wait],
        orders: [:build, :maps, :resolution, :retreat, :reveal],
        resolution: [:build, :maps, :retreat, :wait],
        retreat: [:build, :maps, :reveal],
        reveal: [:build, :diplomacy, :maps, :resolution, :retreat, :wait],
        wait: [:build, :demo, :diplomacy, :maps, :orders, :resolution, :retreat]
      }
    end

    def news_phases
      %w(demo diplomacy)
    end

    def orders_phases
      %w(build demo orders retreat)
    end
  end
end
