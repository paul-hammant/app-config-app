I (Paul) have most likely directed you here because I'm trying to sell you "apps backed by source-control" generally, or "app-config in source-control" specifically which I claim is the gold standard of such things.  Note apps in this context are the things you wrote source for that and are truly unique; they are not infrastructure packages like Postgres or Apache which also have config. 

Application Configuration App
=============================

Ports to different source-control back-ends
-------------------------------------------

App-Config-App stores config into source-control. Two Implementations so far:

[Git + Github version of app-config-app is on a 'git' branch](https://github.com/paul-hammant/app-config-app/tree/git)
(Rather a rudimentary version, that serves as the proof of concept) 

[Perforce version of app-config-app is on a 'perforce' branch](https://github.com/paul-hammant/app-config-app/tree/perforce)
(fellow ThoughtWorker Logan McGrath did the work, with I was Product Owner and P4 tech consultant)

Why Source-Control
------------------

* Is carriage return delimited text
* Terse diffs (if pretty printed consistently)
* Suits branching
* Audit-Trail is helpful
* Permissions per-branch or even subdirectory (not all impls)
* Rollback is atomic
* [Maintained Divergence can be deliberate](http://paulhammant.com/2013/04/02/maintained-divergence/)

Timeline of Blog entries talking about this
-------------------------------------------

[http://paulhammant.com/2012/07/10/app-config-workflow-using-scm](http://paulhammant.com/2012/07/10/app-config-workflow-using-scm)
[http://paulhammant.com/2012/08/14/app-config-using-git-and-angular](http://paulhammant.com/2012/08/14/app-config-using-git-and-angular)
[http://loganmcgrath.com/blog/2012/11/07/using-perforce-chronicle-for-application-configuration](http://loganmcgrath.com/blog/2012/11/07/using-perforce-chronicle-for-application-configuration)
[http://loganmcgrath.com/blog/2012/11/16/scm-backed-application-configuration-with-perforce](http://loganmcgrath.com/blog/2012/11/16/scm-backed-application-configuration-with-perforce)
[http://loganmcgrath.com/blog/2012/11/20/app-config-app-in-action](http://loganmcgrath.com/blog/2012/11/20/app-config-app-in-action)
[http://loganmcgrath.com/blog/2012/11/28/promoting-changes-with-app-config-app](http://loganmcgrath.com/blog/2012/11/28/promoting-changes-with-app-config-app)
[http://paulhammant.com/2013/01/08/perforce-as-a-datastore-with-client-side-mvc](http://paulhammant.com/2013/01/08/perforce-as-a-datastore-with-client-side-mvc)

Invariant Technologies
----------------------

[AngularJS](http://angularjs.org) (JavaScript): we're scotch-taping fragments of it into a...

[Sinatra](http://www.sinatrarb.com) (Ruby): serverside templating tech.

Knockout could have been used instead of Angular, and any server-side templating tech could have been used instead of Sinatra (but would struggle to beat the lines of code count).
