require_relative '../../../puppet_x/puppetlabs/gms.rb'
require 'puppet_x/gms/provider'
require 'puppet/type/gms_webhook'
require 'json'

Puppet::Type.type(:gms_webhook).provide(:gitlab, :parent => PuppetX::Puppetlabs::Gms) do
  include PuppetX::GMS::Provider

  defaultfor :gitlab => :exist

  has_feature :id
  has_feature :name
  has_feature :rest_url
  has_feature :project_name
  has_feature :push_events
  has_feature :issues_events
  has_feature :merge_requests_events
  has_feature :tag_push_events
  has_feature :note_events
  has_feature :build_events
  has_feature :pipeline_events
  has_feature :wiki_events
  has_feature :created_at
  has_feature :webhook_url

  def self.instances
    Puppet.debug("def self.instances")

    instances = []

    repos_url = "#{gms_server}/api/v4/projects"
    repos = get(repos_url, @token)

    webhooks = Array.new
    hooks = Hash.new

    repos.each do |r|

      # hooks_url = "#{gms_server}/projects/#{r['id']}/hooks"
      hooks_url = "#{gms_server}/api/v4/projects/#{r['id']}/hooks"

      hook_objs = get(hooks_url, @token)

      return [] if hook_objs.nil?

      #   Puppet.notice("hook_objs = #{hook_objs.inspect}")

      hook_objs.each do |h|
        h['project_name'] = r['path_with_namespace'] if h.class == Hash
        h['repo_url']  = hooks_url + "/#{h['id']}" if h.class == Hash && !r['id'].nil?

        h['insecure_ssl'] = :false if h['enable_ssl_verification'] == true
        h['insecure_ssl'] = :true  if h['enable_ssl_verification'] == false

        webhooks << h if h.class == Hash
      end

    end

    webhooks.each do |webhook|
      instances << new(
        ensure:                :present,
        name:                  webhook['project_name'] + '_' + webhook['id'].to_s,
        id:                    webhook['id'].to_s,
        rest_url:              webhook['repo_url'],
        project_name:          webhook['project_name'],
        push_events:           webhook['push_events'],
        issues_events:         webhook['issues_events'],
        merge_requests_events: webhook['merge_requests_events'],
        tag_push_events:       webhook['tag_push_events'],
        note_events:           webhook['note_events'],
        build_events:          webhook['build_events'],
        pipeline_events:       webhook['pipeline_events'],
        wiki_page_events:      webhook['wiki_page_events'],
        updated_at:            webhook['updated_at'],
        created_at:            webhook['created_at'],
        insecure_ssl:          webhook['insecure_ssl'],
        webhook_url:           webhook['url']
      )
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
      end
    end
  end

  def message(object)
    Puppet.debug("def message")
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.

    message = object.to_hash

    if message[:insecure_ssl] == :true
      message[:enable_ssl_verification] = false
    elsif message[:insecure_ssl] == :false
      message[:enable_ssl_verification] = true
    end

    if message[:webhook_url]
      message[:url] = message[:webhook_url]
      # message.delete(:webhook)
    end

    gitlab_params = [:id, :url, :push_events, :issues_events, :merge_requests_events, :tag_push_events, :note_events, :build_events, :pipeline_events, :wiki_page_events, :enable_ssl_verification]
    message = sanitize_hash(gitlab_params, message)

    message.to_json
  end

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

  def get_project_id(project_name)
    begin
      repos_url = "#{self.gms_server}/api/v4/projects"
      repos = PuppetX::Puppetlabs::Gms.get(repos_url, get_token)

      repos.each do |r|
        if project_name == r['path_with_namespace']
          return r['id']
        end
      end
    rescue Exception => e
      raise(Puppet::Error, "gms_gitlab_webhook::#{calling_method}: Unable to retrieve project ID given project name: #{e.message}")
    end
  end

  def exists?
    Puppet.debug("def exists #{self.id}")
    @property_hash[:ensure] == :present
  end

  def flush
    Puppet.debug("def flush")

    put_url = "#{gms_server}/api/v4/projects/#{get_project_id(resource[:project_name].strip)}/hooks/#{self.id}"

    if @property_hash != {}
      begin
        response = PuppetX::Puppetlabs::Gms.put(put_url, get_token, message(@property_hash))

        if response.class != Net::HTTPOK
          raise(Puppet::Error, "gms_gitlab_webhook::#{calling_method}: #{response.inspect}")
        end
      rescue Exception => e
        raise(Puppet::Error, "gms_gitlab_webhook::#{calling_method}: #{e.message}")
      end

      return response
    end
  end

  def create
    Puppet.debug('def create')

    begin
      post_url = "#{self.gms_server}/api/v4/projects/#{get_project_id(resource[:project_name].strip)}/hooks"

      response = PuppetX::Puppetlabs::Gms.post(post_url, get_token, message(resource))

      if response.class != Net::HTTPCreated
        raise(Puppet::Error, "gms_gitlab_webhook::#{calling_method}: #{response.inspect}")
        return false
      end

      @property_hash.clear

      return response
    rescue Exception => e
      raise(Puppet::Error, "gms_gitlab_webhook::#{calling_method}: #{e.message}")
      return false
    end

  end

  def destroy
    Puppet.debug("def destroy")

    unless webhook_id.nil?
      destroy_url = "#{gms_server}/api/v4/projects/#{get_project_id(resource[:project_name].strip)}/hooks/#{self.id}"

      begin
        response = PuppetX::Puppetlabs::Gms.delete(destroy_url, get_token)

        if (response.class == Net::HTTPNoContent)
          return true
        else
          raise(Puppet::Error, "gitlab_webhook::#{calling_method}: #{response.inspect}")
        end
      rescue Exception => e
        raise(Puppet::Error, "gitlab_webhook::#{calling_method}: #{e.message}")
      end

    end
  end

  mk_resource_methods

end
