# --                                                            ; {{{1
#
# File        : achatwithsinatra.rb
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-12-05
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
  KEEP_ALIVE      = 15
  LOGIN_TIMEOUT   = 15

  CSS             = %w{ /css/bootstrap.min.css /css/ui.css }
  SCRIPTS         = %w{
    /js/EventSource.js /js/jquery.min.js /__coffee__/ui.js
  }

  set :server, :thin
  set :show_exceptions, :after_handler
  set state: BLANK_STATE[]

  def json_body
    JSON.parse request.body.read
  end

  def empty_response
    ''
  end

  def send(out, event, data = {})
    d = data.merge time: Time.new.strftime('%F %T')
    out << "event: #{event}\ndata: #{d.to_json}\n\n"
    puts "event: #{event}\ndata: #{d.to_json}\n\n" if DEBUG
  end

  def send_from(user, event, msg)
    channel(user[:channel]).each { |out| send out, event, msg }
  end

  def channel(c)
    settings.state[:channels][c] ||= []
  end

  def set_channel(user, c)
    unless (old = user[:channel]) == c
      user[:channel] = c
      channel(old).delete user[:_conn]
      channel(c) << user[:_conn]
    end
  end

  def cleanup(user)
    user[:_timer].cancel
    channel(user[:channel]).delete user[:_conn]
    rm_user user
  end

  def rm_user(user)
    settings.state[:users].delete user[:id]
  end

  def add_user
    user = new_user; settings.state[:users][user[:id]] = user
    EM::Timer.new(LOGIN_TIMEOUT) { rm_user user unless user[:_conn] }
    user
  end

  def connect_user(user, out)
    c = DEFAULT_CHANNEL
    t = EM::PeriodicTimer.new(KEEP_ALIVE) { send out, :ping }
    user.merge! _conn: out, _timer: t, channel: c
    channel(c) << out; out.callback { cleanup user }
    [user, c]
  end

  def new_user
    n = settings.state[:n] += 1
    { id: new_id(n), nick: "guest#{n}" }
  end

  def get_user(id)
    settings.state[:users][id] || raise(UnknownUser, id)
  end

  def all_nicks
    settings.state[:users].values.map { |x| x[:nick] }
  end

  def set_nick(id, nick)
    if nick.empty?
      { error: 'empty nick' }
    elsif nick =~ /^guest\d+$/
      { error: 'is a guest nick' }
    elsif all_nicks.include? nick
      { error: 'nick is taken' }
    else
      settings.state[:users][id][:nick] = nick
      { nick: nick }
    end
  end

  def sanitize(h)
    h.reject { |x| x.to_s.start_with? '_' }
  end

  def join_say_me(event, &b)
    data = json_body; user = get_user data['id']; d = b[user, data]
    send_from user, event, { nick: user[:nick] }.merge(d)
    empty_response
  end

  if DEBUG
    def new_id(n)
      "SecureRandom-#{n}"
    end

    before do
      s = settings.state
      puts "n: #{s[:n]}; channels: #{s[:channels].keys*', '}"
      puts 'users:'
      s[:users].each do |k,v|
        v2 = v.merge _conn: v[:_conn].class, _timer: v[:_timer].class
        puts "  #{k} => #{v2}"
      end
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

  get '/' do
    haml :ui
  end

  get '/channels' do
    content_type :json
    settings.state[:channels].keys.sort.to_json
  end

  get '/events' do
    content_type :json
    id = add_user[:id]
    { location: "/events/#{id}", id: id }.to_json
  end

  get '/events/:id' do |id|
    user = get_user id
    content_type 'text/event-stream'
    stream(:keep_open) do |out|
      user, ch = connect_user user, out
      send out, :welcome, sanitize(user)
      send_from user, :join, nick: user[:nick], channel: ch
    end
  end

  post '/join' do
    join_say_me(:join) do |user, data|
      set_channel user, data['channel']
      { channel: data['channel'] }
    end
  end

  post '/say' do
    join_say_me(:say) do |user, data|
      { message: data['message'] }
    end
  end

  post '/me' do
    join_say_me(:me) do |user, data|
      { message: data['message'] }
    end
  end

  post '/nick' do
    content_type :json
    data = json_body  ; user  = get_user data['id']
    from = user[:nick]; res   = set_nick user[:id], data['nick']
    send_from user, :nick, from: from, to: res[:nick] \
      unless res[:error]
    res.to_json
  end

  get '/__coffee__/:name.js' do |name|
    content_type :js
    coffee :"coffee/#{name}"
  end

  error UnknownUser do
    "Unknown user: #{env['sinatra.error'].message}\n"
  end

end

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
