module Puppet
  newtype(:git_add_user_to_project) do

    @doc = "TODO"

    ensurable do
      defaultvalues
      defaultto :present
    end

    newparam(:username, :namevar => true) do
      desc 'The title of the key that will be provided to the Git management system provider chosen.'
      munge do |value|
        String(value)
      end
    end

    newparam(:user_id) do
      desc 'The corresponding user ID of the user you would like to grant access rights to said repository.'
      munge do |value|
        Integer(value)
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

    newparam(:access_level) do
      desc 'The access level to be granted to the user specified in user_id or username.'
      newvalues(10,20,30,40)
      munge do |value|
        Integer(value)
      end
    end

  end
end

