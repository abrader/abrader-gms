require 'puppet'
require 'net/http'
require 'json'

Puppet::Type.type(:git_webhook).provide(:github) do
  
  defaultfor :github => :exist
  defaultfor :feature => :posix

  def gms_server
    # Provide the host and port portion of the URL to calling methods
    return resource[:server_url].strip unless resource[:server_url].nil?
    return 'https://api.github.com'
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
    # Single method to make all calls to the respective RESTful API
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

    req.initialize_http_header({'Accept' => 'application/vnd.github.v3+json', 'User-Agent' => 'puppet-gms'})
    req.set_content_type('application/json')
    req.add_field('Authorization', "token #{resource[:token].strip}")

    if data
      req.body = data.to_json
    end

    Puppet.debug("github_webhook::#{calling_method}: REST API #{req.method} Endpoint: #{uri.to_s}")
    Puppet.debug("github_webhook::#{calling_method}: REST API #{req.method} Request: #{req.inspect}")

    response = http.request(req)
    
    Puppet.debug("github_webhook::#{calling_method}: REST API #{req.method} Response: #{response.inspect}")
    
    response
  end

  def exists?
    webhook_hash = Hash.new
    url = "#{gms_server}/repos/#{resource[:project_name].strip}/hooks"

    response = api_call('GET', url)
    webhook_json = JSON.parse(response.body)

    webhook_json.each do |child|
      webhook_hash[child['config']['url']] = child['id']
    end

    webhook_hash.keys.each do |k|
      if k.eql?(resource[:webhook_url].strip)
        Puppet.debug "github_webhook::#{calling_method}: Webhook already exists as specified in calling resource block."
        return true
      end
    end
    
    Puppet.debug "github_webhook::#{calling_method}: Webhook does not currently exist as specified in calling resource block."
    return false
  end

  def get_project_id
    return resource[:project_id].to_i unless resource[:project_id].nil?

    if resource[:project_name].nil?
      raise(Puppet::Error, "github_webhook::#{calling_method}: Must provide at least one of the following attributes: project_id or project_name")
    end

    project_name = resource[:project_name].strip

    url = "#{gms_server}/repos/#{project_name}"

    begin
      response = api_call('GET', url)
      return JSON.parse(response.body)['id'].to_i 
    rescue Exception => e
      fail(Puppet::Error, "github_webhook::#{calling_method}: #{e.backtrace}")
      return nil
    end

  end

  def get_webhook_id
    webhook_hash = Hash.new

    url = "#{gms_server}/repos/#{resource[:project_name]}/hooks"

    response = api_call('GET', url)

    webhook_json = JSON.parse(response.body)

    webhook_json.each do |child|
      webhook_hash[child['config']['url']] = child['id']
    end

    webhook_hash.each do |k,v|
      if k.eql?(resource[:webhook_url].strip)
        return v.to_i
      end
    end

    return nil
  end
    
  def create
    url = "#{gms_server}/repos/#{resource[:project_name].strip}/hooks"

    begin
      config_opts = { 'url' => resource[:webhook_url].strip, 'content_type' => 'json' }
      
      if resource.disable_ssl_verify?
        if resource[:disable_ssl_verify] == true
          config_opts['insecure_ssl'] = 1
        else
          config_opts['insecure_ssl'] = 0
        end
      end
      
      response = api_call('POST', url, { 'name' => 'web', 'active' => true, 'config' => config_opts })

      if response.class == Net::HTTPCreated
        return true
      else
        raise(Puppet::Error, "github_webhook::#{calling_method}: #{response.inspect}")
      end
    rescue Exception => e
      raise(Puppet::Error, "github_webhook::#{calling_method}: #{e.message}")
    end
  end

  def destroy
    webhook_id = get_webhook_id

    unless webhook_id.nil?
      url = "#{gms_server}/repos/#{resource[:project_name].strip}/hooks/#{webhook_id}"

      begin
        response = api_call('DELETE', url)

        if (response.class == Net::HTTPNoContent)
          return true
        else
          raise(Puppet::Error, "github_webhook::#{calling_method}: #{response.inspect}")
        end
      rescue Exception => e
        raise(Puppet::Error, "github_webhook::#{calling_method}: #{e.message}")
      end

    end
  end

end


