class gms::git_webhook {

  # git_webhook { 'abrader_macbookpro_key_gitlab.com' :
  #   ensure       => present,
  #   name         => 'abrader_macbookpro_key',
  #   webhook_url  => 'http://master.puppetlabs.vm/payload',
  #   token        => 'Y5E8vXdjhTu6aDp3YRWs',
  #   project_id   => 110384,
  #   server_url   => 'https://gitlab.com',
  # }
  #
  # git_webhook { 'abrader_macbookpro_key_glsrv.puppetlabs.vm' :
  #   ensure       => present,
  #   name         => 'abrader_macbookpro_key',
  #   webhook_url  => 'http://master.puppetlabs.vm/payload',
  #   token        => 'NcuHJ7MLkJnx2DZJ5MKn',
  #   project_name => 'abrader/control',
  #   server_url   => 'http://glsrv.puppetlabs.vm',
  # }
  #
  # git_webhook { 'should_be_removed' :
  #   ensure       => absent,
  #   webhook_url  => 'http://master.puppetlabs.vm/payload',
  #   token        => 'NcuHJ7MLkJnx2DZJ5MKn',
  #   project_name => 'abrader/control',
  #   server_url   => 'http://glsrv.puppetlabs.vm',
  # }
  
  git_webhook { 'testing stash' :
    ensure      => present,
    name        => 'abrader_macbookpro_key',
    webhook_url => 'http://master.puppetlabs.vm:8080/payload',
    username    => 'abrader',
    password    => 'fuck!@#0FF',
    server_url  => 'http://localhost:7990',
  }

}
