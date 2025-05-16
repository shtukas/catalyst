### Catalyst

Catalyst is an advanced task management system.

### Install

```
$ rbenv install 3.4.1
$ rbenv local 3.4.1
$ ~/.rbenv/versions/3.4.1/bin/bundle install
```

If we have a problem after upgrading Ruby, for instance sqlite3 is not working, try:

```
$ brew reinstall sqlite # primary instance only.
$ ~/.rbenv/versions/3.4.1/bin/gem uninstall sqlite3
$ ~/.rbenv/versions/3.4.1/bin/gem install sqlite3
$ ~/.rbenv/versions/3.4.1/bin/bundle install
```
