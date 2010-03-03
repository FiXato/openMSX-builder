module DebugTools
  def debug(*args)
    if ARGV.include?('--debug')
      args.each do |arg|
        puts "[#{Time.now.strftime("%H:%M:%S")}] #{arg}"
      end
    end
  end
end