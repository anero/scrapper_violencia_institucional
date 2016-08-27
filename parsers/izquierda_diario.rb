require 'base'

module Parsers
  class IzquierdaDiario < Base
    ITEMS_PER_PAGE = 24
    SOURCES = ['http://www.laizquierdadiario.com/Gatillo-facil', 'http://www.laizquierdadiario.com/Violencia-institucional', 'http://www.laizquierdadiario.com/Torturas']

    def parse
      # TODO: DRY
      SOURCES.each do |source|
        @total_pages = calculate_total_pages(source)
        @page_number = 0

        while (@page_number < @total_pages)
          puts "Procesando página #{@page_number} de la lista #{source}"
          uri = URI("#{source}?debut_articulos=#{@page_number * ITEMS_PER_PAGE}#pagination_articulos")

          raw = Net::HTTP.get(uri)
          doc = Nokogiri::HTML(raw)

          articles_url = doc.css('.noticia h3 a').map {|a| a.attr 'href' }
          articles_url.each {|article_url| process_page(URI("http://www.laizquierdadiario.com/#{article_url}")) }

          @page_number += 1
        end
      end
    end

    private

    def calculate_total_pages(source)
      raw = Net::HTTP.get(URI(source))
      doc = Nokogiri::HTML(raw)

      last_page = doc.css('.pagination .pages a:last-child').first.content.to_i
      last_page / ITEMS_PER_PAGE
    end

    def process_page(uri)
      article_slug = uri.path.gsub('/', '')
      existing_article = db[:articles].find(source: 'izquierda_diario', slug: article_slug).first
      if existing_article
        puts "Salteando artículo #{article_slug}"
        return
      end

      puts "Procesando artículo #{article_slug}"

      raw = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(raw)

      title = doc.css('.header-articulo h1').first.content
      publish_date = doc.xpath('//article/div[@class="row"][2]/div/p/span').first.content.gsub("\n", '')
      content = doc.css('.articulo p').inject('') {|full_content, paragraph| full_content << paragraph.content }
      images = doc.css('.articulo .foto img').map {|i| i.attr 'src' }

      db[:articles].insert_one(source: 'izquierda_diario', url: uri.to_s, slug: article_slug, title: title, publish_date: publish_date, content: content, images: images)

      puts "******************************************************"
      puts "URL: #{uri.to_s}"
      puts "Slug: #{article_slug}"
      puts "Titulo: #{title}"
      puts "Fecha de publicación: #{publish_date}"
      puts "Contenido: #{content}"
      puts "Images: #{images.inspect}"
      puts "******************************************************"
    end
  end
end
