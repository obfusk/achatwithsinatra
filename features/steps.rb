When(/^I reset the server$/) do
  post 'reset'
end

When(/^I request `\/(.*)`$/) do |path|
  @response = get path
end

When(/^I request `\/(.*)` asynchronously$/) do |path|
  @response = aget path
end

Then(/^The JSON response should be:$/) do |json|
  expect(JSON.parse(@response.body)).to eq(JSON.parse(json))
end
