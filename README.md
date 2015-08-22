# Git Management Systems API Types & Providers

As of right now this repository only covers the following GMS functionality:

## API functions covered

|Function|GitHub|GitLab|Stash|
|--------|------|------|-----|
|git_deploy_key|X|X|X|
|git_webhook|X|X|X|

Of course it is our intent to provide more coverage of the respective APIs in the future.  Please feel free to submit PRs as well.

## git_deploy_key

A deploy key is an SSH key that is stored on your server and grants access to a single GitHub repository.  This key is attached directly to the repository instead of to a personal user account.  Anyone with access to the repository and server has the ability to deploy the project.  It is also beneficial for users since they are not required to change their local SSH settings.

### Mandatory parameters

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

#### token
This is the unique token you created within your GMS to allow you to interface with the system via the API.

```puppet
token        => 'ABCDEF1234568',
```

#### project_name
The project name associated with the project

Be sure to follow the 'userid/repo' format to insure proper operation.

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

### Optional parameters

#### name
A unique title for the key that will be provided to the prefered Git management system.

```puppet
name         => 'One of my unique deploy keys',
```

### An example

```puppet
git_deploy_key { 'add_deploy_key_to_puppet_control':
  ensure       => present,
  name         => $::fqdn,
  path         => '/root/.ssh/id_dsa.pub',
  token        => hiera('gitlab_api_token'),
  project_name => 'puppet/control',
  server_url   => 'http://your.internal.gitlab.server.com',
  provider     => 'gitlab',
}
```

--

## git_webhook

A webhook allows repository admins to manage the post-receive hooks for a repository.  Very helpful in the case you have many Puppet masters you manage and therefore are responsible for their respective webhooks.  This is refers only to respository webhooks and not organizational webhook as offered by Github.  If that functionality is ever supported by this project it will be identified separately.

### Mandatory Parameters

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

A unique title for the key that will be provided to the prefered Git management system.

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

Be sure to follow the 'userid/repo' format to insure proper operation.

```puppet
project_name => 'abrader/abrader-gms',
```

#### server_url
The URL path to the Git management system server

Both http & https URLs are acceptable.

```puppet
server_url   => 'http://my.internal.gms.server.example.com',
```

### Optional Parameters

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

#### disable\_ssl_verify
Boolean value for disabling SSL verification for this webhook. **NOTE: GitHub only**

```puppet
disable_ssl_verify => true,
```

### An example

```puppet
git_webhook { 'web_post_receive_webhook' :
  ensure       => present,
  webhook_url  => 'https://puppetmaster.example.com:8088/payload',
  token        =>  hiera('gitlab_api_token'),
  project_name => 'puppet/control',
  server_url   => 'http://your.internal.gitlab.com',
  provider     => 'gitlab',
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
