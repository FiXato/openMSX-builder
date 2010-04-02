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
        :nice_name => 'openMSX (universal)',
        :publish_location => 'ssh_host:path/to/existing/publish/dir',
        :site_path => 'http://your.host.example/publish/dir',
        :target_cpu => 'univ',
      },
      :openmsx_x86 => {
        :source_dir => File.expand_path("~/Development/openMSX"),
        :builds_subdir => 'derived/x86-darwin-opt-3rd',
        :report_bcc => [],
        :report_from => "openMSX auto-builder by FiXato <username@mailhost.example>",
        :nice_name => 'openMSX (x86)',
        :publish_location => 'ssh_host:path/to/existing/publish/dir',
        :site_path => 'http://your.host.example/publish/dir',
        :target_cpu => 'x86',
      },
      :openmsx_ppc => {
        :source_dir => File.expand_path("~/Development/openMSX"),
        :builds_subdir => 'derived/ppc-darwin-opt-3rd',
        :report_bcc => [],
        :report_from => "openMSX auto-builder by FiXato <username@mailhost.example>",
        :nice_name => 'openMSX (ppc)',
        :publish_location => 'ssh_host:path/to/existing/publish/dir',
        :site_path => 'http://your.host.example/publish/dir',
        :target_cpu => 'ppc',
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

  attr_accessor :type,:build_outputs
  def initialize(options,type=:openmsx)
    @options = options
    @type = type
    @log = Logger.new(STDOUT)
    @log.level = Logger::FATAL
    @log.level = Logger::ERROR if @options.include?('--log-errors')
    @log.level = Logger::WARN if @options.include?('--warn')
    @log.level = Logger::INFO if @options.include?('--verbose')
    @log.level = Logger::DEBUG if @options.include?('--debug')
    @log.debug("Logger created with level #{@log.level}")
    @current_revision = `svnversion -cn #{setting(:source_dir)}`.split(':').last.to_i
    @fails = 0
    @build_outputs = []
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

  def publish_all
    @log.info "Publishing all #{@type} builds found"
    if openmsx?
      regexp = /openmsx-.+-(\d+)-mac-univ-bin.dmg$/
    elsif openmsx_debugger?
      regexp = /openMSX-debugger-(\d+)-mac-x86.tbz$/
    end
    Dir.glob(filemask_for_revision('*')).sort.each do |file|
      publish_revision($1,file) if file =~ regexp
    end
    nil
  end

  def publish_revision(revision,archive_name=nil)
    if archive_name.nil?
      if openmsx?
        archive_name = Dir.glob(filemask_for_revision(revision)).first
      elsif openmsx_debugger?
        archive_name = filemask_for_revision(revision)
        archive(File.join(setting(:source_dir),setting(:builds_subdir),'openMSX_Debugger.app'),File.basename(archive_name))
      end
    end

    destination = File.join(setting(:publish_location),File.basename(archive_name))
    @log.info "Publishing '#{archive_name}' to '#{destination}'."
    @log.debug `scp -p "#{archive_name}" #{destination}`

    return nil unless @options.include?('--tweet')
    url = File.join(setting(:site_path),File.basename(archive_name))
    message = "[#{setting(:nice_name)}] Revision #{revision} is now available:\r\n #{url}"
    tweetmsx.update(message)
  rescue TweetMsx::NotConfigured => e
    @log.error e.message
  end

  def setting(key)
    config[:projects][type][key]
  end

  def run
    return publish_all if @options.include?('--publish-all')
    return publish_revision(@current_revision) if @options.include?('--publish-current')
    if @options.include?('--dont-update')
      @new_revision = @current_revision
      @log.info "Update skipped. Still at revision #{@new_revision}"
      return
    else
      update_svn
    end

    if @new_revision >= @current_revision
      @log.info "Revision #{@new_revision} is not older than #{@current_revision}. Proceeding with build."
      build unless already_built?(@new_revision)
    end
  end

  def update_svn
    @log.info "openMSX is currently at #{@current_revision}. Proceeding with `svn update`"
    @log.debug `cd #{setting(:source_dir)} && svn up`
    @new_revision = `svnversion -nc #{setting(:source_dir)}`.split(':').last.to_i
    @log.info "Now at revision #{@new_revision}"
    nil
  end

private
  def already_built?(revision)
    if openmsx?
      files = Dir.glob(filemask_for_revision(revision))
      if files.size == 0
        @log.debug "Revision #{revision} has not yet been built."
        return false
      end
      @log.debug "The following file(s) were found for revision #{revision}: #{files.join(",")}"
      filename = files.first
    elsif openmsx_debugger?
      filename = filemask_for_revision(revision)
      return false unless File.exist?(filename)
    else
      @log.fatal "Unsupported config type #{@type}."
      exit
    end
    @log.info "Revision #{revision} already built as: #{filename}"
    filename
  end

  def archive(infile,outfile)
    `cd #{File.dirname(infile)} && tar --bzip2 -cf #{outfile} #{File.basename(infile)}`
  end

  def build
    cleanup_dmg_locks if openmsx?
    @log.info("Will attempt to build revision #{@new_revision}.")
    build_args=""
    if openmsx? 
      build_args+=" staticbindist"
      build_args+=" OPENMSX_TARGET_CPU=#{setting(:target_cpu)}" if setting(:target_cpu)
    elsif openmsx_debugger?
      build_args+=" CHANGELOG_REVISION=#{@new_revision}"
    end
    @build_outputs << `cd #{setting(:source_dir)} && make clean && make#{"#{build_args}"} 2>&1`
    if $?.success?
      handle_build_success
      return nil
    end
    handle_build_error
    nil
  end

  def build_output
    build_outputs.last
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

  def filemask_for_revision(revision)
    if openmsx?
      File.join(setting(:source_dir),setting(:builds_subdir),"openmsx-*-#{revision}-mac-univ-bin.dmg")
    elsif openmsx_debugger?
      File.join(setting(:source_dir),setting(:builds_subdir),"openMSX-debugger-#{revision}-mac-x86.tbz")
    end
  end

  def handle_build_error
    if handle_build_hdiutil_error?
      build
      return nil
    end
    @log.error "!!!!!!FAILED!!!!!!"
    build_output.each_line do |line|
      @log.error "     %s" % line
    end
    if @options.include?('--report-build-failure')
      report_build_failure
    end
  end

  #Capture the weird random build error that seems to be more OSX related than openMSX related.
  def handle_build_hdiutil_error?
    return false unless build_output.include?('hdiutil: create failed - error 49168')
    @fails += 1
    @log.error build_output
    @log.error "Weird bug (attempt #{@fails}/3)"
    return true if @fails < 3
    @log.fatal "Encountered the weird 'hdiutil error 49168'-bug #{@fails} times; failing."
    exit
  end

  def handle_build_success
    @log.info "++++++SUCCESS++++++"
    if @log.debug?
      build_output.each_line do |line|
        @log.debug "     %s" % line
      end
    end
    publish_revision(@new_revision) if @options.include?('--publish')
    nil
  end

  def openmsx?
    @type == :openmsx
  end

  def openmsx_debugger?
    @type == :openmsx_debugger
  end

  def report_build_failure
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
      body <<-EOS
        While trying to build revision #{revision} of #{project_name}, the daily auto-builder encountered an error.
        Below you will find the entire build report:\r\n
        #{build_output}
      EOS
    end
  end

  def tweetmsx
    @tweetmsx ||= TweetMsx.new(@log.level)
  end
end