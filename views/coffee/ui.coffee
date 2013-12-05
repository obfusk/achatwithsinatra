$ ->
  msgs    = $('#messages')
  elem    = (cls, el = 'div') -> $ "<#{el} class=\"#{cls}\">"
  parsed  = (f) -> (e) -> f JSON.parse e.originalEvent.data

  push = (t, u, m) ->                                           # {{{1
    e   = elem 'message', 'li'
    et  = elem('text').text t
    eu  = elem('user').text u
    em  = elem('msg' ).text m
    e.append et, eu, em; msgs.append e
                                                                # }}}1

  $.get('/events').done (data) ->
    id = data.id; esrc = $ new EventSource data.location

    esrc.on 'error', (e) -> console.log 'EventSource error:', e

    esrc.on 'welcome', parsed (d) ->
      push d.time, '*', "welcome to #{d.channel}, #{d.nick}"

    esrc.on 'join', parsed (d) ->
      push d.time, '*', "#{d.nick} has joined #{d.channel}"

    esrc.on 'nick', parsed (d) ->
      push d.time, '*', "#{d.from} is now known as #{d.to}"

    esrc.on 'say', parsed (d) ->
      push d.time, d.nick, d.message

    esrc.on 'me', parsed (d) ->
      push d.time, d.nick, "* #{d.nick} #{d.message}"

    $('#controls').submit (e) ->                                # {{{1
      c = $('#command').val(); $('#command').val('')
      f = (n) -> c.substring(n).trim()
      [path, data] = switch
        when c.indexOf('/join ') == 0 then  ['/join', channel: f 5]
        when c.indexOf('/nick ') == 0 then  ['/nick', nick:    f 5]
        when c.indexOf('/say ' ) == 0 then  ['/say' , message: f 4]
        when c.indexOf('/me '  ) == 0 then  ['/me'  , message: f 3]
        else                                ['/say' , message: f 0]
      $.post path, JSON.stringify $.extend {id}, data
      false   # no default
                                                                # }}}1

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
