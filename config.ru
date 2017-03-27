require 'rubygems'
require 'bundler/setup'
Bundler.require :default

require './lib/bot'

run Rack::Cascade.new [Bot::Auth, Bot::Responder]
