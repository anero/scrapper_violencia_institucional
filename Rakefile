require 'rubygems'

require 'bundler/setup'
Bundler.require(:default)

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'parsers'))
require 'fiscales'

namespace :app do
  Dotenv.load '.env'

  task :parse_feed do
    feed = Feedjira::Feed.fetch_and_parse 'https://www.google.com.ar/alerts/feeds/17088465536342431865/4043622370306166586'
    byebug
  end

  task :parse_fiscales do
    Parsers::Fiscales.new.parse
  end
end
