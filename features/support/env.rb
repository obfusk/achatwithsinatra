require 'capybara/cucumber'
require 'childprocess'
require 'em-http-request'
require 'faraday'
require 'timeout'

require './achatwithsinatra'

port    = ENV['PORT'] && !ENV['PORT'].blank? ? ENV['PORT'] : 9999
server  = ChildProcess.build *%W{ rackup -p #{port} }
server.environment['ACHATWITHSINATRA_CUKE'] = 'yes'
# server.io.inherit!
server.start
at_exit { server.stop }

Timeout.timeout(3) do
  loop do
    begin
      Faraday.get "http://localhost:#{port}"
      break
    rescue Faraday::Error::ConnectionFailed
      sleep 0.1
    end
  end
end

module Helpers                                                  # {{{1
  def host
    "http://localhost:#{@port}"
  end
  def get(path)
    Faraday.get "#{host}/#{path}"
  end
  def aget(path, n = 1)
    body = ''
    EM.run do
      http = EM::HttpRequest.new(
        "#{host}/#{path}", inactivity_timeout: n
      ).get redirects: 5
      http.stream { |c| body << c }
      http.callback { EM.stop }
    end
    body
  end
  def post(path)
    Faraday.post "#{host}/#{path}"
  end
end                                                             # }}}1

World do
  w = Object.new
  w.instance_eval { @port = port }
  w
end

World Helpers
