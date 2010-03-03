# openMSX-Builder
******************************************************************************
openMSX-Builder is used for building the latest SVN checkouts of [openMSX][1] and [openMSX-Debugger][2] from [their sourceforge repository][3].  
It also supports publishing the created builds to an external location via [scp][4]. The original setup publishes to [FiXato's openMSX page][5].  
Successfully published builds can also be announced via Twitter. [@openmsx_builder][6] is the official Twitter home for openMSX-Builder.  

Setup of the oauth info has to be done manually at the moment, for more information on that read, about the amazing [twitter_oauth gem][7], [Twitter's oAuth Applications][8] and [Twitter's Authentication Wiki][9]

## Commandline Arguments
******************************************************************************
Currently `./build_openmsx` supports the following commandline arguments:

* --debug                 => Generate debug output.
* --publish               => Publish the created build
* --publish-current       => Only publish the current build and exit
* --publish-all           => Only publish all previously created builds and exit
* --tweet                 => Send a tweet via @openMSX_Builder after successfully having published a build
* --dont-update           => Don't update the SVN repository
* --report-build-failure  => If an error occurs during build, report failure via e-mail

## ToDo
******************************************************************************
Current list of tasks is:

+ Make a gem out of this tool
+ Publish gem to Gemcutter
+ Integrate with CIA.vc / Ruby-Rbot
+ Add tests
+ Refactor `#archive_for_revision` and `#dmg_for_revision` into a single method
+ Create a simple Sinatra App for [openMSX.FiXato.net][5]
+ Allow for automatic setup of the oAuth tokens.

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