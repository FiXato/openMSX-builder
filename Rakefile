begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "openMSX-builder"
    gemspec.summary = "Builds the latest openMSX and openMSX-Debugger for Mac OSX from SVN and publishes it via scp while tweeting about the new release."
    gemspec.description = "openMSX-Builder is used for building the latest SVN checkouts of openMSX and openMSX-Debugger from their sourceforge repository.
    It also supports publishing the created builds to an external location via scp, announcing successfully published builds via Twitter and reporting build-errors via e-mail."
    gemspec.email = "fixato@gmail.com"
    gemspec.homepage = "http://github.com/FiXato/openMSX-builder"
    gemspec.authors = ['Filip H.F. "FiXato" Slagter']
    gemspec.add_development_dependency "rspec", ">= 1.2.9"
    gemspec.add_dependency "twitter_oauth", ">= 0.3.3"
    gemspec.add_dependency "mail", ">= 2.1.3"
    gemspec.has_rdoc = false
    # gemspec is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 and http://wiki.github.com/technicalpickles/jeweler/customizing-your-projects-gem-specification for additional settings
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec