# Forward declaration(s)
module PuppetX; end
module PuppetX::GMS; end

module PuppetX::GMS::Type
  def validate_token_or_token_file
    # The token and token_file parameters are mutually exclusive. It is an
    # error to provide both simultaneously.
    if !parameters[:token].nil? and !parameters[:token_file].nil?
      fail 'token and token_file are mutually exclusive. Only one of these parameters can be specified, not both together'
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def add_parameter_token
      newparam(:token) do
        desc 'The private token require to manipulate the Git management system provider chosen.'
        munge do |value|
          String(value)
        end
      end
    end

    def add_parameter_token_file
      newparam(:token_file) do
        desc 'The path to a file on the agent containing the private token require to manipulate the Git management system provider chosen. Required. NOTE: GitHub & GitLab only.'
        munge do |value|
          String(value)
        end
      end
    end

    def add_parameter_username
      newparam(:username) do
        desc 'The username to be used to authenticate with the Stash server for API access.'
        munge do |value|
          String(value)
        end
      end
    end

    def add_parameter_password
      newparam(:password) do
        desc 'The password to be used to authenticate with the Stash server for API access.'
        munge do |value|
          String(value)
        end
      end
    end
  end
end
