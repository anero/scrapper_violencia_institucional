require 'net/http'
require 'uri'
require 'nokogiri'

module Parsers
  class Base
    def db
      @db ||= Mongo::Client.new([ "#{ENV['MONGODB_HOST']}:#{ENV['MONGODB_PORT']}" ], :database => ENV['MONGODB_DB'])
    end
  end
end
