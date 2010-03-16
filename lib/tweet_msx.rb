require 'logger'
require 'twitter_oauth'
require 'yaml'
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
  def initialize(log_level=Logger::FATAL)
    @log = Logger.new(STDOUT)
    @log.level = log_level
    @client = TwitterOAuth::Client.new(config[:client])
  end

  def config
    create_default_config unless File.exist?(CONFIG_FILENAME)
    @config ||= YAML.load_file(CONFIG_FILENAME)
    @log.debug @config.to_yaml
    if @config == DEFAULTS
      @log.error "TweetMSX config at #{CONFIG_FILENAME} matches DEFAULTS"
      raise NotConfigured.new("You need to set up your config file at #{CONFIG_FILENAME} first")
    end
    @config
  end

  def create_default_config
    system("mkdir -p #{File.dirname(CONFIG_FILENAME)}")
    @log.debug "Creating default config at #{CONFIG_FILENAME}"
    File.open(CONFIG_FILENAME,'w') do |f|
      f.write DEFAULTS.to_yaml
    end
  end

  def update(message)
    @log.info "Tweeting message:\n #{message}"
    @log.debug "[#{message.size} characters]"
    if @client.rate_limit_status == 0
      @log.error "You've exceeded your rate limit"
      return nil
    end
    ret = @client.update(message.to_s)
    @log.info(ret) unless ret.nil?
    nil
  rescue SocketError
    @log.error "Could not send '#{message}'. Twitter or your connection might be down."
    nil
  end
end