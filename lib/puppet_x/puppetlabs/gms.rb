require 'net/http'
require 'json'

module PuppetX
  module Puppetlabs

    class Gms < Puppet::Provider

      def self.gms_server
        # Provide the host and port portion of the URL to calling methods
        provider = cm(caller[0])
        return 'https://api.github.com' if provider =~ /github/i
        return 'https://gitlab.com'     if provider =~ /gitlab/i
        return 'http://localhost:7990'  if provider =~ /stash/i
      end

      def self.cm(method)
        cm = method.split("/").last
        cm = cm.split('.').first
      end

      def self.calling_method
        # Get calling method and clean it up for good reporting
        cm = String.new
        cm = caller[0].split(" ").last
        cm.tr!('\'', '')
        cm.tr!('\`','')
        cm
      end

      def gms_server
        self.class.gms_server
      end

      def calling_method
        self.class.calling_method
      end

      def rest_call(action, url, token, provider, data)
        self.class.rest_call(action, url, token, provider, data)
      end

      def self.provider(cm)
        cm.split('/').last.split('.').first
      end

      def self.post(url, token, data=nil)
        if url =~ URI::regexp
          begin
            self.rest_call('POST', url, token, provider(caller[0]), data)
          rescue Exception => e
            fail("puppet_x::puppetlabs::gms.post: Error caught on POST: #{e}")
          end
        else
          fail("puppet_x::puppetlabs::gms.post: Must supply a valid URL including GMS server hostname/address.")
        end
      end

      def self.put(url, token, data=nil)
        if url =~ URI::regexp
          begin
            self.rest_call('PUT', url, token, provider(caller[0]), data)
          rescue Exception => e
            fail("puppet_x::puppetlabs::gms.put: Error caught on PUT: #{e}")
          end
        else
          fail("puppet_x::puppetlabs::gms.put: Must supply a valid URL including GMS server hostname/address.")
        end
      end

      def self.patch(url, token, data=nil)
        if url =~ URI::regexp
          begin
            self.rest_call('PATCH', url, token, provider(caller[0]), data)
          rescue Exception => e
            fail("puppet_x::puppetlabs::gms.put: Error caught on PATCH: #{e}")
          end
        else
          fail("puppet_x::puppetlabs::gms.patch: Must supply a valid URL including GMS server hostname/address.")
        end
      end

      def self.delete(url, token, data=nil)
        if url =~ URI::regexp
          begin
            self.rest_call('DELETE', url, token, provider(caller[0]), data)
          rescue Exception => e
            fail("puppet_x::puppetlabs::gms.delete: Error caught on DELETE: #{e}")
          end
        else
          fail("puppet_x::puppetlabs::gms.delete: Must supply a valid URL including GMS server hostname/address.")
        end
      end

      def self.get(url, token, data=nil)
        if url =~ URI::regexp
          begin
            self.rest_call('GET', url, token, provider(caller[0]), data)
          rescue Exception => e
            fail("puppet_x::puppetlabs::gms.get: Error caught on GET: #{e}")
          end
        else
          fail("puppet_x::puppetlabs::gms.get: Must supply a valid URL including GMS server hostname/address.")
        end
      end

      def self.rest_call(action, url, token, provider, data)
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
        elsif action =~ /patch/i
          req = Net::HTTP::Patch.new(uri.request_uri)
        elsif action =~ /put/i
          req = Net::HTTP::Put.new(uri.request_uri)
        elsif action =~ /delete/i
          req = Net::HTTP::Delete.new(uri.request_uri)
        else
          req = Net::HTTP::Get.new(uri.request_uri)
        end

        if provider =~ /github/i

          req.initialize_http_header({'Accept' => 'application/vnd.github.v3+json', 'User-Agent' => 'puppet-gms'})
          req.set_content_type('application/json')

          if token && ! token.empty?
            req.add_field('Authorization', "token #{token}")
          elsif @token_file && ! @token_file.empty? && File.exist?(@token_file)
            req.add_field('Authorization', "token #{File.read(@token_file).strip}")
          elsif ENV['GMS_TOKEN']
            req.add_field('Authorization', "token #{ENV['GMS_TOKEN'].strip}")
          else
            fail("puppet_x::puppetlabs::gms: Must supply GMS_TOKEN environment variable.")
          end

        elsif provider =~ /gitlab/i
          req.set_content_type('application/json')
          req.add_field('PRIVATE-TOKEN', ENV['GMS_TOKEN'].strip)
        elsif provider =~ /stash/i
          req.set_content_type('application/json')
          req.basic_auth(resource[:username].strip, ENV['GMS_TOKEN'].strip)
        end

        req.body = data if data && valid_json?(data)

        Puppet.debug("gms_webhook::#{calling_method}: REST API #{req.method} Endpoint: #{uri.to_s}")
        Puppet.debug("gms_webhook::#{calling_method}: REST API #{req.method} Request: #{req.inspect}")

        response = http.request(req)

        Puppet.debug("gms_webhook::#{calling_method}: REST API #{req.method} Response: #{response.inspect}")

        if req.method == 'GET'
          return JSON.parse(response.body)
        else
          return response
        end
      end

      def self.url_to_project_name(url)
        pn_array = url.split('/')
        pn = pn_array[4] + '/' + pn_array[5]
        return pn
      end

      def sanitize_hash(params, input_hash)
        input_hash.each_key do |key|
          input_hash.delete(key) unless params.include?(key)
        end

        return input_hash
      end

      def nest_hash_keys(keys_to_rename, nest_hash, rename_hash)
        rename_hash[nest_hash] = Hash.new if rename_hash[nest_hash].nil?

        keys_to_rename.each do |k, v|
          next if rename_hash[nest_hash][k]
          value = rename_hash[k]
          rename_hash.delete(k)
          if value
            rename_hash[nest_hash][v] = value unless rename_hash[nest_hash][v] == value
          end
        end

        return rename_hash
      end

      def rename_keys(keys_to_rename, rename_hash)
        keys_to_rename.each do |k, v|
          next unless rename_hash[k]
          value = rename_hash[k]
          rename_hash.delete(k)
          rename_hash[v] = value
        end
        return rename_hash
      end

      def self.valid_json?(json)
        JSON.parse(json)
        return true
      rescue Exception => e
        fail("gms_webhook::#{calling_method}: Unable to parse parameters passed in from gms_webhook module as valid JSON: #{e.message}")
        return false
      end

    end
  end
end
