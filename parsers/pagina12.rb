require 'base'

module Parsers
  class Pagina12 < Base
    SOURCES = ['http://www.pagina12.com.ar/buscador/resultado.php?q=violencia+institucional', 'http://www.pagina12.com.ar/buscador/resultado.php?q=gatillo+f%E1cil']

    def parse
      SOURCES.each do |source|
        loop do
          uri = URI(source)
          raw = Net::HTTP.get(uri)
          doc = Nokogiri::HTML(raw)

          articles_url = doc.css('.r_ocurrencia h3 a').map {|a| a.attr 'href' }
          articles_url.each {|article_url| process_page(URI("http://www.pagina12.com.ar#{article_url}")) }
        end
      end
    end

    private

    def process_page(uri)
      # TODO: Filtrar artículos que no sean noticias de Argentina

      article_slug = article_slug(uri)
      existing_article = db[:articles].find(source: 'pagina12', slug: article_slug).first
      if existing_article
        puts "Salteando artículo #{article_slug}"
        return
      end

      puts "Procesando artículo #{article_slug}"

      raw = Net::HTTP.get(uri)
      doc = Nokogiri::HTML(raw)

      title = doc.css('.nota h2').first.content
      fecha_edicion = doc.css('.fecha_edicion').first
      if fecha_edicion
        publish_date = fecha_edicion.content
      end
      content = doc.css('#cuerpo p:not(.margen0)').inject('') {|full_content, paragraph| full_content << paragraph.content }
      images = doc.css('.foto_nota img').map {|i| i.attr 'src' }

      db[:articles].insert_one(source: 'pagina12', url: uri.to_s, slug: article_slug, title: title, publish_date: publish_date, content: content, images: images)

      puts "******************************************************"
      puts "URL: #{uri.to_s}"
      puts "Slug: #{article_slug}"
      puts "Titulo: #{title}"
      puts "Fecha de publicación: #{publish_date}"
      puts "Contenido: #{content}"
      puts "Images: #{images.inspect}"
      puts "******************************************************"
    end

    def article_slug(uri)
      match_data = uri. path.match(/\/diario\/(.+)\.html/)
      match_data[1]
    end
  end
end
