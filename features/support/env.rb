# --                                                            ; {{{1
#
# File        : support/env.rb
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-12-05
#
# Copyright   : Copyright (C) 2013  Felix C. Stegerman
# Licence     : GPLv2
#
# --                                                            ; }}}1

require 'capybara/cucumber'
require 'capybara/poltergeist'
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

module HTTPHelpers                                              # {{{1

  def host
    "http://localhost:#{@port}"
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

  def waitfor_listener(id)
    (@events ||= {})[id] = waitfor id
  end

  def get(path)
    r = Faraday.get "#{host}#{path}"
    raise "get (#{path}) status was #{r.status}" unless r.success?
    r.body
  end

  def post(path, data = nil)                                    # {{{2
    r = Faraday.post "#{host}#{path}" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = data
    end
    raise "post (#{path}) status was #{r.status}" unless r.success?
    r.body
  end                                                           # }}}2

end                                                             # }}}1

module ChatHelpers                                              # {{{1

  def listen_w_redir(path, *args)
    listen JSON.parse(get path)['location'], *args
  end

  def events(str)                                               # {{{2
    str.split("\n\n").map do |e|
      m = /\Aevent: (?<event>\w+)\ndata: (?<data>.*)\Z/m.match(e) \
            || raise("event stream parsing failure: #{e}")
      d = JSON.parse(m[:data]); d.delete 'time'
      { event: m[:event], data: d }
    end # .reject { |e| e[:event] == 'ping' } # TODO
  end                                                           # }}}2

  def ui_chat
    # PhantomJS + EventSource blocks w/ visit('/') :-(
    visit 'about:blank'
    page.execute_script "document.location = \"#{host}/\""
    find '.msg', text: 'welcome to devnull'
  end

  def ui_set_nick(nick)
    fill_in 'command', with: "/nick #{nick}"
    click_on 'send'
    find '.msg', text: "is now known as #{nick}"
  end

  def ui_join(channel)
    fill_in 'command', with: "/join #{channel}"
    click_on 'send'
    find '.msg', text: "has joined #{channel}"
  end

  def ui_say(msg)
    fill_in 'command', with: msg
    click_on 'send'
    find '.msg', text: msg
  end

  def api_listen_nick_join_say(nick, n, ch, msg)                # {{{2
    h = { id: "SecureRandom-#{n}" }
    p = -> p, d { post p, h.merge(d).to_json }
    listen_w_redir '/events', nick
    p['/nick', { nick:    nick  }]
    p['/join', { channel: ch    }]
    p['/say' , { message: msg   }]
  end                                                           # }}}2

  def ui_messages_are(msgs)
    expect(parse_ui_messages).to eq(parse_messages msgs)
  end

  def api_messages_are(nick, msgs)
    api_msgs = parse_api_messages events(@events[nick])
    expect(api_msgs).to eq(parse_messages msgs)
  end

  def parse_messages(msgs)                                      # {{{2
    msgs.lines.map do |l|
      l =~ /^\s+\*\s+(.*)$/
      case $1
      when /^(welcome|join|nick|say|me) +`(.*)` +`(.*)`$/
        u, m = case $1.to_sym
        when :welcome ; ['*', "welcome to #{$3}, #{$2}"]
        when :join    ; ['*', "#{$2} has joined #{$3}"]
        when :nick    ; ['*', "#{$2} is now known as #{$3}"]
        when :say     ; [$2, $3]
        when :me      ; [$2, "* #{$2} #{$3}"]
        else raise "UI messages level 2 parsing failure: #{$1}"
        end
        { user: u, msg: m }
      else raise "UI messages level 1 parsing failure: #{$1}"
      end
    end
  end                                                           # }}}2

  def parse_ui_messages
    find('#messages').all('.message').map do |msg|
      { user: msg.find('.user').text,
        msg:  msg.find('.msg' ).text }
    end
  end

  def parse_api_messages(msgs)                                  # {{{2
    msgs.map do |m|
      e = m[:event].to_sym; d = Hash[m[:data].map{|k,v|[k.to_sym,v]}]
      usr, msg = case e
      when :welcome ; ['*', "welcome to #{d[:channel]}, #{d[:nick]}"]
      when :join    ; ['*', "#{d[:nick]} has joined #{d[:channel]}"]
      when :nick    ; ['*', "#{d[:from]} is now known as #{d[:to]}"]
      when :say     ; [d[:nick], d[:message]]
      when :me      ; [d[:nick], "* #{m[:nick]} #{d[:message]}"]
      when :ping      # ignore
      else raise "API messages parsing failure: #{m}"
      end
      { user: usr, msg: msg }
    end
  end                                                           # }}}2

end                                                             # }}}1

class MyWorld                                                   # {{{1
  include HTTPHelpers, ChatHelpers

  def initialize(port)
    @port                       = port
    Capybara.run_server         = false
    Capybara.javascript_driver  = :poltergeist
  end
end                                                             # }}}1

World { MyWorld.new port }

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
