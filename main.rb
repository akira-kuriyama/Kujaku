require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'

require_relative 'lib/esa_client'
require_relative 'lib/slack_client'

get '/' do
  return {hello: 'Kujaku!'}.to_json
end

post '/' do
  puts '[START]'
  params = JSON.parse(request.body.read)
  dry_run = params['dry-run']

  case params['type']
  when 'url_verification'
    challenge = params['challenge']
    return { challenge: challenge }.to_json

  when 'event_callback'
    channel = params.dig('event', 'channel')

    ts = params.dig('event', 'message_ts')
    links = params.dig('event', 'links')

    unfurls = links.each_with_object({}) do |link, memo|
      url = link['url']
      attachment = EsaClient.fetch(url)
      memo[url] = attachment
    end

    payload = {
        channel: channel,
        ts: ts,
        unfurls: unfurls
    }.to_json

    if dry_run == 'true'
      p "params: #{params}"
      p "payload: #{payload}"
    else
      SlackClient.post(payload)
    end

  else
    p "[LOG] other type. params: #{params}"
  end

  return {}.to_json
end
