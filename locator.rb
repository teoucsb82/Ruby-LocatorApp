require 'json'
require 'addressable/uri'
require 'rest-client'
require 'nokogiri'


SUPER_SECRET_API_KEY = File.read("secret_key.txt")

class Locator

  def initialize
    @storefront = what_to_locate
    @start_coord = get_lat_long
    @destination_coord = find_places
    print_directions
  end

  def what_to_locate
    puts "What are you looking for today?"
    gets.chomp
  end

  def find_user_location
    puts "Please enter your address: "
    gets.chomp
  end

  def geocode_request
    query = Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/geocode/json",
      :query_values => {
        :address => find_user_location,
        :sensor => false,
        :key => SUPER_SECRET_API_KEY
      }
    ).to_s
  end

  def places_request
    query = Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/place/nearbysearch/json",
      :query_values => {
        :location => @start_coord,
        :keyword => @storefront,
        :sensor => false,
        :rankby => "distance",
        :key => SUPER_SECRET_API_KEY
      }
    ).to_s
  end

  def directions_query
    query = Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/directions/json",
      :query_values => {
        :origin => @start_coord,
        :destination => @destination_coord,
        :sensor => false,
        :mode => "walking"
      }
    ).to_s
  end

  def get_lat_long
    location_result = JSON.parse(RestClient.get(geocode_request))
    location =  location_result["results"][0]["geometry"]["location"]
    lat = location["lat"]
    long = location["lng"]
    "#{lat}, #{long}"
  end

  def find_places
    location_result = JSON.parse(RestClient.get(places_request))
    @name = location_result["results"].first["name"]
    @destination_address = location_result["results"].first["vicinity"]
    location = location_result["results"].first["geometry"]["location"]

    lat =  location["lat"]
    long = location["lng"]
    "#{lat}, #{long}"
  end


  def give_directions
    JSON.parse(RestClient.get(directions_query))
  end

  def print_directions
    directions = give_directions
    final_destination = ""
    30.times { puts "" }
    puts "Let's take a walk to #{@name} (#{directions["routes"][0]["legs"][0]["distance"]["text"]})"
    puts "Located at #{@destination_address}"
    directions["routes"][0]["legs"][0]["steps"].each_with_index do |step, idx|
      parsed_html = Nokogiri::HTML(step["html_instructions"]).text
      if parsed_html.include?("Destination")
        newline = parsed_html.index("Destination")
        final_destination = parsed_html[newline..-1]
        parsed_html = parsed_html[0...newline] 
      end
      puts "Step #{idx + 1} = #{parsed_html}"
    end
      puts final_destination
  end


end

l = Locator.new
