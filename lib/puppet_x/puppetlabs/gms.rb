require 'net/http'
require 'json'

module PuppetX
  module Puppetlabs
    
    class Gms < Puppet::Provider
  
      def gms_server
        # Provide the host and port portion of the URL to calling methods
        return resource[:server_url].strip unless resource[:server_url].nil?
        return 'https://api.github.com' if resource[:provider] =~ /github/i
        return 'https://gitlab.com'     if resource[:provider] =~ /gitlab/i
        return 'http://localhost:7990'  if resource[:provider] =~ /stash/i
      end
  
      def calling_method
        # Get calling method and clean it up for good reporting
        cm = String.new
        cm = caller[0].split(" ").last
        cm.tr!('\'', '')
        cm.tr!('\`','')
        cm
      end
      
      def rest_call(action, url, data=nil)
        self.class.rest_call(action, url, data=nil)
      end

      def self.rest_call(action,url,data = nil)
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

        if resource[:provider] =~ /github/i
          req.initialize_http_header({'Accept' => 'application/vnd.github.v3+json', 'User-Agent' => 'puppet-gms'})
          req.set_content_type('application/json')
          req.add_field('Authorization', "token #{resource[:token].strip}")
        elsif resource[:provider] =~ /gitlab/i
          req.set_content_type('application/json')
          req.add_field('PRIVATE-TOKEN', resource[:token].strip)
        elsif resource[:provider] =~ /stash/i
          req.set_content_type('application/json')
          req.basic_auth(resource[:username].strip, resource[:password].strip)
        end 
      
        if data
          req.body = data.to_json
        end

        Puppet.debug("gms_webhook::#{calling_method}: REST API #{req.method} Endpoint: #{uri.to_s}")
        Puppet.debug("gms_webhook::#{calling_method}: REST API #{req.method} Request: #{req.inspect}")

        response = http.request(req)
    
        Puppet.debug("gms_webhook::#{calling_method}: REST API #{req.method} Response: #{response.inspect}")
    
        response
      end
  
      def valid_json?(json)
        JSON.parse(json)
        return true
      rescue
        return false
      end
    
    end
  end
end

