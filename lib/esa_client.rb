require 'esa'
require 'redis'
require 'json'
require 'time'

class EsaClient
  ESA_ACCESS_TOKEN = ENV['ESA_ACCESS_TOKEN']
  ESA_TEAM_NAME = ENV['ESA_TEAM_NAME']
  REDIS_URL = ENV['REDISTOGO_URL']

  class << self
    def fetch(url)
      post = fetch_esa_post(url)
      return {} if post.nil?

      format_response(post)
    end

    private

    def esa_client
      Esa::Client.new(
          access_token: ESA_ACCESS_TOKEN,
          current_team: ESA_TEAM_NAME
      )
    end

    def fetch_esa_post(url)
      post_num = post_num(url)
      if (cache = get_cache(post_num))
        p '[LOG] cache hit'
        return cache
      end

      post = esa_client.post(post_num).body
      return if post.nil?
      p "[LOG] post: #{post}"
      set_cache(post_num, post)
      post
    end

    def post_num(url)
      return unless (match_data = %r(\Ahttps://.+?\.esa\.io/posts/(?<post_num>\d+).*\z).match(url))
      match_data[:post_num]
    end

    def format_response(post)
      title = post['full_name']
      title.insert(0, '[WIP] ') if post['wip']
      footer = generate_footer(post)

      # 素のままだと省略されても長いので10行までにする
      text = post['body_md'].lines[0, 10].map {|item| item.chomp}.join("\n")

      {
          title: title,
          title_link: post['url'],
          author_name: post['created_by']['screen_name'],
          author_icon: post['created_by']['icon'],
          text: text,
          color: '#3E8E89',
          footer: footer
      }
    end

    def generate_footer(post)
      updated_user_name = post.dig('updated_by', 'screen_name') || 'unknown'
      created_at = Time.parse(post['updated_at'])
      created_at_str = created_at.strftime("%Y-%m-%d %H:%M:%S")

      "Updated by #{updated_user_name} \@#{created_at_str}"
    end

    def redis
      return unless redis_available?
      @redis ||= Redis.new(:url => REDIS_URL)
    end

    def get_cache(key)
      return unless redis_available?
      cache_json = redis.get(key)
      return if cache_json.nil?
      JSON.parse(cache_json)
    end

    def set_cache(key, info)
      return unless redis_available?
      redis.multi do
        redis.set(key, info.to_json)
        redis.expire(key, 60 * 60) # 1 hour
      end
    end

    def redis_available?
      !REDIS_URL.nil?
    end
  end
end
