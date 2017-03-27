require_relative './bot/config'
require_relative './bot/client'
require_relative './bot/util'

require_relative './bot/knowledge'

require_relative './bot/auth'
require_relative './bot/responder'
require_relative './bot/event'
require_relative './bot/admin_event'
require_relative './bot/news'
require_relative './bot/order'

module Bot
  Knowledge.fetch!
end
