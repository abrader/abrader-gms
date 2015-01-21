require 'puppet'
require 'net/http'
require 'json'

Puppet::Type.type(:git_deploy_key).provide(:github) do

  defaultfor :github => :exist
  defaultfor :feature => :posix

  def git_server
    return resource[:server_url].strip unless resource[:server_url].nil?
    return 'https://gitlab.com'
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
    #req.add_field('PRIVATE-TOKEN', resource[:token])

    if data
      req.body = data.to_json
    end

    http.request(req)
  end

  def exists?
    key_hash = Hash.new
    url = "#{git_server}/repos/#{resource[:project_name].strip}/keys"

    response = api_call('GET', url)

    key_json = JSON.parse(response.body)
    
    key_json.each do |child|
      if child['key'].split(" ")[1].eql?(File.read(resource[:path].strip).split(" ")[1])
        return true
      end
    end

    return false
  end
  
  def get_key_id
    key_hash = Hash.new
    url = "#{git_server}/repos/#{resource[:project_name].strip}/keys"

    response = api_call('GET', url)

    key_json = JSON.parse(response.body)
    
    key_json.each do |child|
      if child['key'].split(" ")[1].eql?(File.read(resource[:path].strip).split(" ")[1])
        return child['id'].to_s
      end
    end

    return nil
  end

def create
    url = "#{git_server}/repos/#{resource[:project_name].strip}/keys"

    begin
      response = api_call('POST', url, {'title' => resource[:name].strip, 'key' => File.read(resource[:path].strip)})

      if (response.class == Net::HTTPCreated)
        return true
      else
        raise(Puppet::Error, "git_deploy_key: #{response.inspect}")
      end
    rescue Exception => e
      raise(Puppet::Error, e.message)
    end
  end

  def destroy
    key_id = get_key_id
    
    unless key_id.nil?
      url = "#{git_server}/repos/#{resource[:project_name].strip}/keys/#{key_id}"

      begin
        response = api_call('DELETE', url)

        if (response.class == Net::HTTPNoContent)
          return true
        else
          raise(Puppet::Error, "git_deploy_key: #{response.inspect}")
        end
      rescue Exception => e
        raise(Puppet::Error, e.message)
      end

    end
  end

end


