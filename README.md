I (Paul) have most likely directed you here because I'm trying to sell you "app config backed by source-control", which I claim is the gold standard of such things. Note: Apps in this context are the things you wrote source for that and are truly unique; they are not infrastructure packages like Postgres, Tomcat or Apache which also have config. 

For for the purposes of this demo, [Feature Toggles](http://martinfowler.com/bliki/FeatureToggle.html) is the configurable thing that we're going to show.  CMS, Biz Rules, ETL, BPM, Case Mgmt Workflows are all "configurable" things for a platform, that might be maintained within the same system, but **toggles** are what we're showing here, and not just on/off ones.

Application Configuration App
=============================

App-Config-App stores shared config into source-control. This suits **one branch per environment** and merge point tracking as a way of being assured of correct config promotion.

It makes config available over HTTP as JSON.

It provides editing of config, using AngularJS (without a schema), and exposes a 'commit' button in the web page to handle the interop to/from source-control for you.  

It is also "round-trip" in that you can also check-out the JSON source files using regular command line tools, edit, and commit back, without using the web UI.

Ports to different source-control back-ends
-------------------------------------------

Two working implementations so far:

* [Git + Github version of app-config-app is on a 'git' branch](https://github.com/paul-hammant/app-config-app/tree/git)
(Rather a rudimentary version, that serves as the proof of concept) 

* [Perforce version of app-config-app is on a 'perforce' branch](https://github.com/paul-hammant/app-config-app/tree/perforce)
(fellow ThoughtWorker Logan McGrath did the work, with I was Product Owner and P4 tech consultant)

One half-working implementation too:

* [Subversion version of app-config-app is on a 'subversion' branch](https://github.com/paul-hammant/app-config-app/tree/subversion)

Why Source-Control?
-------------------

* Is carriage return delimited text
* Terse diffs (if pretty printed consistently)
* Suits branching
* Audit-Trail is helpful
* Permissions per-branch or even subdirectory (not all impls)
* Rollback is atomic
* [Maintained Divergence can be deliberate](http://paulhammant.com/2013/04/02/maintained-divergence/)

Timeline of Blog entries talking about this
-------------------------------------------

(chronalogical order)

1. [http://paulhammant.com/2012/07/10/app-config-workflow-using-scm](http://paulhammant.com/2012/07/10/app-config-workflow-using-scm)
2. [http://paulhammant.com/2012/08/14/app-config-using-git-and-angular](http://paulhammant.com/2012/08/14/app-config-using-git-and-angular)
[http://loganmcgrath.com/blog/2012/11/07/using-perforce-chronicle-for-application-configuration](http://loganmcgrath.com/blog/2012/11/07/using-perforce-chronicle-for-application-configuration)
3. [http://loganmcgrath.com/blog/2012/11/16/scm-backed-application-configuration-with-perforce](http://loganmcgrath.com/blog/2012/11/16/scm-backed-application-configuration-with-perforce)
4. [http://loganmcgrath.com/blog/2012/11/20/app-config-app-in-action](http://loganmcgrath.com/blog/2012/11/20/app-config-app-in-action) - features a video showing the setting of toggles thru the admin app, and how that affects the "server" in question
5. [http://loganmcgrath.com/blog/2012/11/28/promoting-changes-with-app-config-app](http://loganmcgrath.com/blog/2012/11/28/promoting-changes-with-app-config-app) - screen shots of the promotion (merging as done by Perforce)
6. [http://paulhammant.com/2013/01/08/perforce-as-a-datastore-with-client-side-mvc](http://paulhammant.com/2013/01/08/perforce-as-a-datastore-with-client-side-mvc)

Invariant Technologies between ports
------------------------------------

[AngularJS](http://angularjs.org) (JavaScript): we're scotch-taping fragments of it into Sinatra (below) meaning this is not a SinglePageApplication (SPA).

[Sinatra](http://www.sinatrarb.com) (Ruby): serverside templating tech.

Knockout, Batman, VueJs could have been used instead of AngularJS, and any server-side templating tech could have been used instead of Sinatra.
