Speedup RSpec by running in parallel on multiple CPUs on muliple computers.

**NOTE! This is not in any way complete. It needs alot of polish before being
truly useful.**

This borrows alot of ideas from parallel_specs and will probably be part of it
in one way or another. I'm currently looking into adding a testbot requester
to parallel_specs at: [http://github.com/joakimk/parallel_specs/tree/testbot](http://github.com/joakimk/parallel_specs/tree/testbot).

Concept
====
This is designed to be a simple way to use all the idle computers resources on your local network to
speedup test runtimes. One of the goals is to only require that you to have one central server which
all other computers can access.

As the runners pull down and run code that can be posted by anyone with access to the central server you
will have to have trust everyone using it.

Usage
====

### 0: Prerequisites:

If you have multiple cores on the computer you're running the specs on, you
will probably want to look into how to setup the database and config for it.
Check the readme for parallel_specs for now: [http://github.com/joakimk/parallel_specs](http://github.com/joakimk/parallel_specs)

Also it's a good idea to vendorize all gems/plugins and dependencies in your
rails project so that you don't have to install and maintain so much stuff
on each computer that will host a test runner.

Even better would be if you could use an in-memory database (like SQLite3) for testing.

### 1: Setup a server.

Install required gems and download testbot:

    gem install sequel sinatra sqlite3-ruby daemons
    mkdir testbot && curl -L http://github.com/joakimk/testbot/tarball/master | tar xz --strip 1 -C testbot

* Copy **testbot_server.yml.example** to **~/.testbot_server.yml**.
* Run **bin/server start**.

### 2: Setup a runner

Install required gems and download testbot:

    gem install httparty daemons macaddr
    mkdir testbot && curl -L http://github.com/joakimk/testbot/tarball/master | tar xz --strip 1 -C testbot

* Add a **testbot.rake** task to your project and customize it so that the runner
  can call it to prepare the environment before running a test.
* Copy **testbot_runner.yml.example** to **~/.testbot_runner.yml** and customize it.
* Make sure the user can ssh into the server without a password.
* Run **bin/runner start**

### 3: Setup the requester

You can use the sample requester (lib/requester.rb) but I'd recommend you use my testbot branch of
parallel_specs. Both need a config file, for now, look at
**test/fixtures/local/config/testbot.yml**.

Running the tests
====

    gem install rack-test shoulda flexmock
    rake
    
Realtime runner information
====
    
You can access **/runners/outdated** on the server too see which of the runners needs to be updated.
Out of date runners are not given any test jobs.

You can access **/runners/available_instances** to see how many instances are available. Only runners
that are up to date and actively asking for test jobs are included. The parallel_specs testbot
requester will be using this.

Tips
====

I've seen about 20% faster spec runtimes when using Ruby Enterprise Edition. You can find it at:
[http://www.rubyenterpriseedition.com/](http://www.rubyenterpriseedition.com/).

TODO
====
 - Add support for multiple users
 - Make it simpler to use
   - Example config and testbot.rake.
   - Gems? sudo gem install testbot; vim ~/.testbot.conf; testbot_runner start...
 - Add support for Test:Unit and Cucumber
 - Lots more
