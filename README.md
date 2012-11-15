# Installation

Install 'p4d' (the Perforce server daemon) if you don't already have it.  Go
[here](http://www.perforce.com/downloads/complete_list) and choose the one for
your platform. For Mac, choose darwin 64 or 32 as applicable (slightly counter
intuitive).  Put the resulting executable in your path and make it executable.

Install 'p4' (the Perforce command line client) if you don't already have it.
Go [here](http://www.perforce.com/downloads/complete_list) and choose the one
for your platform. For Mac, choose darwin 64 or 32 as applicable (slightly
counter intuitive).  Put the resulting executable in your path and make it
executable.

App-Config-App requires at least Ruby 1.9.3 to run. Install Ruby Gems and Bundler if
you have not already.

```
$ bundle install
```

# Running the example

First launch the Perforce Daemon:

```
$ ./perforce_daemon.sh
```

Check that it is running perhaps:
```
ps aux | grep p4d
```

You need to setup some users in perforce. Say your name is 'foo', from the
command line:

```
$ ruby setup_example.rb
$ p4port: localhost:1666
$ username: foo
$ email: foo@example.com
$ password: ********
```

This command will create your user in perforce and add **_configuration.json
files in dev, staging, and prod branches. The following test users are also
created:

| Username      | Password | Write   | Read         |
|---------------|----------|---------|--------------|
| sally-runtime | bananas  | prod    | staging, dev |
| jimmy-qa      | apples   | staging | dev          |
| joe-developer | oranges  | dev     |              |
| prod-app      | s3cret3  |         | prod         |
| qa-app        | s3cret2  |         | staging      |
| dev-app       | s3cret1  |         | dev          |

Your user will have read/write permissions on all branches. The script
useradd.rb will add and modify users, but will require permissions on at least
one branch or the script will fail. For more details on managing permissions,
read [Perforce' documentation][].  Particularly the 'p4 protect' command.

[Perforce' documentation]: http://www.perforce.com/perforce/doc.current/manuals/p4sag/04_protect.html

```
$ rackup
```

Then crank up your browser, and go to [http://localhost:9292](http://localhost:9292).
Fiddle around with the different users to see how App-Config-App handles their
respective permissions in Perforce.

# Productionalizing

**All users created by `setup_example.rb` are intended only as examples.** In
the real world, all application users should be setup with real logins and
real permissions.

The Perforce server that App-Config-App connects to is accessed by default
using localhost:1666. To connect to a different server, set it using the
environment variable P4PORT.

## Secure access to App-Config-App over SSL

Access to App-Config-App can be secured over SSL by setting up any capable
server as a proxy to the application. The connection between the proxy and
App-Config-App will be insecure, however, so they must reside on the same
intranet. Minimal proxy configuration with Apache and Nginx has been tried out:

### SSL with Apache

You will want to add the following configuration to the relevant SSL
&lt;VirtualHost&gt; in Apache:

```
ProxyRequests Off
ProxyPass / http://127.0.0.1:9292/
ProxyPassReverse / http://127.0.0.1:9292/
ProxyPreserveHost on
RequestHeader set X-FORWARDED-PROTO https
```

This proxy configuration is minimal. For additional information, look at
Apache's [mod_proxy][] and [mod_proxy_http][] documentation.

[mod_proxy]: http://httpd.apache.org/docs/2.2/mod/mod_proxy.html
[mod_proxy_http]: http://httpd.apache.org/docs/2.2/mod/mod_proxy_http.html

If Apache can't reach the proxied App-Config-App, it will issue a 503 error for
a fixed amount of time before trying to reach the App-Config-App again. This
timeout can be adjusted with the `retry` parameter, and during development it's
best to set this to 0:

```
ProxyPass / https://127.0.0.1:9292/ retry=0
```

### SSL with Nginx

You will want to add the following configuration to the relevant SSL server in
nginx.conf:

```
location / {
    proxy_pass http://127.0.0.1:9292/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
}
```

For more configuration options, see the Nginx [HttpProxyModule][] documentation.

[HttpProxyModule]: http://wiki.nginx.org/HttpProxyModule
