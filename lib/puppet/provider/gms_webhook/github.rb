require_relative '../../../puppet_x/puppetlabs/gms.rb'
require 'puppet_x/gms/provider'
require 'puppet/type/gms_webhook'
require 'json'

Puppet::Type.type(:gms_webhook).provide(:github, :parent => PuppetX::Puppetlabs::Gms) do
  include PuppetX::GMS::Provider

  defaultfor :github => :exist
  defaultfor :feature => :posix

  def self.instances
    Puppet.debug("def self.instances")

    instances = []

    repos_url = "#{gms_server}/user/repos"
    repos = get(repos_url, @token)

    webhooks = Array.new
    hooks = Hash.new

    repos.each do |r|

      hooks_url = r['hooks_url']
      hook_objs = get(hooks_url, @token)
      return [] if hook_objs.nil?

      hook_objs.each do |h|
        hooks[h['id']] = h['url'] if h.class == Hash && h[:message].nil?
        webhooks << h if h.class == Hash && h[:message].nil?
      end

    end

    webhooks.each do |webhook|

      if webhook['config']['insecure_ssl'] == '1' || webhook['config']['insecure_ssl'] == 'true'
        webhook['config']['insecure_ssl'] = :true
      else
        webhook['config']['insecure_ssl'] = :false
      end

      webhook['active'] = :true  if webhook['active'] == true
      webhook['active'] = :false if webhook['active'] == false

      # Build project_name parameter
      pn_array = webhook['url'].strip.split('/')
      pn = pn_array[4] + '/' + pn_array[5]

      instances << new(
        ensure:                :present,
        name:                  webhook['name'] + '_' + webhook['id'].to_s,
        id:                    webhook['id'].to_s,
        web:                   webhook['web'],
        rest_url:              webhook['url'],
        test_url:              webhook['test_url'],
        ping_url:              webhook['ping_url'],
        project_name:          pn,
        active:                webhook['active'],
        events:                webhook['events'],
        last_response_code:    webhook['last_response']['code'],
        last_response_status:  webhook['last_response']['status'],
        last_response_message: webhook['last_response']['message'],
        updated_at:            webhook['updated_at'],
        created_at:            webhook['created_at'],
        secret:                webhook['config']['secret'],
        insecure_ssl:          webhook['config']['insecure_ssl'],
        content_type:          webhook['config']['content_type'],
        webhook_url:           webhook['config']['url']
      )
      webhook.delete('config')
    end

    $webhooks = instances if $webhooks.nil? || $webhooks.empty?

    instances
  end

  def self.prefetch(resources)
    Puppet.debug("def self.prefetch")

    @token = resources[resources.keys.first].value('token')

    $webhooks = instances

    resources.keys.each do |name|
      if provider = $webhooks.find { |wh| wh.project_name == resources[name].parameters[:project_name].value && wh.webhook_url == resources[name].parameters[:webhook_url].value }
        resources[name].provider = provider
        # Assume the user wants the webhook to be active if they did not specify a value for the active property but ensure => true
        if resources[name].parameters[:ensure].value == :present && resources[name].parameters[:active].nil?
          resources[name][:active] = true
        end
      end
    end
  end

  def message(object)
    Puppet.debug("def message")
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.

    message = object.to_hash

    if message[:active] == :false
      message[:active] = false
    elsif message[:active] == :absent && message[:ensure] == :present
      message[:active] = true
    else
      message[:active] = true
    end

    message[:content_type] = 'json' if message[:content_type].nil?

    message[:events] = ['push'] if message[:events].nil?

    if message[:insecure_ssl] == :true || message[:insecure_ssl] == true
      message[:insecure_ssl] = '1'
    else message[:insecure_ssl] == :false
      message[:insecure_ssl] = '0'
    end

    # For now, we will only support setting up 'web' webhooks.  GitHub has a
    # list of many more types of webhooks that can be supported:
    # https://api.github.com/hooks
    message[:name] = 'web'

    config_map = {
      :'content_type'       => :content_type,
      :'insecure_ssl'       => :insecure_ssl,
      :'webhook_url'        => :url,
    }

    message = nest_hash_keys(config_map, :config, message)
    github_params = [:name, :config, :events, :active]
    message = sanitize_hash(github_params, message)

    message.to_json
  end

  # def get_webhook_id
  #   Puppet.debug("def get_webhook_id")
  #
  #   return self.id unless self.id == :absent || self.id.empty?
  #
  #   $webhooks.each do |wh|
  #     if resource[:project_name] == wh.project_name && resource[:webhook_url] == wh.webhook_url
  #       return wh.id
  #     end
  #   end
  #
  #   return nil
  # end

  def gms_server
    PuppetX::Puppetlabs::Gms::gms_server
  end

  def calling_method
    # Get calling method and clean it up for good reporting
    cm = String.new
    cm = caller[0].split(" ").last
    cm.tr!('\'', '')
    cm.tr!('\`','')
    cm
  end

  def exists?
    Puppet.debug("def exists #{self.id}")
    @property_hash[:ensure] == :present
  end

  def flush
    Puppet.debug("def flush")

    # resource[:project_name].strip
    patch_url = "#{gms_server}/repos/#{self.project_name}/hooks/#{self.id}"

    if @property_hash != {}
      begin
        response = PuppetX::Puppetlabs::Gms.patch(patch_url, get_token, message(@property_hash))

        if response.class != Net::HTTPOK
          raise(Puppet::Error, "github_webhook::#{calling_method}: #{response.inspect}")
        end
      rescue Exception => e
        raise(Puppet::Error, "github_webhook::#{calling_method}: #{e.message}")
      end

      return response
    end
  end

  def create
    Puppet.debug('def create')

    begin
      post_url = "#{self.gms_server}/repos/#{resource[:project_name].strip}/hooks"

      response = PuppetX::Puppetlabs::Gms.post(post_url, get_token, message(resource))

      if response.class != Net::HTTPCreated
        raise(Puppet::Error, "gms_github_webhook::#{calling_method}: #{response.inspect}")
        return false
      end

      @property_hash.clear

      return response
    rescue Exception => e
      raise(Puppet::Error, "gms_github_webhook::#{calling_method}: #{e.message}")
      return false
    end

  end

  def destroy
    Puppet.debug("def destroy")

    unless webhook_id.nil?
      destroy_url = "#{gms_server}/repos/#{resource[:project_name].strip}/hooks/#{self.id}"

      begin
        response = PuppetX::Puppetlabs::Gms.delete(destroy_url, get_token)

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

  mk_resource_methods

end
