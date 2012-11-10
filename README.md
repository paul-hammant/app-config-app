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

First launch the Perforce Daemon:

```
$ ./perforce_daemon.sh
```

Check that it is running perhaps:
```
ps aux | grep p4d
```

You need to setup some users in perforce. Say your name is 'foo', from the command line:

```
$ ruby setup_example.rb
$ p4port: localhost:1666
$ username: foo
$ email: foo@example.com
$ password: YOUR_PASSWORD
```

This command will create your user in perforce and add **_configuration.json files in dev, stage, and prod branches. The following test users are also created:

| Username      | Password | Write | Read       |
|---------------|----------|-------|------------|
| sally-runtime | bananas  | prod  | stage, dev |
| jimmy-qa      | apples   | stage | dev        |
| joe-developer | oranges  | dev   |            |

Your user will have read/write permissions on all branches. The script useradd.rb will add and modify users, but will give them read/write on _all_ branches. For more details on managing permissions, read [Perforce' documentation][].  Particularly the 'p4 protect' command.

[Perforce' documentation]: http://www.perforce.com/perforce/doc.current/manuals/p4sag/04_protect.html

Running it
----------

Run the Sinatra web server:

```
$ rackup
```

Then crank up your browser, and go to [http://localhost:9292](http://localhost:9292)
