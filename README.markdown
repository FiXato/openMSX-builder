# openMSX-Builder
******************************************************************************
openMSX-Builder is used for building the latest SVN checkouts of [openMSX][1] and [openMSX-Debugger][2] from [their sourceforge repository][3].  
It also supports publishing the created builds to an external location via [scp][4]. The original setup publishes to [FiXato's openMSX page][5].  
Successfully published builds can also be announced via Twitter. [@openmsx_builder][6] is the official Twitter home for openMSX-Builder.  


## Installation Guidelines
******************************************************************************

### From Git:
`git clone git://github.com/FiXato/openMSX-builder.git && cd openMSX-builder && rake install`

### From RubyForge/GemCutter:
`gem install openMSX-builder`


## Usage
******************************************************************************

The first 2 times you run `build_openmsx` it will probably say you will need to set up the configuration files for the builder and the twitter module.
Setting up the SMTP and builder configuration settings should be pretty straightforward.
Set up of the oauth info has to be done manually at the moment, for more information on that read about the amazing [twitter_oauth gem][7], [Twitter's oAuth Applications][8] and [Twitter's Authentication Wiki][9]


### Commandline Arguments

Currently `build_openmsx` supports the following commandline arguments:

* --debug                 => Generate debug output.
* --publish               => Publish the created build
* --publish-current       => Only publish the current build and exit
* --publish-all           => Only publish all previously created builds and exit
* --tweet                 => Send a tweet via configured authorised Twitter account after successfully having published a build
* --dont-update           => Don't update the SVN repository
* --report-build-failure  => If an error occurs during build, report failure via e-mail

### Examples

Simplest way to run it would usually be:
`build_openmsx --debug --publish --tweet --report-build-failure`

Or by adding a cronjob for:
`0 3 * * * build_openmsx --publish --tweet --report-build-failure`
to have it run daily at 3 at night.
(Remember to add either `source ~/.profile` or the right PATH to your cron.)


## ToDo
******************************************************************************
Current list of tasks is:

+ Integrate with CIA.vc / Ruby-Rbot
+ Add tests
+ Refactor `#archive_for_revision` and `#dmg_for_revision` into a single method
+ Create a simple Sinatra App for [openMSX.FiXato.net][5]
+ Allow for automatic setup of the oAuth tokens.
+ Add documentation on the YAML configuration files.
+ Add --configure argument that will trigger set up of the configuration files.
+ See if VERSION can be integrated into OpenmsxBuilder instead of just being parsed in the executable.

## Notes on Patches/Pull Requests
******************************************************************************

1 Fork the project.
2 Make your feature addition or bug fix.
3 Add tests for it (even though I don't have tests myself at the moment). 
  This is important so I don't break it in a future version unintentionally.
4 Commit, but do not mess with Rakefile, version, history, or README.
  Want to have your own version? Bump version in a separate commit!
  That way I can ignored that commit when I pull.
5 Send me a pull request. Bonus points for topic branches.


## Copyright
******************************************************************************
Copyright (c) 2010 Filip H.F. "FiXato" Slagter. See LICENSE for details.


******************************************************************************
[1]: https://openmsx.svn.sourceforge.net/svnroot/openmsx/openmsx/trunk (openMSX SVN Trunk)
[2]: https://openmsx.svn.sourceforge.net/svnroot/openmsx/openmsx-debugger/trunk (openMSX-Debugger SVN Trunk)
[3]: http://openmsx.sf.net (openMSX at SourceForge.net)
[4]: http://en.wikipedia.org/wiki/Secure_copy (Secure Copy (or SCP) at Wikipedia)
[5]: http://openmsx.fixato.net (openMSX.FiXato.net ~ Home of openMSX-Builder)
[6]: http://twitter.com/openmsx_builder (openMSX-Builder's Twitter account)
[7]: http://github.com/moomerman/twitter_oauth (twitter_oauth gem's Github page)
[8]: http://twitter.com/oauth (create a Twitter oAuth Application)
[9]: http://apiwiki.twitter.com/Authentication (read the Twitter Authentication wiki on oAuth)