yats
====

Yet Another Thing For Doing SSH Stuff (but just YATS sounded better :)

A command-line interface for searching and opening ssh connections to multiple EC2 instances on OS X.

Install
=======

Put the ruby script somewhere in your path, make sure you have the right gems installed:

```
gem install aws-sdk-core
```

```
gem install curses
```

Set up your AWS info in your ~/.bash_proile if you haven't already:

```
export AWS_ACCESS_KEY_ID='...'
export AWS_SECRET_ACCESS_KEY='...'
export AWS_REGION='us-east-1'
```

If the EC2 servers you'll be logging into expect a different username than the one you're logged into on your local machine, you can also specify the remote username in this file:

```
export YATS_USERNAME='ed'
```

To run this, I have the following in my ~/.bashrc:

```
alias yats="ruby ~/bin/ruby/yats.rb"
```

Usage
=====

Assuming some quirk in the required gems or your particular OS X install doesn't cause issues, you should be able to do a:

```
yats term1 term2 term3
```

And you should get a full-terminal list of instances with those terms in the Name tag.

Use up/down to move cursor, space to select items, escape to escape, and enter to spawn ssh sessions for each of those instances in new terminal windows (I really wish it were tabs, but this works...)

TODO
====

* I'm not really doing anything special with reservations for multiple instances at once.
* Per-instance username configuration

