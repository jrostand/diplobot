module Bot
  class InvalidChannelError < RuntimeError; end
  class InvalidUserError < RuntimeError; end

  class NotAuthorizedError < RuntimeError; end
  class NotFoundError < RuntimeError; end
end
