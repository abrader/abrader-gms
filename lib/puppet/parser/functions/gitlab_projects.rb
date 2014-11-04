require 'net/http'
require 'json'

module Puppet::Parser::Functions
  newfunction(:gitlab_projects, :type => :rvalue) do |args|
    if (args.size < 1 || args.size > 2) then
      raise(Puppet::ParseError, "gitlab_projects(): Wrong number of arguments " + "given #{args.size} for a minimum of 1 and at most 2")
    end

    Puppet::Parser::Functions.autoloader.loadall

    token       = args[0]
    project_set = args[1]

    repos = Hash.new

    if project_set == ( 'owned' || 'all' )
      uri = URI.parse("https://gitlab.com/api/v3/projects/#{project_set}")
    elsif project_set.nil?
      uri = URI.parse('https://gitlab.com/api/v3/projects')
    else
      puts args[1]
      raise(Puppet::ParseError, "gitlab_projects(token,project_set): project_set argument can only be one of two options: \'owned\' or \'all\'")
    end

    http = Net::HTTP.new(uri.host, uri.port)

    if uri.port = 443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    req = function_gitlab_url(['GET', uri.request_uri, token])

    puts uri.request_uri

    http.set_debug_output($stdout)

    response = http.request(req)
    puts response.inspect
    #projects = JSON.parse(response.body)
    #puts projects.inspect

    #projects.each do |child|
    #  repos[child['path_with_namespace']] = child['id']
    #end
    repos

  end
end

