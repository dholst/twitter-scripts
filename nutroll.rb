#!/usr/bin/ruby

require 'rubygems'
gem 'twitter4r'
require 'twitter'
require 'time'
require 'net/http'
require 'uri'
require 'json'

PHRASES = [
	'AHHHHHH!!! Spider.',
	'...McDoogles...',
	'Look at all them Escorts for sale.',
	'Owwww, stop it, that hurts my ears.',
	'What?',
	'Make it look like the picture.',
	'They have the best onion rings.',
	'That\'s a lot of food.',
	'Mmmm, I\'ll have to remember this recipe.',
	'I want to eat me a hot roast beef sandwich.',
	'Somewhere that doesn\'t serve fries.',
	'That\'s cool.',
	'That\'s interesting.',
	'That pelonis is looking at me.',
	'The first song on Appetite for Destruction is Appetite for Destruction.',
	'I couldn\'t get a tattoo, but check out my nipple ring.',
	'Hey, do you have the new Dick Cheese album?',
	'something about pie'  
]

SEARCH_URL = 'http://search.twitter.com/search.json'
SEARCH_TERM = '?q=nutroll'

next_query_file = File.join(File.dirname($0), '.' + File.basename($0, '.rb'))
search_url = SEARCH_URL + SEARCH_TERM
search_url = SEARCH_URL + File.read(next_query_file) if(File.exists?(next_query_file))

response = Net::HTTP.get_response(URI.parse(search_url))

raise "Some kind of non OK response - #{response.code}" unless response.code == '200'

json = JSON.parse(response.body)
File.new(next_query_file, 'w').write(json['refresh_url'])

if json['results'].size
  t = Twitter::Client.new(:login => 'username', :password => 'password')
  puts t.status(:post, PHRASES.sort_by{rand}.first)  
end


