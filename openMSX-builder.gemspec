# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{openMSX-builder}
  s.version = "1.4.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Filip H.F. \"FiXato\" Slagter"]
  s.date = %q{2010-03-16}
  s.default_executable = %q{build_openmsx}
  s.description = %q{openMSX-Builder is used for building the latest SVN checkouts of openMSX and openMSX-Debugger from their sourceforge repository.
    It also supports publishing the created builds to an external location via scp, announcing successfully published builds via Twitter and reporting build-errors via e-mail.}
  s.email = %q{fixato@gmail.com}
  s.executables = ["build_openmsx"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown"
  ]
  s.files = [
    ".gitignore",
     "LICENSE",
     "README.markdown",
     "Rakefile",
     "VERSION",
     "bin/build_openmsx",
     "lib/openmsx_builder.rb",
     "lib/tweet_msx.rb",
     "openMSX-builder.gemspec",
     "spec/openMSX-builder_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/FiXato/openMSX-builder}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Builds the latest openMSX and openMSX-Debugger for Mac OSX from SVN and publishes it via scp while tweeting about the new release.}
  s.test_files = [
    "spec/openMSX-builder_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_runtime_dependency(%q<twitter_oauth>, [">= 0.3.3"])
      s.add_runtime_dependency(%q<mail>, [">= 2.1.3"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_dependency(%q<twitter_oauth>, [">= 0.3.3"])
      s.add_dependency(%q<mail>, [">= 2.1.3"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
    s.add_dependency(%q<twitter_oauth>, [">= 0.3.3"])
    s.add_dependency(%q<mail>, [">= 2.1.3"])
  end
end

