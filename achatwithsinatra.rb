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

  BLANK_STATE = -> { { channels: {}, users: {}, n: 0 } }

  set state: BLANK_STATE[]

  def channel(c)
    settings.state[:channels][c] ||= []
  end

  def send(out, event, data)
    out << "event: #{event}\ndata: #{data.to_json}\n\n"
  end

  if ENV['ACHATWITHSINATRA_CUKE'] == 'yes'
    def new_id(n)
      "SecureRandom##{n}"
    end
  else
    def new_id(n)
      SecureRandom.hex 32
    end
  end

  def new_user
    n = settings.state[:n] += 1
    { id: new_id(n), nick: "guest#{n}" }
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
      u = new_user; settings.state[:users][u[:id]] = u[:nick]
      send out, :welcome, u
    end
  end

  post '/say/:channel' do |c|
    data = JSON.parse request.body.read
    channel(c).each { |out| send out, :say, data }
    ''  # empty response
  end

  if ENV['ACHATWITHSINATRA_CUKE'] == 'yes'
    post '/reset' do
      settings.state = BLANK_STATE[]
      ''  # empty response
    end
  end

end

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
