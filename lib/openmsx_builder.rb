require 'rubygems'
require 'mail'
require 'yaml'
require 'tweet_msx'
require 'logger'
class OpenmsxBuilder
  class NotConfigured < RuntimeError;end
  CONFIG_FILENAME = File.expand_path('~/.openMSX-builder.yaml')
  DEFAULTS = {
    :projects => {
      :openmsx => {
        :source_dir => File.expand_path("~/Development/openMSX"),
        :builds_subdir => 'derived/univ-darwin-opt-3rd',
        :report_bcc => [],
        :report_from => "openMSX auto-builder by FiXato <username@mailhost.example>",
        :nice_name => 'openMSX',
        :publish_location => 'ssh_host:path/to/existing/publish/dir',
        :site_path => 'http://your.host.example/publish/dir',
      },
      :openmsx_debugger => {
        :source_dir => File.expand_path("~/Development/openmsx-debugger"),
        :builds_subdir => 'derived',
        :report_bcc => [],
        :report_from => "openMSX auto-builder by FiXato <username@mailhost.example>",
        :nice_name => 'openMSX Debugger',
        :publish_location => 'ssh_host:path/to/existing/publish/dir',
        :site_path => 'http://your.host.example/publish/dir',
      },
    },
    :smtp_settings => {
      :address              => "mail.example",
      :port                 => 25,
      :domain               => 'mail.example',
      :user_name            => 'username@mailhost.example',
      :password             => '',
      :authentication       => :plain,
      :enable_starttls_auto => true
    },
  }

  attr_accessor :type
  def initialize(options,type=:openmsx)
    @type = type
    @current_revision = `svnversion -n #{setting(:source_dir)}`.to_i
    @options = options
    @fails = 0
    @log = Logger.new(STDOUT)
    @log.level = Logger::FATAL
    @log.level = Logger::ERROR if @options.include?('--log-errors')
    @log.level = Logger::WARN if @options.include?('--warn')
    @log.level = Logger::INFO if @options.include?('--verbose')
    @log.level = Logger::DEBUG if @options.include?('--debug')
    @log.debug("Logger created with level #{@log.level}")
    config
  rescue NotConfigured => e
    @log.fatal e.message
    exit
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

  def setting(key)
    config[:projects][type][key]
  end

  def run
    if @options.include?('--publish-all')
      publish_all
      return
    end
    if @options.include?('--publish-current')
      publish_current
      return
    end
    @log.info "openMSX is currently at #{@current_revision}."
    update_svn
    if @new_revision >= @current_revision
      @log.info "Revision #{@new_revision} is not older than #{@current_revision}. Proceeding with build."
      build
    end
  end

