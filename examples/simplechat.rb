require 'sinatra'

set :server, :thin
set connections: []

get '/stream' do
  content_type 'text/event-stream'
  stream(:keep_open) do |out|
    settings.connections << out
    out.callback { settings.connections.delete out }
  end
end

post '/say' do
  msg = request.body.read
  settings.connections.each { |out| out << msg << "\n" }
  "message sent\n"
end

# curl localhost:4567/stream
# curl -X POST localhost:4567/say -d 'Hello, Stream!'
