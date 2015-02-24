require 'puppet'
require 'net/http'
require 'json'

Puppet::Type.type(:git_webhook).provide(:github) do
  
  defaultfor :github => :exist
  defaultfor :feature => :posix

  def git_server
    return resource[:server_url].strip unless resource[:server_url].nil?
    return 'https://api.github.com'
  end

  def api_call(action,url,data = nil)
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)

    if uri.port == 443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    else
      http.use_ssl = false
    end

    #http.set_debug_output($stdout)

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
      #req.body = data[0].to_json
      req.body = data.to_json
    end

    http.request(req)
  end

  def exists?
    webhook_hash = Hash.new
    url = "#{git_server}/repos/#{resource[:project_name].strip}/hooks"

    response = api_call('GET', url)
    webhook_json = JSON.parse(response.body)

    webhook_json.each do |child|
      webhook_hash[child['config']['url']] = child['id']
    end

    webhook_hash.keys.each do |k|
      if k.eql?(resource[:webhook_url].strip)
        return true
      end
    end

    return false
  end

  def get_project_id
    return resource[:project_id].to_i unless resource[:project_id].nil?

    if resource[:project_name].nil?
      raise(Puppet::Error, "git_webhook: Must provide at least one of the following attributes: project_id or project_name")
    end

    project_name = resource[:project_name].strip

    url = "#{git_server}/repos/#{project_name}"

    begin
      response = api_call('GET', url)
      return JSON.parse(response.body)['id'].to_i 
    rescue Exception => e
      fail(Puppet::Error, "git_webhook: #{e.backtrace}")
      return nil
    end

  end

  def get_webhook_id
    #project_id = get_project_id

    webhook_hash = Hash.new

    url = "#{git_server}/repos/#{resource[:project_name]}/hooks"

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
    url = "#{git_server}/repos/#{resource[:project_name].strip}/hooks"

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

      if (response.class == Net::HTTPCreated)
        return true
      else
        raise(Puppet::Error, "git_webhook: #{response.inspect}")
      end
    rescue Exception => e
      raise(Puppet::Error, "#{e.message} &&&& #{e.backtrace}")
    end
  end

  def destroy
    webhook_id = get_webhook_id

    unless webhook_id.nil?
      url = "#{git_server}/repos/#{resource[:project_name].strip}/hooks/#{webhook_id}"

      begin
        response = api_call('DELETE', url)

        if (response.class == Net::HTTPNoContent)
          return true
        else
          raise(Puppet::Error, "git_webhook: #{response.inspect}")
        end
      rescue Exception => e
        raise(Puppet::Error, e.backtrace)
      end

    end
  end

end


