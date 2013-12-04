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

  DEBUG       = ENV['ACHATWITHSINATRA_CUKE'] == 'yes'
  BLANK_STATE = -> { { channels: {}, users: {}, n: 0 } }

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

  def send(out, event, data)
    out << "event: #{event}\ndata: #{data.to_json}\n\n"
  end

  def send_from(user, event, msg)
    channel(user[:channel]).each { |out| send out, event, msg }
  end

  def new_user(c)
    n = settings.state[:n] += 1
    { id: new_id(n), nick: "guest#{n}", channel: c }
  end

  def get_user(id)
    settings.state[:users][id] || raise("unknown id: #{id}")
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
    redirect '/events/devnull'  # default channel
  end

  get '/events/:channel' do |c|
    content_type 'text/event-stream'
    stream(:keep_open) do |out|
      channel(c) << out; out.callback { channel(c).delete out }
      u = new_user c; settings.state[:users][u[:id]] = u
      send out, :welcome, u
    end
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
