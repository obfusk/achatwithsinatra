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

  def events(str)
    str.split("\n\n").map do |e|
      m = /^event: (?<event>\w+)\ndata: (?<data>.*)$/.match(e) \
            || raise('event stream parsing failure')
      { event: m[:event], data: JSON.parse(m[:data]) }
    end
  end

  def listeners
    @listeners ||= {}
  end

  def listen(path, id, timeout = 1)                             # {{{2
    r, w = IO.pipe
    pid = fork do
      r.close
      EM.run do
        http = EM::HttpRequest.new(
          "#{host}#{path}", inactivity_timeout: timeout
        ).get redirects: 5
        http.stream { |c| w.write c }
        http.errback { raise "listen (#{path}) failure" }
        http.callback do
          h = http.response_header
          raise "listen (#{path}) status was #{h.status}" \
            unless h.successful?
          EM.stop
        end
      end
      w.close; exit!  # no at_exit
    end
    w.close; l = listeners[id] = { pid: pid, r: r }
    # make sure we wait for first line (of welcome message)
    l[:firstline] = r.readline
  end                                                           # }}}2

  def waitfor(id)
    l = listeners[id]; data = l[:firstline] + l[:r].read
    l[:r].close; Process.wait l[:pid]; listeners.delete id
    data
  end

  def get(path)
    r = Faraday.get "#{host}#{path}"
    raise "get (#{path}) status was #{r.status}" unless r.success?
    r.body
  end

  def post(path, data = nil)
    r = Faraday.post "#{host}#{path}" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = data
    end
    raise "post (#{path}) status was #{r.status}" unless r.success?
    r.body
  end

end                                                             # }}}1

World do
  w = Object.new; w.instance_eval { @port = port }; w
end

World Helpers

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
