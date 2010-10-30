**IMPORTANT**: This is work in progress. This documentation describes how I imagine it will work when this branch is complete. The stable version can be found at: [http://github.com/joakimk/testbot](http://github.com/joakimk/testbot)


Testbot is a test distribution tool that works with Rails, RSpec, Test::Unit and Cucumber. The basic idea is that you let testbot spread the load of running your tests across multiple machines to make the tests run faster.

Using testbot on 11 machines (25 cores) we got our test suite down to **2 minutes from 30**. You can check the [wiki](http://github.com/joakimk/testbot/wiki) for [examples of how testbot is used](http://github.com/joakimk/testbot/wiki/How-testbot-is-being-used).

How it works
----

Testbot is:

* A **server** to distribute test jobs.
* One or more **runners** to run test jobs and return the results (this is the "slave" process that runs tests).
* One or more **requesters** that tells the server which tests to distribute and displays the results (the client you use to run tests, for example: **rake testbot:spec**).

<pre>
    Requester -- (files to run) --> Server -- (files to run) --> (many-)Runner(s)
        ^                           |    ^                                  |
        |---------------------------|    |----------------------------------|
                 (results)                            (results)
</pre>

Benefits
----

One of the main benefits of testbot compared to other test distribution tools is that it **only requires you to be able to access one central server**. Because of this new users are easy to add and you can use testbot from anywhere using SSH tunneling (built in support).

Installing
----

    gem install testbot

Try it out (just copy and paste)
----

    testbot --server
    testbot --runner --connect localhost
    rails new testbotdemo; cd testbotdemo; script/rails generate scaffold post title:string; rake db:migrate db:test:prepare
    testbot --test --connect localhost
    
    # Cleanup
    testbot --server stop
    testbot --runner stop
    cd ..; rm -rf testbotdemo
    rm -rf /tmp/testbot

That's it. The project files from the demo project are synced to /tmp/testbot/$USER (default). The runner syncs the files to /tmp/testbot/project_rsync (default). The tests are then run and the results returned through the server and displayed.

Example setup
----

Here I make the assumption that you have a user called **testbot** on a server at **192.168.0.100** that every computer can log into without a password and that you have installed testbot on each computer.

    ssh testbot@192.168.0.100
    testbot --server
    
On every computer that should share CPU resources run:

    testbot --runner --connect 192.168.0.100

Testing the network:

    # Within your project run:
    testbot --test --connect 192.168.0.100
    
    # --test could also be --spec or --features

Using the rails plugin:

    # This adds config files and a rake task you can use to prepare the test environment on the runners
    # (like setting up a database).
    rake testbot:setup
    
    rake testbot:spec (or :test, :features)

Updating testbot
----

To simplify updates of a distributed system like testbot there is a **--auto_update** option for the runner. The runner
processes that use this option will be automatically updated and restarted when you change the server version.

Example:
    testbot --runner --connect 192.168.0.100 --auto_update

More options
----

    testbot (or testbot --help)

Could this readme be better somehow?
----

If there is anything missing or unclear about how to use testbot you can create an [issue](http://github.com/joakimk/testbot/issues) (or fix it yourself and send me a pull request).

Features
----
* You can add and remove computers at any time. Testbot simply gives abandoned jobs to other computers.
* Testbot will try to balance the testload so that every computer finishes running the tests at the same time to reduce the time it takes to run the entire test suite. It does a good job, but has potential for further improvement.
* You can access your testbot network through SSH by using the built in SSH tunneling code.

Contributing to testbot
----

First, get the tests to run:
    gem install rack-test shoulda flexmock
    rake

For development I recommend: [grosser/autotest](http://github.com/grosser/autotest)
    autotest -f -c

Make your change (don't forget to write tests) and send me a pull request.

You can also contribute by adding to the [wiki](http://github.com/joakimk/testbot/wiki).

Adding support for more test frameworks
----

Add a **lib/adapters/framework_name_adapter.rb** file, update **lib/adapters/adapter.rb** and this readme.

Gotchas
----

* When you run your tests in smaller sets you may miss dependency errors in your suite.

* The runner processes does not handle if a single user runs different projects at the same time. Code
  fetching and initialization is then only done for one of the projects.

* As the runners pull down and run code that can be posted by anyone with access to your central server you will have to have trust everyone using it.

Tips
----

* I've seen about 20% faster test runtimes when using Ruby Enterprise Edition. You can find it at:
[http://www.rubyenterpriseedition.com/](http://www.rubyenterpriseedition.com/).

* I'm using a ubuntu based PXE (network-boot) server to run some of our testbots without having
to install anything on the computers. Adding a new computer is as simple as setting it to
boot from network. You can find the base PXE server setup at: [http://gist.github.com/622495](http://gist.github.com/622495).

* Check the [wiki](http://github.com/joakimk/testbot/wiki) for more deployment tips.
