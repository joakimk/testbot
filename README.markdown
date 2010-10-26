**IMPORTANT**: This is work in progress. This documentation describes how I imagine it will work when this branch is complete. The stable version can be found at: [http://github.com/joakimk/testbot](http://github.com/joakimk/testbot)


Testbot is a test distribution tool that works with Rails, RSpec, Test::Unit and Cucumber. The basic idea is that you let testbot spread the load of running your tests across multiple machines to make the tests run faster.

Using 11 machines (25 cores) we got our test suite down to **2 minutes from 30**. In this particular case we got about 60% CPU efficiency. [More benchmarks](http://gist.github.com/287124).

How it works
----

Testbot is:

* A **server** to distribute test jobs.
* One or more **runners** to run test jobs and return the results (this is the "slave" process that runs tests).
* One or more **requesters** that tells the server which tests to run and displays the results (the client you use to run tests, for example: **rake testbot:spec**).

<pre>
    Requester -- (files to run) --> Server -- (files to run) --> (many-)Runner(s)
        ^                           |    ^                                  |
        |---------------------------|    |----------------------------------|
                 (results)                            (results)
</pre>

Try it out (just copy and paste)
----

    gem install testbot
    testbot --server
    testbot --runner --connect localhost --working_dir /tmp/testbot/runner
    rails testbotdemo; cd testbotdemo; script/generate scaffold post title:string; rake db:migrate
    testbot --test --connect localhost --sync_path /tmp/testbot/upload

That's it. The project files from the demo project are synced to /tmp/testbot/upload. The runner syncs the files to /tmp/testbot/runner. The tests are then run and the results returned through the server and displayed.

Example setup
----

Here I make the assumption that you have a user called **testbot** on a server at **192.168.0.100** that every computer can log into without a password and that you have installed testbot on each computer.

    ssh testbot@192.168.0.100
    testbot --server
    
On every computer that should share CPU resources run:

    testbot --runner --connect 192.168.0.100 --working_dir /tmp/testbot

Testing the network:

    testbot --test --connect 192.168.0.100 --sync_path /home/testbot/cache/$USER
    # --test could also be --spec or --features

Using the rails plugin:

    rake testbot:setup
    rake testbot:spec (or :test, :features)

Features
----
* You can add and remove computers at any time. Testbot simply gives abandoned jobs to other computers.
* Testbot will try to balance the testload so that every computer finishes running the tests at the same time to reduce the time it takes to run the entire test suite. It does a good job, but it's has potential for further improvement.

Contributing to testbot
----

1) First, get the tests to run:
    gem install rack-test shoulda flexmock
    rake

2) For development I recommend: [grosser/autotest](http://github.com/grosser/autotest)
    autotest -f -c

3) Make your change (don't forget to write tests) and send me a pull request.

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

Presentations featuring testbot
----

* [SHRUG oct 2010](http://github.com/joakimk/presentations/tree/master/shrug_oct2010_sideprojects)
* [SHRUG jan 2010](http://github.com/joakimk/presentations/tree/master/shrug_jan2010_faster_testruns)
