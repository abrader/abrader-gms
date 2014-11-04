module Puppet
  newtype(:git_deploy_key) do

    @doc = "TODO"

    ensurable do
      defaultvalues
      defaultto :present
    end

    newparam(:name, :namevar => true) do
      desc 'The title of the key that will be provided to the Git management system provider chosen.'
    end

    newparam(:path) do
      desc 'The file Puppet will ensure is used with the Git management system provider chosen.'
      validate do |value|
        unless (Puppet.features.posix? and value =~ /^\//) or (Puppet.features.microsoft_windows? and (value =~ /^.:\// or value =~ /^\/\/[^\/]+\/[^\/]+/))
          raise(Puppet::Error, "File paths must be fully qualified, not '#{value}'")
        end
      end
    end

    newparam(:token) do
      desc 'The private token needed to manipulate the Git management system provider chosen.'
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

    autorequire(:file) do
      self[:path]if self[:path] and Pathname.new(self[:path]).absolute?
    end

  end
end

