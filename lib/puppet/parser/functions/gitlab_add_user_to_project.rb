## Gitlab: Add user to a project

# Project ID must be numeric
# Access level must be numeric: Guest => 10, Reporter => 20, Developer => 30, Master => 40

require 'net/http'
require 'json'

module Puppet::Parser::Functions
  newfunction(:gitlab_add_user_to_project, :type => :rvalue) do |args|
    if (args.size != 4) then
      raise(Puppet::ParseError, "gitlab_add_user_to_project(): Wrong number of arguments " + "given #{args.size} for 4")
    end

    Puppet::Parser::Functions.autoloader.loadall

    token        = args[0]
    project_id   = args[1]
    user_id      = args[2]
    access_level = args[3]
    
    uri = URI.parse("https://gitlab.com/api/v3/projects/#{project_id}/members")
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.port = 443 or uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    #http.set_debug_output($stdout)

    req = function_gitlab_url(['POST', uri.request_uri, token])

    req.set_form_data({'user_id' => user_id, 'access_level' => access_level})

    begin
      http.request(req)
    rescue Exception => e
      puts e.message
    end

  end
end

