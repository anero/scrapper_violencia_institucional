require 'base'

module Parsers
  class Telam < Base
    SOURCES = ['http://www.telam.com.ar/tags/6387-gatillo-facil/noticias', 'http://www.telam.com.ar/tags/2461-violencia-institucional/noticias']

    def parse
      # TODO: DRY
      SOURCES.each do |source|
        @page_number = 1

        loop do
          puts "Procesando página #{@page_number} de la lista #{source}"

          uri = case @page_number
            when 1
              URI(source)
            else
              URI("#{source}/pagina/#{@page_number}/")
            end

          raw = nil
          begin
            raw = Net::HTTP.get(uri)
          rescue Net::HTTPNotFound
            puts "Todas las páginas de la lista procesadas"
            next
          end

          doc = Nokogiri::HTML(raw)
          articles_url = doc.css('.related-news-block a').map {|a| a.attr 'href' }
          articles_url.each {|article_url| process_page(URI("http://www.telam.com.ar#{article_url}")) }

          @page_number += 1
        end
      end
    end

    private

    def process_page(uri)
      # TODO: Filtrar artículos que no sean noticias de Argentina

      article_slug = article_slug(uri)
      existing_article = db[:articles].find(source: 'telam', slug: article_slug).first
      if existing_article
        puts "Salteando artículo #{article_slug}"
        return
      end

      puts "Procesando artículo #{article_slug}"

      raw = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(raw)

      title = doc.css('.title h2').first.content
      publish_date = doc.css('.head-content .data .date').first.content
      content = doc.css('.editable-content').first.content.strip
      images = doc.css('.editable-content .image img').map {|i| i.attr 'src' }

      db[:articles].insert_one(source: 'telam', slug: article_slug, title: title, publish_date: publish_date, content: content, images: images)

      puts "******************************************************"
      puts "Titulo: #{title}"
      puts "Fecha de publicación: #{publish_date}"
      puts "Contenido: #{content}"
      puts "Images: #{images.inspect}"
      puts "******************************************************"
    end

    def article_slug(uri)
      match_data = uri.path.match(/\/notas\/\d+\/(.+)\.html/)
      match_data[1]
    end
  end
end
