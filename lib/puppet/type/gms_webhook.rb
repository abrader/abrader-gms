require_relative '../../puppet_x/puppetlabs/property/read_only'

Puppet::Type.newtype(:gms_webhook) do

  @doc = 'To manage webhooks on major GMS systems.'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'A unique title for the key that will be provided to the prefered Git management system. Required.'
  end

  newproperty(:active) do
    desc 'TODO'

    munge do |value|
     value.to_s
    end

    def insync?(is)
      Puppet.notice("is = #{is.inspect} vs should = #{should.inspect}")
      is == should
    end
  end

  newproperty(:webhook_url) do
    desc 'The URL the webhook will trigger upon a commit to the respective respository. Required. NOTE: GitHub & GitLab only.'

    munge do |value|
     value.to_s
    end

    validate do |value|
      unless value =~ /^(https?:\/\/)?(\S*\:\S*\@)?(\S*)\.?(\S*)\.?(\w*):?(\d*)\/?(\S*)$/
        raise(Puppet::Error, "Git webhook URL must be fully qualified, not '#{value}'")
      end
    end

  end

  newproperty(:content_type) do
    desc 'TODO'

    munge do |value|
     value.to_s
    end
  end

  # newproperty(:config) do
  #   desc 'TODO'
  #
  #   #this is a comparison that ignores order
  #   # def insync?(is)
  #   #   Puppet.notice("is = #{is.sort} and should = #{should.sort}")
  #   #   is.sort == should.sort
  #   # end
  # end

  newproperty(:events, :array_matching => :all) do
    desc 'Events that should trigger the activation of the webhook'

    newvalues("commit_comment", "create", "delete", "deployment", "deployment_status", "fork", "gollum", "issue_comment", "issues", "member", "public", "pull_request", "pull_request_review_comment", "push", "release",  "status", "team_add", "watch")

    def insync?(is)
      Puppet.notice("is = #{is.inspect} vs should = #{should.inspect}")
      is.to_set == should.to_set
    end
  end

  newparam(:token) do
    desc 'The private token require to manipulate the Git management system provider chosen. Required. NOTE: GitHub & GitLab only.'
  end

  newproperty(:username) do
    desc 'The username to be used for authentication vs a token. Required. NOTE: Stash only.'
  end

  newproperty(:password) do
    desc 'The password to be used for authentication vs a token. Required. Note: Stash only.'
  end

  newproperty(:project_name) do
    desc 'The project name associated with the project. Required.'

    munge do |value|
     value.to_s
    end
  end

  newproperty(:repo_name) do
    desc 'The name of the repository associated with the webhook. Required. NOTE: Stash only.'
  end

  newproperty(:hook_exe) do
    desc 'The absolute path to the exectuable triggered when a commit has been made to the respository. Required. NOTE: Stash only.'
  end

  newproperty(:hook_exe_params) do
    desc 'The parameters to be passed along side of the executable that will be triggered when a commit has been made to the repository. Optional. NOTE: Stash only.'
  end

  newproperty(:merge_request_events) do
    desc 'The URL in the webhook_url parameter will be triggered when a merge request is created. Optional. NOTE: GitLab only'
  end

  newproperty(:tag_push_events) do
    desc 'The URL in the webhook_url parameter will be triggered when a tag push event occurs. Optional. NOTE: GitLab only'
 end

  newproperty(:issue_events) do
    desc 'The URL in the webhook_url parameter will be triggered when an issue event occurs. Optional. NOTE: GitLab only.'
  end

  newproperty(:disable_ssl_verify) do
    desc 'Boolean value for disabling SSL verification for this webhook. Optional.'

    munge do |value|
     value.to_s
    end
  end

  newproperty(:server_url) do
    desc 'The URL path to the Git management system server. Required.'

    validate do |value|
      unless value =~ /^(https?:\/\/).*:?.*\/?$/
        raise(Puppet::Error, "Git server URL must be fully qualified, not '#{value}'")
      end
    end
  end

  read_only_properties = {
    id:                    'id',
    last_response_code:    'last_response_code',
    last_response_status:  'last_response_status',
    last_response_message: 'last_response_message',
    updated_at:            'updated_at',
    created_at:            'created_at',
    rest_url:              'rest_url',
    test_url:              'test_url',
    ping_url:              'ping_url',
  }

  read_only_properties.each do |property, value|
    newproperty(property, :parent => PuppetX::Property::ReadOnly) do
      desc "Information related to #{value} from the GitHub v3 API."

      munge do |value|
       value.to_s
      end
    end
  end

end
