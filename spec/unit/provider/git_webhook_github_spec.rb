require 'spec_helper'

provider_class = Puppet::Type.type(:git_webhook).provider(:github)

describe provider_class do
  let(:resource) { Puppet::Type.type(:git_webhook).new(
    name:        'sasparilla',
    webhook_url: 'https://puppetmaster.example.com:8088/payload',
    token:       'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    project_name: 'puppet/control',
    server_url:   'https://github.com',
    disable_ssl_verify: true,
  )}

  let(:provider) { resource.provider }

  it 'should be an instance of the GitHub' do
    expect(provider).to be_an_instance_of Puppet::Type::Git_webhook::ProviderGithub
  end

end
