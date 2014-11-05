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

    newparam(:webhook_url) do
      desc 'TODO.'
      validate do |value|
        unless value =~ /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/
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

