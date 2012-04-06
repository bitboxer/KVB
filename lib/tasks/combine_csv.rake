# encoding: utf-8
namespace :extract do
  require 'csv'

  def fix_name(name)
    name = name.gsub("str.", "straße")
    name = name.gsub("Str.", "Straße")
    name
  end

  def find_geo(name)
    return @cache[fix_name(name)] || []
  end

  def append_coordinates(name, coordinates)
    @cache[name] = [] if @cache[name].nil?
    @cache[name] << coordinates
  end

  def parse_my_file(file, type)
    doc = Nokogiri::XML(open(file))

    doc.search('//node').each do |node|
      ortsteilN = node.search("tag[k='VRS:gemeinde']").first
      ortsteil = nil
      if (ortsteilN)
        ortsteil = ortsteilN.get_attribute("v")
      end

      next if ortsteil.nil? || ortsteil != "KÖLN"

      coordinates = {
        lat: node.get_attribute("lat"),
        long:node.get_attribute("lon"),
        type: type
      }

      name = ""

      nameNode = node.search("tag[k='name']").first
      if (nameNode)
        name = nameNode.get_attribute("v")
        append_coordinates(fix_name(name), coordinates)
      end
      kvbNameNode = node.search("tag[k='VRS:name']").first
      if (kvbNameNode && name != kvbNameNode.get_attribute("v"))
        append_coordinates(fix_name(kvbNameNode.get_attribute("v")), coordinates)
      end

    end
  end

  def build_cache
    @cache = {}
    parse_my_file('trainstop.osm', 'bahn')
    parse_my_file('busstop.osm', 'bus')
  end

  desc "extract kvb web"
  task :combine do
    build_cache

    opts = {:col_sep => ";", :quote_char => '§'}
    @stops = CSV.read("kvb_station_ids.csv", opts)

    @stops.each do |stop|
      next if stop[1].match("Stand.*") || stop[1].nil?

      geos = find_geo(stop[1])
      geos.each do |geo|
        puts "#{stop[0]};#{stop[1]};#{geo[:lat]};#{geo[:long]};#{geo[:type]}"
      end
      if geos.length == 0
        puts "#{stop[0]};#{stop[1]};;;"
      end
    end
  end
end

