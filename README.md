Installation
------------

Install 'p4d' (the Perforce server daemon) if you don't already have it.  Go [here](http://www.perforce.com/downloads/complete_list) and choose the one for your platform. For Mac, choose darwin 64 or 32 as applicable (slightly counter intuitive).  Put the resulting executable in your path and make it executable.

Install 'p4' (the Perforce command line client) if you don't already have it.  Go [here](http://www.perforce.com/downloads/complete_list) and choose the one for your platform. For Mac, choose darwin 64 or 32 as applicable (slightly counter intuitive).  Put the resulting executable in your path and make it executable.

Install Ruby Gems if you have not already.

The app requires at least Ruby 1.9.3 to run. 

```
$ bundle install
$ rvm install 1.9.3 # if needed
$ rvm 1.9.3
```

First Time
----------

You need to setup some users in perforce. Say you're name is 'foo', from the command line:

```
$ p4 -p localhost:1666 user -f foo
$ # (make sure you add a password line, save and exit)
```

You'll also need to create a client

```
$ p4 -p localhost:1666 -u foo -P YOUR_PASSWORD client fooClient
$ # add the path to the repo with /wc/foo on the end. Save and exit.
```

(both of these will happen through an admin interface eventually)

Running it
----------

First launch the Perforce Daemon:

```
$ ./perforce_daemon.sh
```

Then run the Sinatra web server:

```
$ rackup
```

Then crank up your browser, and go to [http://localhost:9292](http://localhost:9292)
