#!/usr/bin/env ruby
# Automatic builder for openMSX and openMSX-Debugger builds for Mac OSX.
# Options:
# --debug                 => Generate debug output.
# --publish               => Publish the created build
# --publish-current       => Only publish the current build and exit
# --publish-all           => Only publish all previously created builds and exit
# --tweet                 => Send a tweet via @openMSX_Builder after successfully having published a build
# --dont-update           => Don't update the SVN repository
# --report-build-failure  => If an error occurs during build, report failure via e-mail
require 'rubygems'
require 'mail'
require 'yaml'
require 'twitter_oauth'
load './lib/debug_tools.rb'
require './lib/tweet_msx'
require './lib/openmsx_builder'
include DebugTools

debug('-'*50)
debug("Starting with openMSX")
OpenmsxBuilder.new(ARGV,:openmsx).run
debug('-'*50)
debug("Proceeding with openMSX-Debugger")
OpenmsxBuilder.new(ARGV,:openmsx_debugger).run
