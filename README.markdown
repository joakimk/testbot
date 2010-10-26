Testbot is a test distribution tool that works with Rails, RSpec, Test::Unit and Cucumber. The basic idea is that you let testbot spread the load of running your tests across multiple machines to make them run faster.

Try it out on you local machine
----

1) Install and start testbot
    gem install testbot
    testbot --server
    testbot --connect http://localhost:2288 --working_dir /tmp/testbot

2) Add testbot as a gem dependency in rails, run setup and follow the instructions.
    rake testbot:setup

Benefits of using testbot
----
* You **reduce** test time!
* You do so by **sharing CPU resources** within your team
* You can also **use spare resources** in local (or remote) servers

What testbot does besides just distributing test load
----
* **Balances** the load so that you get the most use of the hardware you have
* Provides **failover** if a computer suddenly dissapears from the network
* Provides the option of **SSH tunneling** so that you can work from anywhere

Benchmarks
----
[http://gist.github.com/287124](http://gist.github.com/287124)

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

* When you run your tests in smaller sets you can become unaware of dependency errors in your suite.

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
