require 'spec_helper'

type_class = Puppet::Type.type(:git_webhook)

describe type_class do
  let :params do
    [
      :name,
      :webhook_url,
      :token,
      :username,
      :password,
      :project_id,
      :project_name,
      :repo_name,
      :hook_exe,
      :hook_exe_params,
      :merge_request_events,
      :tag_push_events,
      :issue_events,
      :disable_ssl_verify,
      :server_url,
    ]
  end

  let :properties do
    [
      :ensure,
    ]
  end

  it 'should have expected properties' do
    properties.each do |prop|
      expect(type_class.properties.map(&:name)).to be_include(prop)
    end
  end

  it 'should have expected parameters' do
    params.each do |param|
      expect(type_class.parameters).to be_include(param)
    end
  end

  it 'should require a name' do
    expect {
      type_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

end
