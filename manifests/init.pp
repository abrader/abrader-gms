class gms(
  $path         = <absolute path to SSH key>,
  $token        = <token>,
  $project_id   = <project_id>,
  $project_name = <project/respository name>,
  $user_id      = <user id>,
  $access_level = <GUEST = 10, REPORTER = 20, DEVELOPER = 30, MASTER = 40, OWNER = 50>,
  $sshkey_title = <title for test ssh key>,
  $server_url   = <URL for Git management system>,
) {

  git_deploy_key { 'unique_key_name' :
    ensure       => present,
    path         => '/root/.ssh/id_rsa.pub',
    token        => $token,
    project_id   => $project_id,
    project_name => $project_name,
    server_url   => $server_url,
  }

}
