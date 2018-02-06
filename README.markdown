## Not maintained 

This is not maintained by me anymore. If you want to take over as maintainer for the project, please let me know.

Testbot has helped me ship well tested software for 7+ years, but it hasn't been well maintained for quite a while and I don't use it myself anymore.

I recommend looking at a CI service like [CircleCI](https://circleci.com/) for parallel tests and [Knapsack Pro](https://knapsackpro.com/) for test balancing. I've seen the same performance of 10 CircleCI containers with Knapsack Pro balancing compared to 16 CPU cores with testbot. It's a bit more expensive to run, but it's easier to maintain.

## Old readme

Testbot is a test distribution tool that works with Rails, RSpec, RSpec2, Test::Unit and Cucumber. The basic idea is that you let testbot spread the load of running your tests across multiple machines to make the tests run faster.

Using testbot on 11 machines (25 cores) we got our test suite down to **2 minutes from 30**. [More examples of how testbot is used](http://github.com/joakimk/testbot/wiki/How-testbot-is-used).

If you intend to use testbot with cloud computing (like EC2), take a look at [TestbotCloud](https://github.com/joakimk/testbot_cloud).

Installing
----

    gem install testbot

Try it out
----

    testbot --server
    testbot --runner --connect localhost
    sleep 5 # wait for the runner to register with the server

    mkdir -p testbotdemo/test; cd testbotdemo
    echo 'require "test/unit"' > test/demo_test.rb
    echo 'class DemoTest < Test::Unit::TestCase; def test_first; end; end' >> test/demo_test.rb

    testbot --test --connect localhost
        
    # Cleanup
    testbot --server stop
    testbot --runner stop
    cd ..; rm -rf testbotdemo
    rm -rf /tmp/testbot

The project files from the demo project are synced to /tmp/testbot/$USER (default). The runner syncs the files to /tmp/testbot/project (default). The tests are then run and the results returned through the server and displayed.

How it works
----

Testbot is:

* A **server** to distribute test jobs.
* One or more **runners** to run test jobs and return the results (this is the "worker" process).
* One or more **requesters** that tells the server which tests to distribute and displays the results (the client you use to run tests, for example: **rake testbot:spec**).

<pre>
    Requester -- (files to run) --> Server -- (files to run) --> (many-)Runner(s)
        ^                           |    ^                                  |
        |---------------------------|    |----------------------------------|
                 (results)                            (results)
</pre>

Example setup
----

Here I make the assumption that you have a user called **testbot** on a server at **192.168.0.100** that every computer [can log into without a password](http://github.com/joakimk/testbot/wiki/SSH-Public-Key-Authentication) and that you have **installed testbot** on each computer.

    ssh testbot@192.168.0.100
    testbot --server
    
On every computer that should share CPU resources run:

    testbot --runner --connect 192.168.0.100

Running tests:
    
    testbot --test --connect 192.168.0.100
    # --test could also be --spec (RSpec), --rspec (RSpec 2) or --features

Using testbot with Rails 2:

    # Add testbot to your Gemfile if you use bundler. You also need the plugin because
    # Rails 2 does not load raketasks from gems.
    ruby script/plugin install git://github.com/joakimk/testbot.git -r 'refs/tags/v0.7.8'
    script/generate testbot --connect 192.168.0.100

    rake testbot:spec (or :rspec, :test, :features)

Using testbot with Rails 3:

    rails g testbot --connect 192.168.0.100
    rake testbot:spec (or :rspec, :test, :features)

    # Gemfile:
    gem 'testbot'

You can keep track of the testbots on:

    http://192.168.0.100:2288/status

Updating testbot
----

To simplify updates there is a **--auto_update** option for the runner. The runner processes that use this option will be automatically updated and restarted when you change the server version.

This requires testbot to be installed **without sudo** as the update simply runs "gem install testbot -v new_version". I recommend using [RVM](http://rvm.beginrescueend.com/) (it handles paths correctly).

Example:
    testbot --runner --connect 192.168.0.100 --auto_update

More options
----

    testbot (or testbot --help)

Could this readme be better somehow?
----

If there is anything missing or unclear you can create an [issue](http://github.com/joakimk/testbot/issues) (or send me a pull request).

Features
----
* You can add and remove computers at any time. Testbot simply gives abandoned jobs to other computers.
* Testbot will try to balance the testload so that every computer finishes running the tests at the same time to reduce the time it takes to run the entire test suite. It does a good job, but has potential for further improvement.
* You can access your testbot network through SSH by using the built in SSH tunneling code.
* You can use the same testbot network with multiple projects.
* You can abort a test run with ctrl+c and all remote processes will be stopped.
* It shows you the output as it happens.

Contributing to testbot
----

First, get the tests to run:

    bundle
    rake

For development I recommend using guard.

    # OSX needs: gem install rb-fsevent
    guard

Make your change (don't forget to write tests) and send me a pull request.

You can also contribute by adding to the [wiki](http://github.com/joakimk/testbot/wiki).

How to add support for more test frameworks and/or programming languages
----

Add a **lib/shared/adapters/framework_name_adapter.rb** file and update this readme.

More
----

* Check the [wiki](http://github.com/joakimk/testbot/wiki) for more info.
