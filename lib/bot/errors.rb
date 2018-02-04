module Bot
  class IllegalTransitionError < RuntimeError; end

  class InvalidChannelError < RuntimeError; end
  class InvalidNationError < RuntimeError; end
  class InvalidPhaseError < RuntimeError; end
  class InvalidUserError < RuntimeError; end

  class KarmaDecayError < RuntimeError; end

  class NoChannelError < RuntimeError; end

  class NotAuthorizedError < RuntimeError; end
  class NotFoundError < RuntimeError; end
end
