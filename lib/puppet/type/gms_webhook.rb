require_relative '../../puppet_x/puppetlabs/property/read_only'
require 'puppet_x/gms/type'

Puppet::Type.newtype(:gms_webhook) do
  include PuppetX::GMS::Type

  @doc = 'To manage webhooks on major GMS systems.'

  ensurable

  newparam(:name)

  newproperty(:active) do
    desc 'Boolean to make webhook active or inactive.  GitHub only.'

    newvalues(true, false)
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

  newproperty(:events, :array_matching => :all) do
    desc 'Events that should trigger the activation of the webhook'

    newvalues("commit_comment", "create", "delete", "deployment", "deployment_status", "fork", "gollum", "issue_comment", "issues", "member", "public", "pull_request", "pull_request_review_comment", "push", "release",  "status", "team_add", "watch")

    def insync?(is)
      is.to_set == should.to_set
    end
  end

  add_parameter_token
  add_parameter_token_file
  add_parameter_username
  add_parameter_password

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

  newproperty(:push_events) do
    desc 'Boolean value for indicating if webhook should be triggered on a push event. GitLab Only.'

    def insync?(is)
      is.to_s == should.to_s
    end

    defaultto :false
    newvalues(:true, :false)
  end

  newproperty(:issues_events) do
    desc 'Boolean value for indicating if webhook should be triggered on an issues event. GitLab Only.'

    def insync?(is)
      is.to_s == should.to_s
    end

    defaultto :false
    newvalues(:true, :false)
  end

  newproperty(:merge_requests_events) do
    desc 'Boolean value for indicating if webhook should be triggered on a merge requests event. GitLab Only.'

    def insync?(is)
      is.to_s == should.to_s
    end

    defaultto :false
    newvalues(:true, :false)
  end

  newproperty(:tag_push_events) do
    desc 'Boolean value for indicating if webhook should be triggered on a tag push event. GitLab Only.'

    def insync?(is)
      is.to_s == should.to_s
    end

    defaultto :false
    newvalues(:true, :false)
  end

  newproperty(:note_events) do
    desc 'Boolean value for indicating if webhook should be triggered on a note event. GitLab Only.'

    def insync?(is)
      is.to_s == should.to_s
    end

    defaultto :false
    newvalues(:true, :false)
  end

  newproperty(:build_events) do
    desc 'Boolean value for indicating if webhook should be triggered on a build event. GitLab Only.'

    def insync?(is)
      is.to_s == should.to_s
    end

    defaultto :false
    newvalues(:true, :false)
  end

  newproperty(:pipeline_events) do
    desc 'Boolean value for indicating if webhook should be triggered on a pipeline event. GitLab Only.'

    def insync?(is)
      is.to_s == should.to_s
    end

    defaultto :false
    newvalues(:true, :false)
  end

  newproperty(:wiki_page_events) do
    desc 'Boolean value for indicating if webhook should be triggered on a wiki page event. GitLab Only.'

    def insync?(is)
      is.to_s == should.to_s
    end

    defaultto :false
    newvalues(:true, :false)
  end

  newproperty(:insecure_ssl) do
    desc 'Boolean value for disabling SSL verification for this webhook. Optional.'

    defaultto :false
    newvalues(:true, :false)
  end

  newproperty(:server_url) do
    desc 'The URL path to the Git management system server. Required.'

    validate do |value|
      unless value =~ /^(https?:\/\/).*:?.*\/?$/
        raise(Puppet::Error, "Git server URL must be fully qualified, not '#{value}'")
      end
    end
  end

  newparam(:gitlab_api_version) do
    desc 'The api version to use with gitlab.'
    defaultto :v4
    newvalues(:v3, :v4)
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

  validate do
    validate_token_or_token_file
  end

end
