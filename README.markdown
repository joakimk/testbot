Speedup RSpec and Cucumber by running in parallel on multiple CPUs on muliple computers.

Concept
====
This is designed to be a simple way to use all the idle computers resources on your local network to
speedup test runtimes. One of the goals is to only require that you to have one central server which
all other computers can access.

As the runners pull down and run code that can be posted by anyone with access to the central server you
will have to have trust everyone using it.

How it works
====
1. You run something like "rake parallel:testbot_spec".
2. Your project files is synced to a server.
3. Your local client requests testing jobs based on your tests.
4. Runners on different computers syncs your project files from the server, runs the testing jobs and returns the results.
5. The results is returned by the server and displayed.

You can add and remove runners whenever you want. The runners will only run tests on computers that is idle.

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

Install required gems and parallel_specs:

    gem install httparty parallel
    cd vendor/plugins && git clone git://github.com/joakimk/parallel_specs.git && cd parallel_specs && git checkout remotes/origin/testbot -b testbot && rm -rf .git && cd ../../..
    cp vendor/plugins/parallel_specs/docs/testbot.yml.example config/testbot.yml
    cp vendor/plugins/parallel_specs/docs/testbot.rake.example lib/tasks/testbot.rake

Customize **lib/tasks/testbot.rake** and **config/testbot.yml**. You will probably want to keep **config/testbot.yml**
outside of version control for now (as every user must specify their own server_path).

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

    gem install httparty daemons macaddr
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

To run the rspec specs:

    rake parallel:testbot_spec

To run the cucumber features:

    rake parallel:testbot_features

Running testbot's tests
====

    gem install rack-test shoulda flexmock
    rake

Realtime runner information
====

You can access **/runners/outdated** on the server too see which of the runners needs to be updated.
Out of date runners are not given any test jobs.

You can access **/runners/available_instances** to see how many instances are available. Only runners
that are up to date and actively asking for test jobs are included.

You can access **/runners/available** to see how many runners are available. Only runners
that are up to date and actively asking for test jobs are included.

You can access **/runners/total_instances** to see how many instances have been available within the last hour.

Gotchas
====

* When you run your tests in smaller sets you can become unaware of dependency errors in your suite.

Tips
====

I've seen about 20% faster test runtimes when using Ruby Enterprise Edition. You can find it at:
[http://www.rubyenterpriseedition.com/](http://www.rubyenterpriseedition.com/).

Add "server_type: git" to testbot.yml and change "server_path" to your git repo to
greatly improve startup speed. This is probably not practical if you want to run
uncommited code, but great for CI servers.

I'm using a ubuntu based PXE (network-boot) server to run some of our testbots without having
to install anything on the computers. Adding a new computer is as simple as setting it to
boot from network. You can find the base PXE server setup at: [http://gist.github.com/622495](http://gist.github.com/622495).

TODO
====
 - Make it simpler to use
 - Add support for Test:Unit / Shoulda
 - Add support for jRuby
 - Optimizations
 - Lots more
