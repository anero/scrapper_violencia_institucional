require 'net/http'
require 'uri'
require 'nokogiri'

module Parsers
  class Fiscales
    def initialize
      @page_number = 1
    end

    def parse
      loop do
        puts "Procesando página #{@page_number} de la lista"

        uri = case @page_number
        when 1
          URI('http://www.fiscales.gob.ar/violencia-institucional/')
        else
          URI("http://www.fiscales.gob.ar/violencia-institucional/page/#{@page_number}/")
        end

        raw = nil
        begin
          raw = Net::HTTP.get(uri)
        rescue Net::HTTPNotFound
          puts "Todas las páginas de la lista procesadas"
          return
        end

        doc = Nokogiri::HTML(raw)
        articles_url = doc.css('.nota-contenedor .nota-titulo a').map {|a| a.attr 'href' }
        articles_url.each {|article_url| process_page(URI(article_url)) }

        @page_number += 1
      end
    end

    private

    def process_page(uri)
      article_slug = article_slug(uri)
      existing_article = db[:articles].find(slug: article_slug).first
      if existing_article
        puts "Salteando artículo #{article_slug}"
        return
      end

      puts "Procesando artículo #{article_slug}"

      raw = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(raw)

      title = doc.css('.nota-titulo').first.content
      publish_date = doc.css('.left.coma.fecha').first.content
      content = doc.css('.nota p').inject('') {|full_content, paragraph| full_content << paragraph.content }
      images = doc.css('.foto.popup').map {|i| i.attr 'href' }

      db[:articles].insert_one(slug: article_slug, title: title, publish_date: publish_date, content: content, images: images)

      puts "******************************************************"
      puts "Titulo: #{title}"
      puts "Fecha de publicación: #{publish_date}"
      puts "Contenido: #{content}"
      puts "Images: #{images.inspect}"
      puts "******************************************************"
    end

    def article_slug(uri)
      match_data = uri.path.match(/violencia-institucional\/(.+)\//)
      match_data[1]
    end

    def db
      @db ||= Mongo::Client.new([ "#{ENV['MONGODB_HOST']}:#{ENV['MONGODB_PORT']}" ], :database => ENV['MONGODB_DB'])
    end
  end
end
