#!/usr/bin/ruby

require 'rubygems'
require 'net/pop'
require 'openssl'
gem 'twitter4r'
require 'twitter'
require 'time'

module Net

# == Examples
#
# === Retrieving Messages
#
# This example retrieves messages from the server and deletes them
# on the server.
#
# Messages are written to files named 'inbox/1′, 'inbox/2′, ….
# Replace 'pop.example.com' with your POP3 server address, and
# 'YourAccount' and 'YourPassword' with the appropriate account
# details.
#
# require 'net/pops'
#
# pop = Net::POP3.new('pop.example.com', pop3_ssl_port)
# pop.use_ssl = true
# pop.start('YourAccount', 'YourPassword') # (1)
# if pop.mails.empty?
# puts 'No mail.'
# else
# i = 0
# pop.each_mail do |m| # or "pop.mails.each …" # (2)
# File.open("inbox/#{i}", 'w') do |f|
# f.write m.pop
# end
# m.delete
# i += 1
# end
# puts "#{pop.mails.size} mails popped."
# end
# pop.finish # (3)
#
# 1. Call Net::POP3#start and start POP session.
# 2. Access messages by using POP3#each_mail and/or POP3#mails.
# 3. Close POP session by calling POP3#finish or use the block form of #start.

class POP3

remove_method :do_start
remove_method :initialize

def initialize( addr, port = nil, isapop = false )
@address = addr
@port = port || self.class.default_port
@apop = isapop

@command = nil
@socket = nil
@started = false
@open_timeout = 30
@read_timeout = 60
@debug_output = nil

@mails = nil
@n_mails = nil
@n_bytes = nil

@use_ssl = false
@ssl_context = nil

end

def do_start( account, password )
s = timeout(@open_timeout) { TCPSocket.open(@address, @port) }
if use_ssl?
unless @ssl_context.verify_mode
warn "warning: peer certificate won't be verified in this SSL session"
@ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
end
s = OpenSSL::SSL::SSLSocket.new(s, @ssl_context)
s.sync_close = true
end
@socket = Net::InternetMessageIO.new(s)
@socket.read_timeout = @read_timeout
@socket.debug_output = @debug_output

if use_ssl?
s.connect
end

on_connect
@command = POP3Command.new(@socket)
if apop?
@command.apop account, password
else
@command.auth account, password
end
@started = true
ensure
do_finish if not @started
end
private :do_start

def use_ssl?
@use_ssl
end

# For backward compatibility.
alias use_ssl use_ssl?

# Turn on/off SSL.
# This flag must be set before starting session.
# If you change use_ssl value after session started,
# a Net::HTTP object raises IOError.
def use_ssl=(flag)
flag = (flag ? true : false)
raise IOError, "use_ssl value changed, but session already started" \
if started? and @use_ssl != flag
if flag and not @ssl_context
@ssl_context = OpenSSL::SSL::SSLContext.new
end
@use_ssl = flag
end

def self.ssl_context_accessor(name)
module_eval(<<-End, __FILE__, __LINE__ + 1)
def #{name}
return nil unless @ssl_context
@ssl_context.#{name}
end

def #{name}=(val)
@ssl_context ||= OpenSSL::SSL::SSLContext.new
@ssl_context.#{name} = val
end
End
end

ssl_context_accessor :key
ssl_context_accessor :cert
ssl_context_accessor :ca_file
ssl_context_accessor :ca_path
ssl_context_accessor :verify_mode
ssl_context_accessor :verify_callback
ssl_context_accessor :verify_depth
ssl_context_accessor :cert_store

def ssl_timeout
return nil unless @ssl_context
@ssl_context.timeout
end

def ssl_timeout=(sec)
raise ArgumentError, 'Net::POP3#ssl_timeout= called but use_ssl=false' \
unless use_ssl?
@ssl_context ||= OpenSSL::SSL::SSLContext.new
@ssl_context.timeout = sec
end

# For backward compatibility
alias timeout= ssl_timeout=

def peer_cert
return nil if not use_ssl? or not @socket
@socket.io.peer_cert
end
end
end

def format_email(email)
  m = email.match(/<(.*@.*)>/)
  return m[1] if m
  email
end

def format_time(date)
  date ||= Time.new.to_s
  Time.parse(date).strftime('%I:%M:%S')
end

pop3 = Net::POP3.new('pop.gmail.com', 995)
pop3.use_ssl = true
pop3.start('pop3user', 'pop3password') do |pop|
  pop.mails.each do |m|
    from = nil
    subject = nil
    date = nil
    
    m.mail do |line|
      line.strip!
      
      m = line.match(/^From: (.*)/i)
      from = m[1] if m && from == nil
      
      m = line.match(/^Subject: (.*)/i)
      subject = m[1] if m && subject == nil
      
      m = line.match(/^Date: (.*)/i)
      date = m[1] if m && date == nil
    end
    
    if(from)
      t = Twitter::Client.new(:login => 'twitterusername', :password => 'twitterpassword')
      puts t.status(:post, "mail from #{format_email(from)} at #{format_time(date)} >> #{subject}")
    end
  end
end