private
  def archive(infile,outfile)
    `cd #{File.dirname(infile)} && tar --bzip2 -cf #{outfile} #{File.basename(infile)}`
  end

  def dmg_for_revision?(revision)
    return false unless openmsx?
    files = Dir.glob(File.join(setting(:source_dir),setting(:builds_subdir),"openmsx-*-#{revision}-mac-univ-bin.dmg"))
    @log.debug files.to_yaml unless files.size == 0
    files.size > 0
  end

  def archive_for_revision?(revision)
    return false unless openmsx_debugger?
    filename = File.join(setting(:source_dir),setting(:builds_subdir),"openMSX-debugger-#{revision}-mac-x86.tbz")
    @log.debug filename
    File.exist?(filename)
  end

  def publish_build(revision,infile,outfile='',location=setting(:publish_location))
    @log.debug "\n#publish_build"
    outfile = File.basename(infile) if outfile == ''
    destination = File.join(location,outfile)
    @log.info "Will publish #{infile} to #{setting(:publish_location)} now."
    publish_output = `scp -p "#{infile}" #{destination}`
    @log.debug publish_output unless publish_output.nil? || publish_output.strip == ''
    url = File.join(setting(:site_path),File.basename(destination))
    twitter_update = tweetmsx.update("[#{setting(:nice_name)}] Revision #{revision} is now available:\r\n #{url}") if @options.include?('--tweet')
    @log.info(twitter_update) unless twitter_update.nil?
    nil
  rescue TweetMsx::NotConfigured => e
    @log.error e.message
  end

  def publish
    if openmsx?
      archive_name = Dir.glob(File.join(setting(:source_dir),setting(:builds_subdir),"openmsx-*-#{@new_revision}-mac-univ-bin.dmg")).first
    elsif openmsx_debugger?
      archive_name = File.join(setting(:source_dir),setting(:builds_subdir),"openMSX-debugger-#{@new_revision}-mac-x86.tbz")
      archive(File.join(setting(:source_dir),setting(:builds_subdir),'openMSX_Debugger.app'),File.basename(archive_name))
    end
    publish_build(@new_revision, archive_name)
    nil
  end

  def publish_all
    @log.info "Publishing all #{@type} builds found"
    if openmsx?
      files = Dir.glob(File.join(setting(:source_dir),setting(:builds_subdir),"openmsx-*-mac-univ-bin.dmg")).sort.map do |f|
        if f =~ /openmsx-.+-(\d+)-mac-x86-bin.dmg$/
          rev = $1
        else
          rev = 'unknown'
        end
        [rev,f]
      end
    elsif openmsx_debugger?
      files = Dir.glob(File.join(setting(:source_dir),setting(:builds_subdir),'openMSX-debugger-*-mac-x86.tbz')).sort.map do |f|
        if f =~ /openMSX-debugger-(\d+)-mac-x86.tbz$/
          rev = $1
        else
          rev = 'unknown'
        end
        [rev,f]
      end
    end
    files.each do |rev,file|
      publish_build(rev,file)
    end
    nil
  end
  
  def publish_current
    if openmsx?
      archive_name = Dir.glob(File.join(setting(:source_dir),setting(:builds_subdir),"openmsx-*-#{@current_revision}-mac-univ-bin.dmg")).first
    elsif openmsx_debugger?
      archive_name = File.join(setting(:source_dir),setting(:builds_subdir),"openMSX-debugger-#{@current_revision}-mac-x86.tbz")
      archive(File.join(setting(:source_dir),setting(:builds_subdir),'openMSX_Debugger.app'),File.basename(archive_name))
    end
    publish_build(@current_revision, archive_name)
    nil
  end
  
  def update_svn
    if @options.include?('--dont-update')
      update = 'Update skipped'
    else
      @log.info "Proceeding with update."
      update = `cd #{setting(:source_dir)} && svn up` 
    end
    @new_revision = `svnversion -n #{setting(:source_dir)}`.to_i
    @log.debug update
    @log.info "Now at revision #{@new_revision}"
    nil
  end

  def tweetmsx
    @tweetmsx ||= TweetMsx.new(@log.level)
  end

  def build
    if openmsx?
      if dmg_for_revision?(@new_revision)
        @log.info "Revision already build as #{Dir.glob(File.join(setting(:source_dir),setting(:builds_subdir),"openmsx-*-#{@new_revision}-mac-univ-bin.dmg")).first}"
        return nil
      end
      cleanup_dmg_locks
    elsif openmsx_debugger?
      if archive_for_revision?(@new_revision)
        @log.info "Revision already build as #{File.join(setting(:source_dir),setting(:builds_subdir),"openMSX-debugger-#{@new_revision}-mac-x86.tbz")}"
        return nil
      end
    end
    @log.info("Will attempt to build revision #{@new_revision}.")
    build_output = `cd #{setting(:source_dir)} && make clean OPENMSX_TARGET_CPU=univ && make #{'staticbindist OPENMSX_TARGET_CPU=univ' if openmsx?} 2>&1`
    if $?.success?
      @log.info "++++++SUCCESS++++++"
      build_output.each_line do |line|
        @log.debug "     %s" % line
      end
      publish if @options.include?('--publish')
      nil
    else
      #Capture the weird random build error that seems to be more OSX related than openMSX related.
      if build_output.include?('hdiutil: create failed - error 49168')
        @fails += 1
        @log.error build_output
        @log.error "Weird bug (attempt #{@fails}/3)"
        if @fails == 3
          @log.fatal "Encountered the weird 'hdiutil error 49168'-bug #{@fails} times; failing."
          exit
        else
          return build
        end
      end
      @log.error "!!!!!!FAILED!!!!!!"
      build_output.each_line do |line|
        @log.error "     %s" % line
      end
      if @options.include?('--report-build-failure')
        report_build_failure(build_output)
      end
    end
    nil
  end

  def cleanup_dmg_locks
    @log.info("Checking for existing filelocks on DMGs.")
    locks = `/usr/sbin/lsof | grep #{@new_revision}-mac-univ-bin.dmg`
    @log.debug locks
    locks.each_line do |lock_line|
      pid = lock_line.split[1].to_i
      @log.info "Killing pid #{pid} from lock '#{lock_line}'"
      kill_output = `kill -9 #{pid}`
      @log.debug kill_output
    end
  end

  def report_build_failure(build_output)
    #TODO: Find out why I have to set these local vars due to problems with scope within Mail
    revision = @new_revision
    project_name = setting(:nice_name)
    smtp_settings = config[:smtp_settings]
    mail_from = setting(:report_from)
    mail_bcc = setting(:report_bcc)
    @log.debug Mail.defaults do
      delivery_method :smtp, smtp_settings
    end
    @log.debug Mail.deliver do
      from mail_from
        to mail_from
        bcc mail_bcc.join(', ')
      subject "[FAIL] #{project_name} revision #{revision} failed to build"
      content_type 'text/plain; charset=UTF-8'
      content_transfer_encoding '8bit'
      body "While trying to build revision #{revision} of #{project_name}, the daily auto-builder encountered an error. Below you will find the entire build report:\r\n\r\n" << build_output
    end
  end
  
  def openmsx?
    @type == :openmsx
  end

  def openmsx_debugger?
    @type == :openmsx_debugger
  end
end