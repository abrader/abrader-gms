require 'puppet/parameter/boolean'

module Puppet
  newtype(:git_webhook) do

    @doc = %q{TODO
    }

    ensurable do
      defaultvalues
      defaultto :present
    end

    newparam(:name, :namevar => true) do
      desc 'A unique title for the key that will be provided to the prefered Git management system.'
    end

    newparam(:system) do
      desc 'Two options here depending on the git management system (Github or Gitlab)'
      newvalues('Github', 'Gitlab')
      validate do |value|
        String(value)
        if value =~ /gitlab/i
          resource[:provider] = :gitlab
        elsif value =~ /stash/i
          resource[:provider] = :stash
        else
          resource[:provider] = :github
        end
      end
    end

    newparam(:webhook_url) do
      desc 'TODO.'
      validate do |value|
        unless value =~ /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*:?.*\/?$/
          raise(Puppet::Error, "Git webhook URL must be fully qualified, not '#{value}'")
        end
      end
    end

    newparam(:token) do
      desc 'The private token require to manipulate the Git management system provider chosen.'
      munge do |value|
        String(value)
      end
    end

    newparam(:project_id) do
      desc 'The project ID associated with the project.'
      munge do |value|
        Integer(value)
      end
    end

    newparam(:project_name) do
      desc 'The project name associated with the project.'
      munge do |value|
        String(value)
      end
    end
    
    newparam(:merge_request_events, :boolean => true, :parent => Puppet::Parameter::Boolean) do
      desc 'The URL in the webhook_url parameter will be triggered when a merge request is created. NOTE: GitLab only'
     
      defaultto false
    end
    
    newparam(:tag_push_events, :boolean => true, :parent => Puppet::Parameter::Boolean) do
      desc 'The URL in the webhook_url parameter will be triggered when a tag push event occurs. NOTE: GitLab only'
      
      defaultto false
    end
    
    newparam(:issue_events, :boolean => true, :parent => Puppet::Parameter::Boolean) do
      desc 'The URL in the webhook_url parameter will be triggered when an issue event occurs. NOTE: GitLab only.'
      
      defaultto false
    end 
    
    newparam(:disable_ssl_verify, :boolean => true, :parent => Puppet::Parameter::Boolean) do
      desc 'Boolean value for disabling SSL verification for this webhook. Note: GitHub only'
      
      defaultto false
    end

    newparam(:server_url) do
      desc 'The URL path to the Git management system server.'
      validate do |value|
        unless value =~ /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/
          raise(Puppet::Error, "Git server URL must be fully qualified, not '#{value}'")
        end
      end
    end

  end
end

