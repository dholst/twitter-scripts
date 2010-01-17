#!/usr/bin/ruby

require 'rubygems'
gem 'twitter4r'
require 'twitter'
require 'time'
require 'net/http'
require 'uri'
require 'json'

SEARCH_URL = 'http://search.twitter.com/search.json'
SEARCH_TERM = '?from=gocards300'

next_query_file = File.join(File.dirname($0), '.' + File.basename($0, '.rb'))
search_url = SEARCH_URL + SEARCH_TERM
search_url = SEARCH_URL + File.read(next_query_file) if(File.exists?(next_query_file))

response = Net::HTTP.get_response(URI.parse(search_url))

raise "Some kind of non OK response - #{response.code}" unless response.code == '200'

json = JSON.parse(response.body)
File.new(next_query_file, 'w').write(json['refresh_url'])

json['results'].reverse.each do |r|  
  t = Twitter::Client.new(:login => 'username', :password => 'password')
  puts t.status(:post, "#{r['text'].split(' ').reverse.map{|w| m = w.match(/(.*?)([,|\.|!|\?|:|;]*)$/); "#{m[2]}#{m[1]}"}.join(' ')}")  
end
