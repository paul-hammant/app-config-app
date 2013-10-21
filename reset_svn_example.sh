rm -Rf wc && rm -Rf svn_files && killall svnserve
./svn_daemon.sh && ruby svn_setup_example.rb
bundle exec rackup
