require 'net/http'
require 'json'

module Puppet::Parser::Functions
  newfunction(:gitlab_add_deploy_key, :type => :rvalue) do |args|
    if (args.size != 4) then
      raise(Puppet::ParseError, "gitlab_add_deploy_key(token,project_id,title,key): Wrong number of arguments " + "given #{args.size} for 4")
    end

    Puppet::Parser::Functions.autoloader.loadall

    token      = args[0]  # Gitlab Private Token
    project_id = args[1]  # Gitlab Project ID
    title      = args[2]  # Title of SSH Key
    key        = args[3]  # Key to added to deploy key for said Project ID

    uri = URI.parse("https://gitlab.com/api/v3/projects/#{project_id}/keys")
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.port = 443 or uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    req = function_gitlab_url(['POST', uri.request_uri, token])

    req.set_form_data({'title' => title, 'key' => key})

    begin
      response = http.request(req)

      if (response.class == Net::HTTPCreated)
        return true
      else
        raise(Puppet::ParseError, "Failed: gitlab::add_deploy_key: #{response.inspect}")
        #raise
      end
    rescue Exception => e
      raise(Puppet::ParseError, e.message)
    end

  end
end
