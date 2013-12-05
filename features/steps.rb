When(/^I reset the server$/) do
  post '/reset'
end

When(%r{^I request `(/.*)`$}) do |path|
  @response = get path
end

Then(/^The JSON response should be:$/) do |json|
  expect(JSON.parse(@response)).to eq(JSON.parse(json))
end

When(%r{^I listen to `(/.*)` as `(\w+)`$}) do |path, id|
  listen_w_redir path, id
end

When(/^I wait for listener `(\w+)`$/) do |id|
  waitfor_listener id
end

When(%r{^I post JSON to `(/.*)`:$}) do |path, json|
  post path, json
end

Then(/^The events of `(\w+)` should be:$/) do |id, str|
  expect(events(@events[id])).to eq(events(str))
end

When(/^I go to the chat UI$/) do
  ui_chat
end

When(/^I set my nick to `(.*)`/) do |nick|
  ui_set_nick nick
end

When(/^I join `(.*)`$/) do |channel|
  ui_join channel
end

When(/^User `(.*)` \((\d+)\) joins `(.*)` and says `(.*)`$/) \
do |nick, n, ch, msg|
  api_listen_nick_join_say nick, n, ch, msg
end

When(/^I say `(.*)`$/) do |msg|
  ui_say msg
end

When(/^User `(.*)` stops listening$/) do |nick|
  waitfor_listener nick
end

Then(/^I should see UI messages:$/) do |msgs|
  ui_messages_are msgs
end

Then(/^User `(.*)` should see API messages:$/) do |nick, msgs|
  api_messages_are nick, msgs
end
