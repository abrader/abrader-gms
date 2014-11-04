class gitlab(
  $token = <token>,
  $project_id = <project_id>,
  $project_name = <project/respository name>,
  $user_id = <user id>,
  $access_level = '20',
  $sshkey_title = <title for test ssh key>,
  $sshkey = <test ssh key>,
) {

  #git_deploy_key { 'All your bases are belong to us' :
  #  #ensure      => present,
  #  ensure       => absent,
  #  path         => '/root/.ssh/id_rsa.pub',
  #  token        => $token,
  #  project_id   => $project_id,
  #  #project_name => $project_name,
  #}

  git_add_user_to_project { 'abrader' :
    username     => 'abrader',
    ensure       => present,
    token        => $token,
    project_id   => $project_id,
    user_id      => $user_id,
    access_level => $access_level,
  }

}
