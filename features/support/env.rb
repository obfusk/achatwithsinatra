# --                                                            ; {{{1
#
# File        : support/env.rb
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-12-03
#
# Copyright   : Copyright (C) 2013  Felix C. Stegerman
# Licence     : GPLv2
#
# --                                                            ; }}}1

require 'capybara/cucumber'
require 'childprocess'
require 'em-http'
require 'faraday'
require 'timeout'

require './achatwithsinatra'

port    = ENV['PORT'] && !ENV['PORT'].blank? ? ENV['PORT'] : 9999
server  = ChildProcess.build *%W{ rackup -p #{port} }
server.environment['ACHATWITHSINATRA_CUKE'] = 'yes'
server.io.inherit! if ENV['INHERIT_IO'] == 'yes'
server.start; at_exit { server.stop }

Timeout.timeout(3) do                                           # {{{1
  loop do
    begin
      Faraday.get "http://localhost:#{port}"
      break
    rescue Faraday::Error::ConnectionFailed
      sleep 0.1
    end
  end
end                                                             # }}}1

module Helpers                                                  # {{{1

  def host
    "http://localhost:#{@port}"
  end

  def listeners
    @listeners ||= {}
  end

  def listen(path, id, timeout = 1)                             # {{{2
    r, w = IO.pipe
    pid = fork do
      r.close; body = ''
      EM.run do
        http = EM::HttpRequest.new(
          "#{host}#{path}", inactivity_timeout: timeout
        ).get redirects: 5
        http.errback { raise 'OOPS' }
        http.stream { |c| body << c }
        http.callback { EM.stop }
        w.write "OK\n"
      end
      w.write body; w.close; exit!  # no at_exit
    end
    listeners[id] = { pid: pid, r: r }
    w.close; r.readline   # wait for OK
  end                                                           # }}}2

  def waitfor(id)
    l = listeners[id]; data = l[:r].read; l[:r].close
    Process.wait l[:pid]; listeners.delete id
    data
  end

  def get(path)
    Faraday.get "#{host}#{path}"
  end

  def post(path, data = nil)
    Faraday.post "#{host}#{path}" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = data
    end
  end

end                                                             # }}}1

World do
  w = Object.new; w.instance_eval { @port = port }; w
end

World Helpers

# vim: set tw=70 sw=2 sts=2 et fdm=marker :