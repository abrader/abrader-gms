require 'puppet'
require 'net/http'
require 'json'
require 'puppet_x/gms/provider'

Puppet::Type.type(:git_groupteam).provide(:gitlab) do
  include PuppetX::GMS::Provider

  defaultfor :gitlab => :exists

  def gms_server
    return resource[:server_url].strip unless resource[:server_url].nil?
    return 'https://gitlab.com'
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

    Puppet.debug("gitlab_groupteam::#{calling_method}: REST API #{req.method} Endpoint: #{uri.to_s}")
    Puppet.debug("gitlab_groupteam::#{calling_method}: REST API #{req.method} Request: #{req.inspect}")

    response = http.request(req)

    Puppet.debug("gitlab_groupteam::#{calling_method}: REST API #{req.method} Response: #{response.inspect}")

    response
  end

  def exists?
    groupteam_hash = Hash.new
    url = "#{gms_server}/api/v4/groups"

    response = api_call('GET', url)

    groupteam_json = JSON.parse(response.body)

    groupteam_json.each do |child|
      groupteam_hash[child['name']] = child['description']
    end

    groupteam_hash.each do |k,v|
      if k.eql?(resource[:groupteam_name].strip)
        unless (v.nil? && resource[:description].nil?) || (v && resource[:description]) && v.eql?(resource[:description].strip)
          destroy()
          Puppet.debug "gitlab_groupteam::#{calling_method}: Group \'#{resource[:name]}\' exists but not as resource block indicates.  Recreating..."
          return false
        end
        Puppet.debug "gitlab_groupteam::#{calling_method}: Group \'#{resource[:name]}\' already exists"
        return true
      end
    end

    Puppet.debug "gitlab_groupteam::#{calling_method}: Group \'#{resource[:name]}\' does not currently exist"
    return false
  end

  def get_group_id
    group_hash = Hash.new

    url = "#{gms_server}/api/v4/groups"

    response = api_call('GET', url)

    group_json = JSON.parse(response.body)

    group_json.each do |child|
      group_hash[child['name']] = child['id']
    end

    group_hash.each do |k,v|
      if k.eql?(resource[:groupteam_name].strip)
        return v.to_i
      end
    end

    raise(Puppet::Error, "gitlab_groupteam_member::#{calling_method}: Unable to find nonexistent group \'#{resource[:groupteam_name].strip}\'")
    return nil
  end

  def create
    url = "#{gms_server}/api/v4/groups"

    begin
      opts = { 'name' => resource[:groupteam_name].strip, 'path' => resource[:groupteam_name].strip }

      unless resource[:description].nil?
        opts['description'] = resource[:description].strip
      end

      Puppet.debug("opts => #{opts.inspect}")

      response = api_call('POST', url, opts)

      if (response.class == Net::HTTPCreated)
        return true
      else
        raise(Puppet::Error, "gitlab_groupteam::#{calling_method}: #{response.inspect}")
      end
    rescue Exception => e
      raise(Puppet::Error, "gitlab_groupteam::#{calling_method}: #{e.message}")
    end
  end

  def destroy
    group_id = get_group_id

    unless group_id.nil?
      url = "#{gms_server}/api/v4/groups/#{group_id}"

      begin
        response = api_call('DELETE', url)

        if response.class == Net::HTTPOK
          return true
        else
          raise(Puppet::Error, "gitlab_groupteam::#{calling_method}: #{response.inspect}")
        end
      rescue Exception => e
        raise(Puppet::Error, "gitlab_groupteam::#{calling_method}: #{e.message}")
      end

    end
  end

end


