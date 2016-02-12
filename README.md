[![Puppet
Forge](http://img.shields.io/puppetforge/v/abrader/gms.svg)](https://forge.puppetlabs.com/abrader/gms)
[![Build
Status](https://travis-ci.org/abrader/abrader-gms.svg?branch=master)](https://travis-ci.org/abrader/abrader-gms)
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/abrader/abrader-gms?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![Puppet Forge Downloads](http://img.shields.io/puppetforge/dt/abrader/gms.svg)](https://forge.puppetlabs.com/abrader/gms)

# Git Management Systems API Types & Providers

As of right now this repository only covers the following GMS functionality:

## API functions covered

|Function|GitHub|GitLab|Stash|
|--------|------|------|-----|
|git_deploy_key|X|X|X|
|git_webhook|X|X|X|

Of course it is our intent to provide more coverage of the respective APIs in the future.  Please feel free to submit PRs as well.

## Permissions to use API

The following is a table indicating the necessary level of permission needed for the user the authenticating credential(s) are associated with:

|Function|GitHub|GitLab|Stash|
|--------|------|------|-----|
|git_deploy_key|owners|master|repo_admin|
|git_webhook|owners|master|repo_admin|

## Debugging

Troubleshooting issues when APIs are involved can be painful.  Now the advertised providers within this module can pass you useful debugging info when you append the debug argument to your puppet run:

```bash
puppet apply --debug
```
or
```bash
puppet agent --debug
```

## git_deploy_key

A deploy key is an SSH key that is stored on your server and grants access to a single GitHub repository.  This key is attached directly to the repository instead of to a personal user account.  Anyone with access to the repository and server has the ability to deploy the project.  It is also beneficial for users since they are not required to change their local SSH settings.

### GMS agnostic mandatory parameters

#### ensure

Add or remove the deploy key from the GMS

```puppet
ensure       => present,
```
or
```puppet
ensure       => absent,
```

#### path
The file Puppet will ensure is provided to the prefered Git management system

```puppet
path         => '/root/.ssh/id_dsa.pub',
```

#### project_name
The project name associated with the project

Be sure to follow the 'userid/repo' format to insure proper operation for GitHub & GitLab.  For Stash, only include the project name for this parameter.

```puppet
project_name => 'abrader/abrader-gms',
```

#### server_url
The URL path to the Git management system server

Both http & https URLs are acceptable.

```puppet
server_url   => 'http://my.internal.gms.server.example.com',
```

#### provider

The Git Management System you are currently using in reference to the webhook you are managing.  Currently only GitHub and GitLab are supported.

```puppet
provider     => 'github',
```
or
```puppet
provider     => 'gitlab',
```
or
```puppet
provider     => 'stash',
```

#### name
A unique title for the key that will be provided to the prefered Git management system.  This parameter is namevar.

```puppet
name         => 'One of my unique deploy keys',
```

### GitHub & GitLab mandatory authentication parameter

GitHub and GitLab utilize a token based authentication system to access their APIs respectively

#### token
This is the unique token you created within your GMS to allow you to interface with the system via the API.

```puppet
token        => 'ABCDEF1234568',
```

### Stash mandatory authentication parameters

Stash utilizes a Basic Authentication system as well as an OAuth system for accessing their API respectively.  Since OAuth requires a callback URL based system that can not be feasibly implemented by this GMS module, only Basic Authenticaiton is supported.

#### username
This is the unique token you created within your GMS to allow you to interface with the system via the API.

```puppet
username        => 'ihavealotof',
```

#### password
This is the unique token you created within your GMS to allow you to interface with the system via the API.

```puppet
password        => 'puppet_love',
```

### Stash optional parameter

Stash allows a deploy key to be associated with a project ([project_name](#project_name)) or with a repository ([repo_name](#repo_name)).  By choosing to omit the repo_name parameter, this module will assume you are associating the SSH key in your git_deploy_key resource block with the project.

#### repo\_name

```puppet
repo_name       => 'control',
```

### A GitHub & GitLab deploy key example

```puppet
git_deploy_key { 'add_deploy_key_to_puppet_control':
  ensure       => present,
  name         => $::fqdn,
  path         => '/root/.ssh/id_dsa.pub',
  token        => hiera('gitlab_api_token'),
  project_name => 'puppet/control',
  server_url   => 'http://your.internal.github.server.com',
  provider     => 'github',
}
```

### A Stash deploy key example

The example below utilizes the optional [repo_name](#repo_name) parameter to ensure the SSH key in git_deploy_key resouce block below is associated with the repository and not the parent project.

```puppet
git_deploy_key { 'magical stash deploy key' :
  ensure       => present,
  name         => $::fqdn,
  username     => hiera('stash_api_username'),
  password     => hiera('stash_api_password'),
  project_name => 'puppet',
  repo_name    => 'control',
  path         => '/root/.ssh/id_rsa.pub',
  server_url   => 'http://your.internal.stash.server.com:7990',
  provider     => 'stash',
}
```

--

## git_webhook

A webhook allows repository admins to manage the post-receive hooks for a repository.  Very helpful in the case you have many Puppet masters you manage and therefore are responsible for their respective webhooks.  This is refers only to respository webhooks and not organizational webhook as offered by Github.  If that functionality is ever supported by this project it will be identified separately.

### GMS system agnostic mandatory parameters

#### ensure

Add or remove the deploy key from the GMS

```puppet
ensure       => present,
```
or
```puppet
ensure       => absent,
```

#### name

A unique title for the key that will be provided to the prefered Git management system.  This parameter is namevar.

```puppet
name         => 'super_unique_name_for_webhook',
```

#### provider

The Git Management System you are currently using in reference to the webhook you are managing.  Currently only GitHub and GitLab are supported.

```puppet
provider     => 'github',
```
or
```puppet
provider     => 'gitlab',
```
or
```puppet
provider     => 'stash',
```

#### webhook_url

The URL relating to the webhook.  This typically has payload in the name.

```puppet
webhook_url  => 'https://puppetmaster.example.com:8088/payload',
```

#### token
This is the unique token you created within your GMS to allow you to interface with the system via the API.

```puppet
token        => 'ABCDEF1234568',
```

#### project_name
The project name associated with the project

Be sure to follow the 'userid/repo' format to insure proper operation for GitHub & GitLab.  For Stash, only include the project name for this parameter.

```puppet
project_name => 'control',
```

#### server_url
The URL path to the Git management system server

Both http & https URLs are acceptable.

```puppet
server_url   => 'http://my.internal.gms.server.example.com',
```

### GitHub & GitLab mandatory authentication parameter

GitHub and GitLab utilize a token based authentication system to access their APIs respectively

#### token
This is the unique token you created within your GMS to allow you to interface with the system via the API.

```puppet
token        => 'ABCDEF1234568',
```

### Stash mandatory authentication parameters

Stash utilizes a Basic Authentication system as well as an OAuth system for accessing their API respectively.  Since OAuth requires a callback URL based system that can not be feasibly implemented by this GMS module, only Basic Authenticaiton is supported.

#### username
This is the unique token you created within your GMS to allow you to interface with the system via the API.

```puppet
username        => 'ihavealotof',
```

#### password
This is the unique token you created within your GMS to allow you to interface with the system via the API.

```puppet
password        => 'puppet_love',
```

### Stash mandatory parameter

Stash allows a deploy key to be associated with a project ([project_name](#project_name)) or with a repository ([repo_name](#repo_name)).  By choosing to omit the repo_name parameter, this module will assume you are associating the SSH key in your git_deploy_key resource block with the project.

#### repo\_name

The name of the repository associated

```puppet
repo_name       => 'control',
```

### GitHub & Gitlab optional parameters

#### disable\_ssl_verify
Boolean value for disabling SSL verification for this webhook. **NOTE: Does not work on Stash **

```puppet
disable_ssl_verify => true,
```

The gitlab provider sets `enable_ssl_verification` to false when this attribute is used

### GitLab optional Parameters

#### merge\_request_events
The URL in the webhook_url parameter will be triggered when a merge requests event occurs. **NOTE: GitLab only**

```puppet
merge_request_events => true,
```

#### tag\_push_events
The URL in the webhook_url parameter will be triggered when a tag push event occurs. **NOTE: GitLab only**

```puppet
tag_push_events => true,
```

#### issue_events
The URL in the webhook_url parameter will be triggered when an issues event occurs. **NOTE: GitLab only**

```puppet
issue_events => true,
```

### GitHub webhook example

```puppet
git_webhook { 'web_post_receive_webhook' :
  ensure             => present,
  webhook_url        => 'https://puppetmaster.example.com:8088/payload',
  token              =>  hiera('gitlab_api_token'),
  project_name       => 'puppet/control',
  server_url         => 'http://your.internal.github.server.com',
  disable_ssl_verify => true,
  provider           => 'github',
}
```

### GitLab webhook example

```puppet
git_webhook { 'web_post_receive_webhook' :
  ensure               => present,
  webhook_url          => 'https://puppetmaster.example.com:8088/payload',
  token                => hiera('gitlab_api_token'),
  merge_request_events => true,
  project_name         => 'puppet/control',
  server_url           => 'http://your.internal.gitlab.server.com',
  provider             => 'gitlab',
}
```

### Stash webhook example

```puppet
git_webhook { 'web_post_receive_webhook' :
  ensure       => present,
  webhook_url  => 'https://puppetmaster.example.com:8088/payload',
  username     => hiera('stash_api_username'),
  password     => hiera('stash_api_password'),
  project_name => 'puppet',
  repo_name    => 'control',
  server_url   => 'http://your.internal.stash.server.com:7990',
  provider     => 'stash',
}
```

## Limited use access tokens (GitHub only)

By heading over the following link:

[Create a GitHub Access Token](https://github.com/settings/tokens/new)

You should see a screen that resembles something like the following image:

![alt text](https://github.com/abrader/abrader-gms/raw/master/github_new_token.png "GitHub Access Token")

By highlighting **only** the following options:

* write:repo_hook
* read:repo_hook
* admin:repo_hook

You are limiting this token to only be able to manage webhooks.  This may be very beneficial to you if the current tokens available to you entitle too much access. Ultimately, you are puppetizing webhook creation, limiting scope of the token capability only makes sense.



--
