namespace :extract do
  require 'open-uri'

  def parse_web(number)
    doc = Nokogiri::HTML(open("http://www.kvb-koeln.de/qr/#{number}"))
    doc.css("div[class='qr_top_head_rot_small']").each do |link|
      puts "#{number};#{link.children.first.content}"
      STDOUT.flush
    end
  end

  desc "extract kvb web"
  task :kvb_web do
    (1..1000).each do|i|
      parse_web(i)
    end
  end
end

