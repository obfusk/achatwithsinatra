# --                                                            ; {{{1
#
# File        : achatwithsinatra.rb
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-12-03
#
# Copyright   : Copyright (C) 2013  Felix C. Stegerman
# Licence     : GPLv2
#
# --                                                            ; }}}1

require 'coffee-script'
require 'haml'
require 'json'
require 'securerandom'
require 'sinatra/base'

class AChatWithSinatra < Sinatra::Base

  class UnknownUser < RuntimeError; end

  BLANK_STATE     = -> { { channels: {}, users: {}, n: 0 } }
  DEBUG           = ENV['ACHATWITHSINATRA_CUKE'] == 'yes'
  DEFAULT_CHANNEL = 'devnull'

  set state: BLANK_STATE[]

  def json_body
    JSON.parse request.body.read
  end

  def empty_response
    ''
  end

  def channel(c)
    settings.state[:channels][c] ||= []
  end

  def set_channel(user, c)
    unless (old = user[:channel]) == c
      user[:channel] = c
      channel(old).delete user[:_out]
      channel(c) << user[:_out]
    end
  end

  def cleanup(user)
    puts "cleaning up #{user.inspect}"
    channel(user[:channel]).delete user[:_out]
    settings.state[:users].delete user[:id]
  end

  def send(out, event, data)
    out << "event: #{event}\ndata: #{data.to_json}\n\n"
  end

  def send_from(user, event, msg)
    channel(user[:channel]).each { |out| send out, event, msg }
  end

  def new_user(c, out)
    n = settings.state[:n] += 1
    { id: new_id(n), nick: "guest#{n}", channel: c, _out: out }
  end

  def get_user(id)
    settings.state[:users][id] || raise(UnknownUser, id)
  end

  def all_nicks
    settings.state[:users].values.map { |x| x[:nick] }
  end

  def set_nick(id, nick)
    if nick =~ /^guest\d+$/
      { error: 'is a guest nick' }
    elsif all_nicks.include? nick
      { error: 'nick is taken' }
    else
      settings.state[:users][id][:nick] = nick; { nick: nick }
    end
  end

  def sanitize(h)
    h.reject { |x| x.to_s.start_with? '_' }
  end

  if DEBUG
    def new_id(n)
      "SecureRandom##{n}"
    end

    before do
      puts "state: #{settings.state.inspect}"
    end

    post '/reset' do
      settings.state = BLANK_STATE[]
      empty_response
    end
  else
    def new_id(n)
      SecureRandom.hex 32
    end
  end

  get '/channels' do
    content_type :json
    settings.state[:channels].keys.sort.to_json
  end

  get '/events' do
    c = DEFAULT_CHANNEL
    content_type 'text/event-stream'
    stream(:keep_open) do |out|
      user = new_user c, out; settings.state[:users][user[:id]] = user
      channel(c) << out; out.callback { cleanup user }
      send out, :welcome, sanitize(user)
      send_from user, :join, nick: user[:nick], channel: c
    end
  end

  post '/join' do
    data = json_body; user = get_user data['id']
    set_channel user, data['channel']
    send_from user, :join, nick: user[:nick], channel: data['channel']
    empty_response
  end

  post '/say' do
    data = json_body; user = get_user data['id']
    send_from user, :say, nick: user[:nick], message: data['message']
    empty_response
  end

  post '/me' do
    data = json_body; user = get_user data['id']
    send_from user, :me, nick: user[:nick], message: data['message']
    empty_response
  end

  post '/nick' do
    data = json_body  ; user  = get_user data['id']
    from = user[:nick]; res   = set_nick user[:id], data['nick']
    send_from user, :nick, from: from, to: res[:nick] \
      unless res[:error]
    res.to_json
  end

end

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
