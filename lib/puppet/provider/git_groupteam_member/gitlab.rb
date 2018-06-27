require 'puppet'
require 'net/http'
require 'json'
require 'puppet_x/gms/provider'

Puppet::Type.type(:git_groupteam_member).provide(:gitlab) do
  include PuppetX::GMS::Provider

  defaultfor :gitlab => :exists

  GUEST     = 10
  REPORTER  = 20
  DEVELOPER = 30
  MASTER    = 40
  OWNER     = 50

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

    # Passing along the ability to see greater debugging output from net/http call
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

    Puppet.debug("gitlab_groupteam_member::#{calling_method}: REST API #{req.method} Endpoint: #{uri.to_s}")
    Puppet.debug("gitlab_groupteam_member::#{calling_method}: REST API #{req.method} Request: #{req.inspect}")

    response = http.request(req)

    Puppet.debug("gitlab_groupteam_member::#{calling_method}: REST API #{req.method} Response: #{response.inspect}")

    response
  end

  def exists?
    group_id = get_group_id

    groupteam_hash = Hash.new
    url = "#{gms_server}/api/v4//groups/#{group_id}/members"

    response = api_call('GET', url)

    groupteam_json = JSON.parse(response.body)

    groupteam_json.each do |child|
      groupteam_hash[child['username']] = child['id']
    end

    groupteam_hash.keys.each do |k|
      if k.eql?(resource[:member_name].strip)
        Puppet.debug "gitlab_groupteam_member::#{calling_method}: Member \'#{resource[:member_name]}\' is already a member of #{resource[:groupteam_name].strip}"
        return true
      end
    end

    Puppet.debug "gitlab_groupteam_member::#{calling_method}: Member \'#{resource[:member_name]}\' is not currently a member of #{resource[:groupteam_name].strip}"
    return false
  end

  def get_access_level
    unless resource[:access_level].nil?
      al = resource[:access_level].strip

      case al
      when /guest/i
        Puppet.debug("gitlab_groupteam_member::#{calling_method}:  Access Level = #{GUEST}")
        return GUEST
      when /reporter/i
        Puppet.debug("gitlab_groupteam_member::#{calling_method}:  Access Level = #{REPORTER}")
        return REPORTER
      when /developer/i
        Puppet.debug("gitlab_groupteam_member::#{calling_method}:  Access Level = #{DEVELOPER}")
        return DEVELOPER
      when /master/i
        Puppet.debug("gitlab_groupteam_member::#{calling_method}:  Access Level = #{MASTER}")
        return MASTER
      when /owner/i
        Puppet.debug("gitlab_groupteam_member::#{calling_method}:  Access Level = #{OWNER}")
        return OWNER
      else
        raise(Puppet::Error, "gitlab_groupteam_member::#{calling_method}: Access level provided \'#{al}\' is not GUEST, REPORTER, DEVELOPER, MASTER, or OWNER.")
        return nil
      end
    else
      raise(Puppet::Error, "gitlab_groupteam_member::#{calling_method}: Access level provided \'#{al}\' is not GUEST, REPORTER, DEVELOPER, MASTER, or OWNER.")
      return nil
    end
  end

  def get_group_id
    group_hash = Hash.new

    url = "#{gms_server}/api/v4/groups?search=#{resource[:groupteam_name].strip}"

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

  def get_user_id
    group_hash = Hash.new

    url = "#{gms_server}/api/v4/users?search=#{resource[:member_name].strip}"

    response = api_call('GET', url)

    group_json = JSON.parse(response.body)

    group_json.each do |child|
      group_hash[child['username']] = child['id']
    end

    group_hash.each do |k,v|
      if k.eql?(resource[:member_name].strip)
        return v.to_i
      end
    end

    raise(Puppet::Error, "gitlab_groupteam_member::#{calling_method}: Unable to add nonexistent user \'#{resource[:member_name].strip}\' to group #{resource[:groupteam_name].strip}")
    return nil
  end

  def create
    access_level = get_access_level
    group_id = get_group_id
    user_id  = get_user_id

    url = "#{gms_server}/api/v4//groups/#{group_id}/members"

    begin
      if access_level.nil? ||  group_id.nil? || user_id.nil?
        raise(Puppet::Error, "gitlab_groupteam_member::#{calling_method}: Cannot add member to group with values presented: user_id => #{user_id}, group_id => #{group_id}, and access_level => #{access_level}")
      else
        opts = { 'id' => group_id, 'user_id' => user_id, 'access_level' => access_level }
      end

      Puppet.debug("gitlab_groupteam_member::#{calling_method}: opts => #{opts.inspect}")

      response = api_call('POST', url, opts)

      if (response.class == Net::HTTPCreated)
        return true
      else
        raise(Puppet::Error, "gitlab_groupteam_member::#{calling_method}: #{response.inspect}")
      end
    rescue Exception => e
      raise(Puppet::Error, "gitlab_groupteam_member::#{calling_method}: #{e.message}")
    end
  end

  def destroy
    group_id = get_group_id
    user_id  = get_user_id

    unless group_id.nil?
      url = "#{gms_server}/api/v4//groups/#{group_id}/members/#{user_id}"

      begin
        response = api_call('DELETE', url)

        if response.class == Net::HTTPOK
          return true
        else
          raise(Puppet::Error, "gitlab_groupteam_member::#{calling_method}: #{response.inspect}")
        end
      rescue Exception => e
        raise(Puppet::Error, "gitlab_groupteam_member::#{calling_method}: #{e.message}")
      end

    end
  end

end


