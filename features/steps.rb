When(/^I reset the server$/) do
  post 'reset'
end

When(/^I request `\/(.*)`$/) do |path|
  @response = get path
end

Then(/^The JSON response should be:$/) do |json|
  expect(JSON.parse(@response.body)).to eq(JSON.parse(json))
end

When(/^I listen to `\/(.*)` as `(.*)`$/) do |path, id|
  listen path, id
end

When(/^I wait for listener `(.*)`$/) do |id|
  (@messages ||= {})[id] = waitfor id
end

When(/^I post JSON to `\/(.*)`:$/) do |path, json|
  post path, json
end

Then(/^The messages of `(.*)` should be:$/) do |id, s|
  expect(@messages[id]).to eq(s)
end
