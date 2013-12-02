# --                                                            ; {{{1
#
# File        : achatwithsinatra.rb
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-12-02
#
# Copyright   : Copyright (C) 2013  Felix C. Stegerman
# Licence     : GPLv2
#
# --                                                            ; }}}1

require 'coffee-script'
require 'haml'
require 'json'
require 'sinatra/base'

class AChatWithSinatra < Sinatra::Base

  set state: { channels: {} }

  def channel(c)
    settings.state[:channels][c] ||= []
  end

  get '/channels' do
    content_type :json
    settings.state[:channels].keys.sort.to_json
  end

  get '/messages/:channel' do |c|
    content_type 'text/event-stream'
    stream(:keep_open) do |out|
      channel(c) << out
      out.callback { channel(c).delete out }
    end
  end

  post '/say/:channel' do |c|
    data = JSON.parse request.body.read
    channel(c).each do |out|
      out << "event: say\ndata: #{data.to_json}\n\n"
    end
    ''
  end

  if ENV['ACHATWITHSINATRA_CUKE'] == 'yes'
    post '/reset' do
      settings.state[:channels] = {}
    end
  end

end

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
