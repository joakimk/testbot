Speedup RSpec by running in parallel on multiple CPUs on muliple computers.

NOTE! This is not in any way complete. It needs alot of polish before being
truly useful.

This borrows alot of ideas from parallel_specs and will probably be part of it
in one way or another. I'm currently looking into adding a testbot requester
to parallel_specs at: [http://github.com/joakimk/parallel_specs/tree/testbot](http://github.com/joakimk/parallel_specs/tree/testbot).

Setup
====
    
    sudo gem install sequel sinatra sqlite3-ruby daemons # For running the server
    sudo gem install httparty daemons macaddr            # For running the runner or requester

Files
====

    bin/testbot_server  <- The server that keeps track of testing jobs and results.
    bin/testbot_runner  <- The runner that you have on each computer that actually runs the testing jobs.
    lib/requester.rb    <- A sample implementation of a testing job-requester.

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

Copy testbot to the server and run **bin/testbot_server start**.

### 2: Setup a runner

* Add a **testbot.rake** task to your project and customize it so that the runner
  can call it to prepare the environment before running a test.
* Copy testbot to a computer.
* Edit **lib/runner.rb**, configure the server address and the number of parallel jobs to allow.
* Make sure the user can ssh into the server without a password.
* Run **bin/testbot_runner start**

### 3: Setup the requester

You can use the sample requester but I'd recommend you use my testbot branch of
parallel_specs. Both need a config file, for now, look at
**test/fixtures/local/config/testbot.yml**.

Running the tests
====

    sudo gem install rack-test
    rake
    
Realtime runner information
====
    
You can access **/runners/outdated** on the server too see which of the runners needs to be updated.
Out of date runners are not given any test jobs.

You can access **/runners/available_instances** to see how many instances are available. Only runners
that are up to date and actively asking for test jobs are included. The parallel_specs testbot
requester will be using this.

TODO
====
 - Add support for multiple users
 - Make it simpler to use
   - Example config and testbot.rake.
   - Gems? sudo gem install testbot; vim ~/.testbot.conf; testbot_runner start...
 - Add support for Test:Unit and Cucumber
 - Lots more
