Speedup RSpec by running in parallel on multiple CPUs on muliple computers.

**NOTE: This is very much a work in progress.**

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

Benchmarks
====
[http://gist.github.com/287124](http://gist.github.com/287124)

Usage
====

### 0: Prerequisites:

It's a good idea to vendorize all gems/plugins and dependencies in your
rails project so that you don't have to install and maintain so much stuff
on each computer that will host a test runner.

Even better would be if you could use an in-memory database (like SQLite3) for testing.

### 1: Prepare your project

* Add a **testbot.rake** task to your project and customize it so that the runner
  can call it to prepare the environment before running a test.

    cp testbot.rake.example ~/PROJECT_PATH/lib/tasks/testbot.yml

### 2: Setup a server.

Install required gems and download testbot:

    gem install sequel sinatra sqlite3-ruby daemons
    mkdir testbot && curl -L http://github.com/joakimk/testbot/tarball/release | tar xz --strip 1 -C testbot
    cd testbot
    cp testbot_server.yml.example ~/testbot_server.yml

* Customize **~/.testbot_server.yml**.
* Run **bin/server run** and make sure it does not immediately crash. Then press ctrl+c.
* Run **bin/server start**.

### 3: Setup a runner

Install required gems and download testbot:

    gem install httparty daemons macaddr
    mkdir testbot && curl -L http://github.com/joakimk/testbot/tarball/release | tar xz --strip 1 -C testbot
    cd testbot
    cp testbot_runner.yml.example ~/testbot_runner.yml

* Customize **~/.testbot_runner.yml**.
* Make sure the user can ssh into the server without a password.
* Run **bin/runner run** and make sure it does not immediately crash. Then press ctrl+c.
* Run **bin/runner start** to start the runner as a daemon.

### 3: Setup the requester

You can use the sample requester (lib/requester.rb) but I'd recommend you use my testbot branch of
parallel_specs.

    cp testbot.yml.example ~/PROJECT_PATH/config/testbot.yml

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

Gotchas
====

* When you run your specs in smaller sets you can become unaware of dependency errors in your suite. I'd
recommend that you use testbot for development but have a CI server that runs the entire suite with "rake spec"
on each commit.

Tips
====

I've seen about 20% faster spec runtimes when using Ruby Enterprise Edition. You can find it at:
[http://www.rubyenterpriseedition.com/](http://www.rubyenterpriseedition.com/).

TODO
====
 - Make it simpler to use
 - Add support for Test:Unit and Cucumber
 - Lots more
