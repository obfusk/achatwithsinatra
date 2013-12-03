[]: {{{1

    File        : README.md
    Maintainer  : Felix C. Stegerman <flx@obfusk.net>
    Date        : 2013-12-03

    Copyright   : Copyright (C) 2013  Felix C. Stegerman
    Version     : v0.0.1

[]: }}}1

## Description
[]: {{{1

  achatwithsinatra - a simple sinatra chat app

  achatwithsinatra is a simple chat app built w/ sinatra, haml, and
  coffeescript; it uses server-sent events to communicate events from
  the server to the client.

  Building this app is the demonstration part of my
  [sinatra presentation] (http://obfusk.github.io/achatwithsinatra).

  It's also running on
  [heroku] (http://achatwithsinatra.herokuapp.com).

[]: }}}1

## Specs & Docs

    $ rake cuke
    $ rake spec     # TODO
    $ rake jasmine  # TODO

## TODO

  * features, specs, docs, build
  * ...

## License

  * remy's EventSource polyfill [1]: MIT [2];
  * everything else: GPLv2 [3].

## References
[]: {{{1

  [1] remy's EventSource polyfill
  --- https://github.com/remy/polyfills/blob/master/EventSource.js

  [2] remy's EventSource polyfill license
  --- https://github.com/remy/polyfills/blob/master/MIT-LICENCE.txt

  [3] GNU General Public License, version 2
  --- http://www.opensource.org/licenses/GPL-2.0

[]: }}}1

[]: ! ( vim: set tw=70 sw=2 sts=2 et fdm=marker : )
