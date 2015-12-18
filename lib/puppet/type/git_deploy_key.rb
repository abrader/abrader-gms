module Puppet
  Puppet::Type.newtype(:git_deploy_key) do

    @doc = %q{A deploy key is an SSH key that is stored on your server and grants access to a single GitHub repository.  This key is attached directly to the repository instead of to a personal user account.  Anyone with access to the repository and server has the ability to deploy the project.  It is also beneficial for users since they are not required to change their local SSH settings.
    }

    ensurable do
      defaultvalues
      defaultto :present
    end

    newparam(:name, :namevar => true) do
      desc 'A unique title for the key that will be provided to the prefered Git management system.'
    end

    newparam(:path) do
      desc 'The file Puppet will ensure is provided to the prefered Git management system.'
      validate do |value|
        unless (Puppet.features.posix? and value =~ /^\//) or (Puppet.features.microsoft_windows? and (value =~ /^.:\// or value =~ /^\/\/[^\/]+\/[^\/]+/))
          raise(Puppet::Error, "File paths must be fully qualified, not '#{value}'")
        end
      end
    end

    newparam(:token) do
      desc 'The private token require to manipulate the Git management system provider chosen.'
      munge do |value|
        String(value)
      end
    end
    
    newparam(:username) do
      desc 'The username to be used to authenticate with the Stash server for API access.'
      munge do |value|
        String(value)
      end
    end
    
    newparam(:password) do
      desc 'The password to be used to authenticate with the Stash server for API access.'
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
    
    newparam(:repo_name) do
      desc 'The repository name the deploy key will be associated. If this parameter is ommitted, the deploy key will be associated with the project instead. Optional.  NOTE: Stash only.'
      munge do |value|
        String(value)
      end
    end

    newparam(:server_url) do
      desc 'The URL path to the Git management system server.'
      validate do |value|
        #unless value =~ /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/
        unless value =~ /^(https?:\/\/).*:?.*\/?$/
          raise(Puppet::Error, "Git server URL must be fully qualified, not '#{value}'")
        end
      end
    end

    newparam(:write_permission) do
      desc "Whether the deploy key has read or write access. Defaults to false."
      newvalues(:true, :false)

      defaultto :false
    end

    autorequire(:file) do
      self[:path]if self[:path] and Pathname.new(self[:path]).absolute?
    end

  end
end

