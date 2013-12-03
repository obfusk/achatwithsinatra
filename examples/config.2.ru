run -> env {
  req = Rack::Request.new env
  Rack::Response.new.finish do |res|
    res['Content-Type'] = 'text/plain'
    res.status = 200
    res.write "Parameters sent: #{req.params.inspect}\n"
  end
}
