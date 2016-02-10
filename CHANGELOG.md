##2016-02-10 - Release 1.0.2
###Summary

This release is mainly a wrap of fixes and updates prior to a major rewrite

####Fixes
- Deploy Keys
  - All Providers
    - Removed restriction on SSL port
  - Stash
    - Fixed issue with initial deploy key not getting created 

- - -

##2015-10-20 - Release 1.0.1
###Summary

This release is purely to expose debugging functionality previously assumed as released. ;)

- - -

##2015-08-24 - Release 1.0.0
###Summary

This release introduces Stash support for both deploy keys and webhooks.

The [README](https://github.com/abrader/abrader-gms/blob/master/README.md) has been updated to include the usage notes for these parameters.

####Features
- New parameters - `Stash`
  - `username`
  - `password`
  - `repo_name`

- - -

##2015-06-12 - Release 0.0.9
###Summary

v0.0.8 Tarball on Puppet Forge had bad permissions for the Webhook provider. Thanks to @bhechinger for the heads up.

- - -

##2015-04-20 - Release 0.0.8
###Summary

This release is because I simply missed the updated CHANGELOG when packaging the previous module release.

- - -

##2015-04-20 - Release 0.0.7

###Summary

This release is for the purpose of easing the regex on the git_webhook type so Basic HTTP Auth included with an URL is an accepted parameter.

- - -

##2015-02-24 - Release 0.0.6
###Summary

This release has many new parameters enabling the ability to set different triggers for webhooks on GitLab and disabling ssl checks on GitHub.  Minor cleanup as well.

The [README](https://github.com/abrader/abrader-gms/blob/master/README.md) has been updated to include the usage notes for these parameters.

####Features
- New parameters - `GitLab`
  - `merge_request_events`
  - `tag_push_events`
  - `issue_events`
- New parameters - `GitHub`
  - `disable_ssl_verify`

- - -
