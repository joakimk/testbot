Testbot is a test distribution tool that works with Rails, RSpec, Test::Unit and Cucumber. The basic idea is that you let testbot spread the load of running your tests across multiple machines to make the tests run faster.

I'm currently working on making testbot a gem and making it simpler to use: [http://github.com/joakimk/testbot/tree/gemify](http://github.com/joakimk/testbot/tree/gemify).

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

Install testbot and required gems:

    gem install httparty macaddr net-ssh
    cd vendor/plugins && mkdir testbot && curl -L http://github.com/joakimk/testbot/tarball/release | tar xz --strip 1 -C testbot && cd ../..
    cp vendor/plugins/testbot/testbot.yml.example config/testbot.yml
    cp vendor/plugins/testbot/testbot.rake.example lib/tasks/testbot.rake

Customize **lib/tasks/testbot.rake** and **config/testbot.yml**. You will probably want to keep **config/testbot.yml** outside of version control for now (as every user must specify their own server_path).

### 2: Setup a server.

Install required gems and download testbot:

    gem install sequel sinatra sqlite3-ruby daemons
    mkdir testbot && curl -L http://github.com/joakimk/testbot/tarball/release | tar xz --strip 1 -C testbot
    cd testbot
    cp testbot_server.yml.example ~/.testbot_server.yml

* Customize **~/.testbot_server.yml**.
* Run **bin/server run** and make sure it does not immediately crash. Then press ctrl+c.
* Run **bin/server start**.

### 3: Setup a runner

Install required gems and download testbot:

    gem install httparty daemons macaddr net-ssh
    mkdir testbot && curl -L http://github.com/joakimk/testbot/tarball/release | tar xz --strip 1 -C testbot
    cd testbot
    cp testbot_runner.yml.example ~/.testbot_runner.yml

* Customize **~/.testbot_runner.yml**.
* Make sure the user can ssh into the server without a password.
* Run **bin/runner run** and make sure it does not immediately crash. Then press ctrl+c.
* Run **bin/runner start** to start the runner as a daemon.

### 4: Running the tests

The first time you run your tests the runners will sync the project so you can expect it to take a bit
more time than usual.

To run the RSpec specs:

    rake testbot:spec

To run the Test::Unit tests:

    rake testbot:test

To run the Cucumber features:

    rake testbot:features

To run with JRuby:

    JRUBY=true rake testbot:spec
    # or
    jruby -S rake testbot:spec

Running testbot's tests
====

    gem install rack-test shoulda flexmock
    rake
    autotest -f -c

I recommend: [grosser/autotest](http://github.com/grosser/autotest)

Realtime runner information
====

You can access **/runners/outdated** on the server too see which of the runners needs to be updated.
Out of date runners are not given any test jobs.

You can access **/runners/available_instances** to see how many instances are available. Only runners
that are up to date are included.

You can access **/runners/total_instances** to see how many instances there are in total. Only runners
that are up to date are included.

You can access **/runners/available** to see how many runners are available. Only runners
that are up to date are included.

Gotchas
====

* When you run your tests in smaller sets you can become unaware of dependency errors in your suite.

* The runner processes does not handle if a single user runs different projects at the same time. Code
  fetching and initialization is then only done for one of the projects.

* As the runners pull down and run code that can be posted by anyone with access to your central server you will have to have trust everyone using it.

Tips
====

I've seen about 20% faster test runtimes when using Ruby Enterprise Edition. You can find it at:
[http://www.rubyenterpriseedition.com/](http://www.rubyenterpriseedition.com/).

I'm using a ubuntu based PXE (network-boot) server to run some of our testbots without having
to install anything on the computers. Adding a new computer is as simple as setting it to
boot from network. You can find the base PXE server setup at: [http://gist.github.com/622495](http://gist.github.com/622495).

Presentations featuring testbot
====

* [SHRUG oct 2010](http://github.com/joakimk/presentations/tree/master/shrug_oct2010_sideprojects)
* [SHRUG jan 2010](http://github.com/joakimk/presentations/tree/master/shrug_jan2010_faster_testruns)
