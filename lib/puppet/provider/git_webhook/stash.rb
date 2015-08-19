require 'puppet'
require 'net/http'
require 'json'
require 'base64'

Puppet::Type.type(:git_webhook).provide(:stash) do

  defaultfor :stash => :exists

  def gms_server
    return resource[:server_url].strip unless resource[:server_url].nil?
    return 'http://localhost:7990'
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

    Puppet.debug(http.set_debug_output($stdout))

    if action =~ /post/i
      req = Net::HTTP::Post.new(uri.request_uri)
    elsif action =~ /put/i
      req = Net::HTTP::Put.new(uri.request_uri)
    elsif action =~ /delete/i
      req = Net::HTTP::Delete.new(uri.request_uri)
    else
      req = Net::HTTP::Get.new(uri.request_uri)
    end

    enc = Base64.encode64("#{resource[:username].strip}:#{resource[:password].strip}")

    req.set_content_type('application/json')
    req.basic_auth(resource[:username].strip, resource[:password].strip)

    if data
      req.body = data.to_json
    end
    
    Puppet.debug("REST API Endpoint: #{uri.to_s}")
    Puppet.debug("Request: #{req.inspect}")

    response = http.request(req)
    
    Puppet.debug("Response: #{response.inspect}")
    
    response
  end

  def exists?
    pn = resource[:project_name].strip
    rs = resource[:repo_name].strip
    
    webhook_hash = Hash.new
    url = "#{gms_server}/rest/api/1.0/projects/#{pn}/repos/#{rs}/settings/hooks"

    response = api_call('GET', url)
    
    Puppet.debug("API call response: #{response.class}")

    webhook_json = JSON.parse(response.body)
    
    webhook_json.each do |children|
      children.each do |child|
        if child.class == Array
          child.each do |hook|
            if hook['details']['key'] == 'com.ngs.stash.externalhooks.external-hooks:external-post-receive-hook' && hook['configured'] == true
              url = "#{gms_server}/rest/api/1.0/projects/#{pn}/repos/#{rs}/settings/hooks/com.ngs.stash.externalhooks.external-hooks:external-post-receive-hook/settings"
              Puppet.debug "Found a external post commit hook!"
              response = api_call('GET', url)
              
              exec_json = JSON.parse(response.body)
              
              exec_check = nil
              params_check = nil
              
              if exec_json['params'].empty? && (resource[:hook_exec_params].nil? || resource[:hook_exec_params].empty?)
                params_check  = true
              end
              
              if exec_json['exe'] == resource[:hook_exec].strip && params_check
                Puppet.debug 'stash_webhook: Confirmed webhook exists already. Nothing to be done.'
                return true
              else
                Puppet.debug 'stash_webhook: Webhook differs from parameters passed in resource. Going to fix that now.'
                return false
              end
            end
          end
        end
      end
    end
    
    raise(Puppet::Error, "stash_webhook: It does not appear you have the External Async Post Receive Hook installed on your Stash server.  This is required for the git_webhook resource to work on Stash servers.")

    return false
  end

  def get_project_id
    return resource[:project_id].to_i unless resource[:project_id].nil?

    if resource[:project_name].nil?
      raise(Puppet::Error, "stash_webhook: Must provide at least one of the following attributes: project_id or project_name")
    end

    project_name = resource[:project_name].strip.sub('/','%2F')

    url = "#{gms_server}/api/v3/projects/#{project_name}"

    begin
      response = api_call('GET', url)
      return JSON.parse(response.body)['id'].to_i 
    rescue Exception => e
      fail(Puppet::Error, "stash_webhook: #{e.message}")
      return nil
    end

  end

  def get_webhook_id
    project_id = get_project_id

    webhook_hash = Hash.new

    url = "#{gms_server}/api/v3/projects/#{project_id}/hooks"

    response = api_call('GET', url)

    webhook_json = JSON.parse(response.body)

    webhook_json.each do |child|
      webhook_hash[child['url']] = child['id']
    end

    webhook_hash.each do |k,v|
      if k.eql?(resource[:webhook_url].strip)
        return v.to_i
      end
    end

    return nil
  end
    
  def create
    project_id = get_project_id

    url = "#{gms_server}/api/v3/projects/#{project_id}/hooks"
    
    begin
      opts = { 'url' => resource[:webhook_url].strip }
      
      if resource.merge_request_events?
        opts['merge_requests_events'] = resource[:merge_request_events]
      end

      if resource.tag_push_events?
        opts['tag_push_events'] = resource[:tag_push_events]
      end
      
      if resource.issue_events?
        opts['issues_events'] = resource[:issue_events]
      end
      
      response = api_call('POST', url, opts)

      if (response.class == Net::HTTPCreated)
        return true
      else
        raise(Puppet::Error, "stash_webhook: #{response.inspect}")
      end
    rescue Exception => e
      raise(Puppet::Error, e.message)
    end
  end

  def destroy
    project_id = get_project_id

    webhook_id = get_webhook_id

    unless webhook_id.nil?
      url = "#{gms_server}/api/v3/projects/#{project_id}/hooks/#{webhook_id}"

      begin
        response = api_call('DELETE', url)

        if (response.class == Net::HTTPOK)
          return true
        else
          raise(Puppet::Error, "stash_webhook: #{response.inspect}")
        end
      rescue Exception => e
        raise(Puppet::Error, e.message)
      end

    end
  end

end


