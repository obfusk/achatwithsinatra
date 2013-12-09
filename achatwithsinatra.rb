# --                                                            ; {{{1
#
# File        : achatwithsinatra.rb
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-12-09
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
  class EmptyChannel < RuntimeError; end

  BLANK_STATE     = -> { ... }
  DEFAULT_CHANNEL = 'devnull'
  KEEP_ALIVE      = 15
  LOGIN_TIMEOUT   = 15

  CODE_LINK       = 'https://github.com/obfusk/achatwithsinatra'

  CSS             = %w{ /css/bootstrap.min.css /css/ui.css }
  SCRIPTS         = %w{ /js/jquery.min.js /__coffee__/ui.js }

  set :server, :thin
  set :show_exceptions, :after_handler
  set state: BLANK_STATE[]

  def json_body
    JSON.parse request.body.read
  end

  def empty_response
    ''
  end

  ...

  get '/' do
    haml :ui
  end

  ...

  get '/__coffee__/:name.js' do |name|
    content_type :js
    coffee :"coffee/#{name}"
  end

  error UnknownUser do
    "Unknown user: #{env['sinatra.error'].message}\n"
  end

  error EmptyChannel do
    "Empty channel\n"
  end

end

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
