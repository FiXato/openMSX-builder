load 'debug_tools.rb'
# Patch for Ruby 1.9.2
module Net
  module HTTPHeader
    alias_method :url_encode_original, :urlencode
    def urlencode(str)
      str = str.to_s if str.kind_of?(Symbol)
      url_encode_original(str)
    end
  end
end
class TweetMsx
  include DebugTools
  class NotConfigured < RuntimeError;end
  CONFIG_FILENAME = File.expand_path('~/.openMSX-builder-TweetMSX.yaml')
  DEFAULTS = {
    :client => {
      :consumer_key => '',
      :consumer_secret => '',
      :token => '',
      :secret => '',
    }
  }
  attr_reader :client, :twitter_down
  def initialize
    @client = TwitterOAuth::Client.new(config[:client])
  end

  def config
    create_default_config unless File.exist?(CONFIG_FILENAME)
    @config ||= YAML.load_file(CONFIG_FILENAME)
    raise NotConfigured.new("You need to set up your config file at #{CONFIG_FILENAME} first") if @config == DEFAULTS
    @config
  end

  def create_default_config
    system("mkdir -p #{File.dirname(CONFIG_FILENAME)}")
    File.open(CONFIG_FILENAME,'w') do |f|
      f.write DEFAULTS.to_yaml
    end
  end

  def update(message)
    debug "#{message} [#{message.size} chars]"
    if @client.rate_limit_status == 0
      debug "You've exceeded your rate limit"
      return nil
    end
    puts message.to_yaml
    @client.update(message.to_s)
    nil
  rescue SocketError
    debug "Could not send '#{message}'. Twitter or your connection might be down."
    nil
  end
end