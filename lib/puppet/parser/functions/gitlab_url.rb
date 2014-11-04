  require 'net/http'

  module Puppet::Parser::Functions
    newfunction(:gitlab_url, :type => :rvalue) do |args|
      if (args.size != 3) then
        raise(Puppet::ParseError, "gitlab_url(): Wrong number of arguments " + "given #{args.size} for 3")
      end

      action  = args[0]
      params  = args[1]
      token   = args[2]

      if action =~ /post/i
        req = Net::HTTP::Post.new(params)
      elsif  action =~ /put/i
        req = Net::HTTP::Put.new(params)
      else
        req = Net::HTTP::Get.new(params)
      end

      req.set_content_type('application/json')
      req.add_field('PRIVATE-TOKEN', token)
      req
    end
  end
