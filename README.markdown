Speedup RSpec by running in parallel on multiple CPUs on muliple computers.

NOTE! This is not in any way complete. It needs alot of polish before being
truly useful.

This borrows alot of ideas from parallel_specs and will probably be part of it
in one way or another. I'm currently looking into adding a testbot requester
to parallel_specs at: [http://github.com/joakimk/parallel_specs/tree/testbot](http://github.com/joakimk/parallel_specs/tree/testbot).

Setup
====
    
    sudo gem install sequel sinatra sqlite3-ruby # For running the server
    sudo gem install httparty                    # For running the runner or requester

Files
====

    server.rb    <- The server that keeps track of testing jobs and results.
    runner.rb    <- The runner that you have on each computer that actually runs the testing jobs.
    requester.rb <- A sample implementation of a testing job-requester.

Usage
====

### 0: Prerequisites:
    If you have multiple cores on the computer you're running the specs on, you
    will probably want to look into how to setup the database and config for it.
    Check the readme for parallel_specs for now:

[http://github.com/joakimk/parallel_specs](http://github.com/joakimk/parallel_specs)

    Also it's a good idea to vendorize all gems/plugins and dependencies in your
    rails project so that you don't have to install and maintain so much stuff
    on each computer that will host a test runner.

### 1: Setup a server.
    Copy server.rb to the server and run it.

### 2: Setup a runner
    - Add a testbot.rake task to your project and customize it so that the runner
      can call it to prepare the environment before running a test.
    - Copy runner.rb to a computer.
    - Edit it and configure the server address and the number of parallel jobs to allow.
    - Make sure the user can ssh into the server without a password.
    - Run it.

### 3: Setup the requester
    You can use the sample requester but I'd recommend you use my testbot branch of
    parallel_specs. Both need a config file, for now, look at
    test/fixtures/local/config/testbot.yml.

Running the tests
====

    sudo gem install rack-test
    rake

TODO
====
 - Add support for multiple users
 - Make it simpler to use
   - Deamons, rake tasks, ...
   - Example config and testbot.rake.
 - Make it simpler to install ("vendorize" gems)
 - Add support for Test:Unit and Cucumber
 - Lots more
