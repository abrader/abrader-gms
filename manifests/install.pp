# Private class
class gms::install {
  if $::puppetversion and $::puppetversion =~ /Puppet Enterprise/ {
    $provider = 'pe_gem'
  } elsif $::puppetversion and versioncmp($::puppetversion, '4.0.0') >= 0 {
    $provider = 'puppet_gem'
  } else {
    $provider = 'gem'
  }
  package { 'faraday':
    ensure   => present,
    provider => $provider,
  }
}
