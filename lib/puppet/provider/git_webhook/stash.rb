require 'puppet'
require 'net/http'
require 'json'
#require 'base64'

Puppet::Type.type(:git_webhook).provide(:stash) do

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
    if resource[:repo_name].nil?
      missing_params << 'repo_name'
    end
    if resource[:hook_exe].nil?
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

    Puppet.debug("stash_webhook::#{calling_method}: REST API #{req.method} Endpoint: #{uri.to_s}")
    Puppet.debug("stash_webhook::#{calling_method}: REST API #{req.method} Request: #{req.inspect}")

    response = http.request(req)

    Puppet.debug("stash_webhook::#{calling_method}: REST API #{req.method} Response: #{response.inspect}")

    response
  end

  def exists?
    # Checks to see if the webhook exists on the Stash server
    prereq_check()

    pn = resource[:project_name].strip
    rs = resource[:repo_name].strip

    webhook_hash = Hash.new
    url = "#{gms_server}/rest/api/1.0/projects/#{pn}/repos/#{rs}/settings/hooks"

    response = api_call('GET', url)

    webhook_json = JSON.parse(response.body)

    webhook_json.each do |children|
      children.each do |child|
        if child.class == Array
          child.each do |hook|
            if hook['details'].key?('key') && hook['details']['key'] == 'com.ngs.stash.externalhooks.external-hooks:external-post-receive-hook' #&& hook['configured'] == true
              url = "#{gms_server}/rest/api/1.0/projects/#{pn}/repos/#{rs}/settings/hooks/com.ngs.stash.externalhooks.external-hooks:external-post-receive-hook/settings"
              Puppet.debug "stash_webhook::#{calling_method}: External post receive commit hook exists, checking for similarities..."
              response = api_call('GET', url)

              if response.class == Net::HTTPNoContent
                Puppet.debug("stash_webhook::#{calling_method}: External post receive hook is not configured.")
                return false
              end

              exe_json = JSON.parse(response.body)

              resource[:hook_exe] = '' if resource[:hook_exe].nil?
              resource[:hook_exe_params] = '' if resource[:hook_exe_params].nil?

              exe_check = nil
              params_check = nil

              if exe_json['exe'] == resource[:hook_exe].strip
                exe_check = true
              else
                exe_check = false
              end

              if exe_json['params'] == resource[:hook_exe_params].strip
                params_check = true
              else
                params_check = false
              end

              if hook.key?('enabled')
                if resource[:ensure].to_s == 'present' && hook['enabled'] == false
                  return false
                elsif resource[:ensure].to_s == 'absent' && hook['enabled'] == true
                  return true
                elsif resource[:ensure] == :present && hook['enabled'] == true
                  return true
                else
                  return false
                end
              end

              if exe_check && params_check
                Puppet.debug "stash_webhook::#{calling_method}: Confirmed external post receive hook exists in defined state already."
                return true
              else
                Puppet.debug "stash_webhook::#{calling_method}: External post receive hook has differing data from parameters passed in resource."
                return false
              end
            end
          end
        end
      end
    end

    raise(Puppet::Error, "stash_webhook::#{calling_method}: External Async Post Receive Hook does not appear to be installed on your Stash server.  This is required for the git_webhook resource to work on Stash servers.")
  end

  def create
    # Creates a webhook in the Stash repository referenced.
    pn = resource[:project_name].strip
    rs = resource[:repo_name].strip

    url = "#{gms_server}/rest/api/1.0/projects/#{pn}/repos/#{rs}/settings/hooks/com.ngs.stash.externalhooks.external-hooks:external-post-receive-hook/settings"

    begin
      opts = Hash.new

      unless resource[:hook_exe_params].nil?
        opts = { 'exe' => resource[:hook_exe].strip, 'params' => resource[:hook_exe_params].strip }
      else
        opts = { 'exe' => resource[:hook_exe].strip }
      end

      response = api_call('PUT', url, opts)

      raise(Puppet::Error, "stash_webhook::#{calling_method}: #{response.inspect}") if (response.class != Net::HTTPOK)
    rescue Exception => e
      raise(Puppet::Error, "stash_webhook::#{calling_method}: #{e.message}")
    end

    enable()
  end

  def enable
    # Enabled a webhook in the Stash repository referenced.
    pn = resource[:project_name].strip
    rs = resource[:repo_name].strip

    begin
      url = "#{gms_server}/rest/api/1.0/projects/#{pn}/repos/#{rs}/settings/hooks/com.ngs.stash.externalhooks.external-hooks:external-post-receive-hook/enabled"

      response = api_call('PUT', url)

      if response.class == Net::HTTPOK
        Puppet.debug "stash_webhook::#{calling_method}: External post receive hook now enabled."
        return true
      else
        raise(Puppet::Error, "stash_webhook::#{calling_method}: #{response.inspect}")
      end
    rescue Exception => e
      raise(Puppet::Error, e.message)
    end
  end

  def disable
    # Disable a webhook in the Stash repository referenced.
    pn = resource[:project_name].strip
    rs = resource[:repo_name].strip

    begin
      url = "#{gms_server}/rest/api/1.0/projects/#{pn}/repos/#{rs}/settings/hooks/com.ngs.stash.externalhooks.external-hooks:external-post-receive-hook/enabled"

      response = api_call('DELETE', url)

      if response.class == Net::HTTPOK
        Puppet.debug "stash_webhook::#{calling_method}: External post receive hook now disabled."
        return true
      else
        raise(Puppet::Error, "stash_webhook::#{calling_method}: #{response.inspect}")
      end
    rescue Exception => e
      raise(Puppet::Error, e.message)
    end
  end

  def destroy
    # Renders the webhook unusable.
    disable()
  end

end


