class gms(
  $name         = <unique name to identify key>
  $path         = <absolute path to SSH key>,
  $token        = <token>,
  $project_id   = <project_id>,
  $project_name = <project/respository name>,
  $server_url   = <URL for Git management system # i.e., https://gitlab.com>,
) {

  git_deploy_key { 'unique_key_name' :
    name         => $name,
    ensure       => present,
    path         => '/root/.ssh/id_rsa.pub',
    token        => $token,
    project_id   => $project_id,
    project_name => $project_name,
    server_url   => $server_url,
  }

}
