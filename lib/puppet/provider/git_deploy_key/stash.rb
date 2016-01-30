require 'puppet'
require 'net/http'
require 'json'

Puppet::Type.type(:git_deploy_key).provide(:stash) do

  defaultfor :stash => :exists

  def calling_method
    # Get calling method and clean it up for good reporting
    cm = String.new
    cm = caller[0].split(" ").last
    cm.tr!('\'', '')
    cm.tr!('\`','')
    cm
  end

  def prereq_check
    # Check to see if all required parameters have been passed
    missing_params = Array.new

    if resource[:name].nil?
      missing_params << 'name'
    end
    if resource[:username].nil?
      missing_params << 'username'
    end
    if resource[:password].nil?
      missing_params << 'password'
    end
    if resource[:project_name].nil?
      missing_params << 'project_name'
    end
    if resource[:path].nil?
      missing_params << 'hook_exe'
    end
    if resource[:server_url].nil?
      missing_params << 'server_url'
    end
    if missing_params.size > 0
      raise(Puppet::Error, "stash_webhook::#{calling_method}: Must supply the git_webhook resource with required parameter(s): #{missing_params.join(', ')}")
    end
  end

  def gms_server
    # Return the prefix portion of the URL
    return resource[:server_url].strip unless resource[:server_url].nil?
    return 'http://localhost:7990'
  end

  def api_call(action,url,data = nil)
    # Reusable API caller method
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)

    if uri.port == 443 or uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    else
      http.use_ssl = false
    end

    if Puppet[:debug] == true
      http.set_debug_output($stdout)
    end

    if action =~ /post/i
      req = Net::HTTP::Post.new(uri.request_uri)
    elsif action =~ /put/i
      req = Net::HTTP::Put.new(uri.request_uri)
    elsif action =~ /delete/i
      req = Net::HTTP::Delete.new(uri.request_uri)
    else
      req = Net::HTTP::Get.new(uri.request_uri)
    end

    req.set_content_type('application/json')
    req.basic_auth(resource[:username].strip, resource[:password].strip)

    if data
      req.body = data.to_json
    end

    Puppet.debug("stash_deploy_key::#{calling_method}: REST API #{req.method} Endpoint: #{uri.to_s}")
    Puppet.debug("stash_deploy_key::#{calling_method}: REST API #{req.method} Request: #{req.inspect}")

    response = http.request(req)

    Puppet.debug("stash_deploy_key::#{calling_method}: REST API #{req.method} Response: #{response.inspect}")

    response
  end

  def get_key_id
    # Return the deploy key ID
    prereq_check()

    url = String.new

    pn = resource[:project_name].strip

    unless resource[:repo_name].nil?
      rs = resource[:repo_name].strip
      url = "#{gms_server}/rest/keys/1.0/projects/#{pn}/repos/#{rs}/ssh"
    else
      url = "#{gms_server}/rest/keys/1.0/projects/#{pn}/ssh"
    end

    response = api_call('GET', url)

    raise(Puppet::Error, "stash_deploy_key::#{calling_method}: #{response.inspect}") unless response.class == Net::HTTPOK

    key_json = JSON.parse(response.body)

    # Clearly no deploy keys exist if size == 0
    if key_json['size'] == 0
      Puppet.debug("stash_deploy_key::#{calling_method}: No pre-existing deploy keys. Onto creation!")
      return nil
    else
      key_json['values'].each do |v|
        if v['key']['text'].eql?(File.read(resource[:path].strip).strip)
          Puppet.debug("stash_deploy_key::#{calling_method}: Found a key match for deploy key.  Nothing more to do.")
          return v['key']['id']
        end
      end
    end

    Puppet.debug("stash_deploy_key::#{calling_method}: Key provided with git_deploy_key resource is not a match for what is on file. Onto creation!")
    return nil
  end

  def exists?
    # Checks to see if the deploy exists on the Stash server
    if get_key_id.nil?
      return false
    else
      return true
    end
  end

  def create
    # Creates a deploy key in the Stash server project or repository referenced.
    pn = resource[:project_name].strip

    url = String.new

    opts = Hash.new
    opts['key'] = Hash.new
    opts['key']['text'] = File.read(resource[:path].strip).strip

    unless resource[:repo_name].nil?
      rs = resource[:repo_name].strip
      opts['permission'] = "REPO_READ"
      url = "#{gms_server}/rest/keys/1.0/projects/#{pn}/repos/#{rs}/ssh"
    else
      opts['permission'] = "PROJECT_READ"
      url = "#{gms_server}/rest/keys/1.0/projects/#{pn}/ssh"
    end

    response = api_call('POST', url, opts)

    if response.class == Net::HTTPCreated
      if resource[:repo_name].nil?
        Puppet.debug("stash_deploy_key::#{calling_method}: Successfully created deploy key \'#{resource[:name]}\' for project \'#{resource[:project_name]}\'")
      else
        Puppet.debug("stash_deploy_key::#{calling_method}: Successfully created deploy key \'#{resource[:name]}\' for repository \'#{resource[:repo_name]}\' in project \'#{resource[:project_name]}\'")
      end
      return true
    else
      raise(Puppet::Error, "stash_deploy_key::#{calling_method}: #{response.inspect}")
    end
  end

  def destroy
    # Remove the deploy key from the Stash project or repository referenced.
    dk_key_id = get_key_id
    pn = resource[:project_name].strip

    unless resource[:repo_name].nil?
      rs = resource[:repo_name].strip
      url = "#{gms_server}/rest/keys/1.0/projects/#{pn}/repos/#{rs}/ssh/#{dk_key_id}"
    else
      url = "#{gms_server}/rest/keys/1.0/projects/#{pn}/ssh/#{dk_key_id}"
    end

    response = api_call('DELETE', url)

    if response.class == Net::HTTPNoContent
      if resource[:repo_name].nil?
        Puppet.debug("stash_deploy_key::#{calling_method}: Successfully deleted deploy key \'#{resource[:name]}\' from project \'#{resource[:project_name]}\'")
      else
        Puppet.debug("stash_deploy_key::#{calling_method}: Successfully deleted deploy key \'#{resource[:name]}\' from repository \'#{resource[:repo_name]}\' in project \'#{resource[:project_name]}\'")
      end
    end
  end

end
