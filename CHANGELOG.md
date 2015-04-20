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
