require 'rubygems'
require 'twitter'

twitter = Twitter::Base.new(Twitter::HTTPAuth.new('username', 'password'))

twitter.user_timeline(:count => "200").each do |tweet|
  puts "killing #{tweet[:text]}"

  begin
    twitter.status_destroy(tweet[:id])
  rescue Exception => e
    puts "OOPS - #{e}"
  end
end