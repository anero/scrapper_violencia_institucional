require 'rubygems'

require 'bundler/setup'
Bundler.require(:default)

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'parsers'))
require 'fiscales'
require 'telam'
require 'pagina12'
require 'izquierda_diario'

namespace :app do
  Dotenv.load '.env'

  task :parse_feed do
    feed = Feedjira::Feed.fetch_and_parse 'https://www.google.com.ar/alerts/feeds/17088465536342431865/4043622370306166586'
    byebug
  end

  task :parse_fiscales do
    Parsers::Fiscales.new.parse
  end

  task :parse_telam do
    Parsers::Telam.new.parse
  end

  task :parse_pagina12 do
    Parsers::Pagina12.new.parse
  end

  task :parse_izquierda_diario do
    Parsers::IzquierdaDiario.new.parse
  end
end
