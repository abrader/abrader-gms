require 'puppet'
require 'net/http'
require 'json'
require 'puppet_x/gms/provider'

Puppet::Type.type(:git_deploy_key).provide(:gitlab) do
  include PuppetX::GMS::Provider

  defaultfor :gitlab => :exists

  def gms_server
    return resource[:server_url].strip unless resource[:server_url].nil?
    return 'https://gitlab.com'
  end

  def api_version
    return resource[:gitlab_api_version]
  end

  def keys_endpoint
    if api_version.to_s.eql? "v3"
      return 'keys'
    else
      return 'deploy_keys'
    end
  end

  def calling_method
    # Get calling method and clean it up for good reporting
    cm = String.new
    cm = caller[0].split(" ").last
    cm.tr!('\'', '')
    cm.tr!('\`','')
    cm
  end

  def api_call(action,url,data = nil)
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
    req.add_field('PRIVATE-TOKEN', get_token)

    if data
      req.body = data.to_json
    end

    Puppet.debug("gitlab_deploy_key::#{calling_method}: REST API #{req.method} Endpoint: #{uri.to_s}")
    Puppet.debug("gitlab_deploy_key::#{calling_method}: REST API #{req.method} Request: #{req.inspect}")

    response = http.request(req)

    Puppet.debug("gitlab_deploy_key::#{calling_method}: REST API #{req.method} Response: #{response.inspect}")

    response
  end

  def exists?
    project_id = get_project_id

    sshkey_hash = Hash.new

    url = "#{gms_server}/api/#{api_version}/projects/#{project_id}/#{keys_endpoint}"

    response = api_call('GET', url)

    sshkey_json = JSON.parse(response.body)
    sshkey_json.each do |child|
      sshkey_hash[child['key']] = child['id']
    end

    sshkey_hash.keys.each do |k|
      if k.eql?(File.read(resource[:path]).strip)
        Puppet.debug "gitlab_deploy_key::#{calling_method}: Deploy key already exists as specified in calling resource block."
        return true
      end
    end

    Puppet.debug "gitlab_deploy_key::#{calling_method}: Deploy key does not currently exist as specified in calling resource block."
    return false
  end

  def get_project_id
    return resource[:project_id].to_i unless resource[:project_id].nil?

    if resource[:project_name].nil?
      raise(Puppet::Error, "gitlab_deploy_key::#{calling_method}: Must provide at least one of the following attributes: project_id or project_name")
    end

    project_name = resource[:project_name].strip.gsub('/','%2F')

    url = "#{gms_server}/api/#{api_version}/projects/#{project_name}"

    begin
      response = api_call('GET', url)
      return JSON.parse(response.body)['id'].to_i
    rescue Exception => e
      fail(Puppet::Error, "gitlab_deploy_key::#{calling_method}: #{e.message}")
      return nil
    end

  end

  def get_key_id
    project_id = get_project_id

    keys_hash = Hash.new

    url = "#{gms_server}/api/#{api_version}/projects/#{project_id}/#{keys_endpoint}"

    response = api_call('GET', url)

    keys_json = JSON.parse(response.body)

    keys_json.each do |child|
      keys_hash[child['key']] = child['id']
    end

    keys_hash.each do |k,v|
      if k.eql?(File.read(resource[:path]).strip)
        return v.to_i
      end
    end

    raise(Puppet::Error, "gitlab_deploy_key::#{calling_method}: Unable to find nonexistent project ID \'#{resource[:project_name].strip}\' to retrieve corresponding key ID")
    return nil
  end

  def create
    project_id = get_project_id

    url = "#{gms_server}/api/#{api_version}/projects/#{project_id}/#{keys_endpoint}"

    begin
      response = api_call('POST', url, {'title' => resource[:name].strip, 'key' => File.read(resource[:path].strip)})

      if (response.class == Net::HTTPCreated)
        return true
      else
        raise(Puppet::Error, "gitlab_deploy_key::#{calling_method}: #{response.inspect}")
      end
    rescue Exception => e
      raise(Puppet::Error, "gitlab_deploy_key::#{calling_method}: #{e.message}")
    end
  end

  def destroy
    project_id = get_project_id

    key_id = get_key_id

    unless key_id.nil?

      url = "#{gms_server}/api/#{api_version}/projects/#{project_id}/#{keys_endpoint}/#{key_id}"

      begin
        response = api_call('DELETE', url)

        if response.class == Net::HTTPOK
          return true
        else
          raise(Puppet::Error, "gitlab_deploy_key::#{calling_method}: #{response.inspect}")
        end
      rescue Exception => e
        raise(Puppet::Error, "gitlab_deploy_key::#{calling_method}: #{e.message}")
      end

    end
  end

end
