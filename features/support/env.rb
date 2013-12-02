require 'capybara/cucumber'
require 'childprocess'
require 'em-http-request'
require 'faraday'
require 'timeout'

require './achatwithsinatra'

port    = ENV['PORT'] && !ENV['PORT'].blank? ? ENV['PORT'] : 9999
server  = ChildProcess.build *%W{ rackup -p #{port} }
server.environment['ACHATWITHSINATRA_CUKE'] = 'yes'
server.io.inherit! if ENV['INHERIT_IO'] == 'yes'
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

  def listeners
    @listeners ||= {}
  end

  def listen(path, id, timeout = 5)                             # {{{2
    r, w = IO.pipe
    if pid = fork
      listeners[id] = { pid: pid, r: r }
      w.close
      r.readline # wait for OK
    else
      r.close
      body = ''
      EM.run do
        http = EM::HttpRequest.new(
          "#{host}/#{path}", inactivity_timeout: timeout
        ).get redirects: 5
        http.errback { raise 'OOPS' }
        http.stream { |c| body << c }
        http.callback { EM.stop }
        w.write "OK\n"
      end
      w.write body
      w.close
      exit!
    end
  end                                                           # }}}2

  def waitfor(id)
    data = listeners[id][:r].read
    listeners[id][:r].close
    Process.wait listeners[id][:pid]
    listeners.delete id
    data
  end

  def get(path)
    Faraday.get "#{host}/#{path}"
  end

  def post(path, data = nil)
    Faraday.post "#{host}/#{path}" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = data
    end
  end

end                                                             # }}}1

World do
  w = Object.new
  w.instance_eval { @port = port }
  w
end

World Helpers
