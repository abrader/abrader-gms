require 'puppet'
require 'net/http'
require 'json'

Puppet::Type.type(:git_add_user_to_project).provide(:gitlab) do

  def create_url(action,url_params)
    if action =~ /post/i
      req = req = Net::HTTP::Post.new(url_params)
    elsif action =~ /put/i
      req = Net::HTTP::Put.new(url_params)
    elsif action =~ /delete/i
      req = Net::HTTP::Delete.new(url_params)
    else
      req = Net::HTTP::Get.new(url_params)
    end

    req.set_content_type('application/json') 
    req.add_field('PRIVATE-TOKEN', resource[:token])
    req
  end

  def exists?
    project_id = get_project_id
    user_id = get_user_id

    uri = URI.parse("https://gitlab.com/api/v3/projects/#{project_id}/members/#{user_id}")
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.port = 443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    #http.set_debug_output($stdout)

    req = create_url('GET', uri.request_uri)

    response = http.request(req)

    users_json = JSON.parse(response.body)
    puts users_json.class
    if users_json.has_key?('message')
      if users_json['message'] = '404 Not found'
        return false
      end
    else
      return true
    end

    return false
  end

  def get_user_id
    return resource[:user_id].to_i unless resource[:project_id].nil?

    if resource[:username].nil?
      raise(Puppet::Error, "gitlab_add_user_to_project: Must provide at least one of the following attributes: user_id or user_name") 
    end

    users_hash = Hash.new
    username = resource[:username].strip

    uri = URI.parse("https://gitlab.com/api/v3/users")
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.port = 443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    http.set_debug_output($stdout)

    req = create_url('GET', uri.request_uri)

    response = http.request(req)

    users_json = JSON.parse(response.body)
    puts users_json
    users_json.each do |child|
      users_hash[child['key']] = child['id']
    end

    users_hash.each do |k,v|
      if k.eql?(username)
        return v.to_i
      end
    end

    return false
  end

  def get_project_id
    return resource[:project_id].to_i unless resource[:project_id].nil?

    if resource[:project_name].nil?
      raise(Puppet::Error, "gitlab_add_user_to_project: Must provide at least one of the following attributes: project_id or project_name")
    end

    project_name = resource[:project_name].strip.sub('/','%2F')

    uri = URI.parse("https://gitlab.com/api/v3/projects/#{project_name}")
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.port = 443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    req = create_url('GET', uri.request_uri)

    #http.set_debug_output($stdout)

    response = http.request(req)

    return JSON.parse(response.body)['id'].to_i 
  end

  def get_key_id
    project_id = get_project_id

    sshkey_hash = Hash.new

    uri = URI.parse("https://gitlab.com/api/v3/projects/#{project_id}/keys")
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.port = 443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    req = create_url('GET', uri.request_uri)

    response = http.request(req)

    keys_json = JSON.parse(response.body)

    keys_json.each do |child|
      sshkey_hash[child['key']] = child['id']
    end

    sshkey_hash.each do |k,v|
      if k.eql?(File.read(resource[:path]).strip)
        return v.to_i
      end
    end

    return nil
  end
    
  def create
    project_id = get_project_id
    user_id = get_user_id

    uri = URI.parse("https://gitlab.com/api/v3/projects/#{project_id}/members/#{user_id}")
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.port = 443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    http.set_debug_output($stdout)

    req = create_url('POST', uri.request_uri)

    req.set_form_data({'user_id' => user_id, 'access_level' => resource[:access_level].to_i})

    begin
      response = http.request(req)

      if (response.class == Net::HTTPCreated)
        return true
      else
        raise(Puppet::Error, "gitlab_add_user_to_project: #{response.inspect}")
      end
    rescue Exception => e
      raise(Puppet::Error, e.message)
    end
  end

  def destroy
    project_id = get_project_id
    user_id = get_user_id

    unless user_id.nil?
      uri = URI.parse("https://gitlab.com/api/v3/projects/#{project_id}/members/#{user_id}")

      http = Net::HTTP.new(uri.host, uri.port)

      if uri.port = 443
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      #http.set_debug_output($stdout)

      req = create_url('DELETE', uri.request_uri)

      begin
        response = http.request(req)

        if (response.class == Net::HTTPOK)
          return true
        else
          raise(Puppet::Error, "gitlab_deploy_key: #{response.inspect}")
        end
      rescue Exception => e
        raise(Puppet::Error, e.message)
      end

    end
  end

end


