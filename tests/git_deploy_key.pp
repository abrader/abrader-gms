class gms::git_deploy_key {

  git_deploy_key { 'abrader_macbookpro_key_gitlab.com' :
    ensure       => present,
    name         => 'abrader_macbookpro_key',
    path         => '/root/.ssh/id_rsa.pub',
    token        => 'Y5E8vXdjhTu6aDp3YRWs',
    project_id   => 110384,
    server_url   => 'https://gitlab.com',
  }

  git_deploy_key { 'abrader_macbookpro_key_glsrv.puppetlabs.vm' :
    ensure       => present,
    name         => 'abrader_macbookpro_key',
    path         => '/home/abrader/.ssh/id_rsa.pub',
    token        => 'NcuHJ7MLkJnx2DZJ5MKn',
    project_name => 'abrader/control',
    server_url   => 'http://glsrv.puppetlabs.vm',
  }

  git_deploy_key { 'should_be_removed' :
    ensure       => absent,
    path         => '/home/abrader/.ssh/id_rsa.pub',
    token        => 'NcuHJ7MLkJnx2DZJ5MKn',
    project_name => 'abrader/control',
    server_url   => 'http://glsrv.puppetlabs.vm',
  }

}
