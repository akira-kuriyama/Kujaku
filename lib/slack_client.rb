require 'net/http'
require 'json'

class SlackClient
  SLACK_API_ENDPOINT = 'https://slack.com/api/chat.unfurl'.freeze
  SLACK_AUTH_TOKEN = ENV['SLACK_OAUTH_ACCESS_TOKEN']

  class << self
    def post(json)
      res = http_client.request(http_request(json))
      puts "[LOG] json: #{json}, slack response: #{res.body}"
    end

    private

    def uri
      URI.parse(SLACK_API_ENDPOINT)
    end

    def http_request(body)
      Net::HTTP::Post.new(uri.request_uri).tap do |req|
        req['Content-Type'] = 'application/json;  charset=utf-8'
        req['Authorization'] = "Bearer #{SLACK_AUTH_TOKEN}"
        req.body = body
      end
    end

    def http_client
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = true
      end
    end
  end
end
