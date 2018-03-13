require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'gms_webhook',
  docs: <<-EOS,
      This type provides Puppet with the capabilities to manage ...
    EOS
  features: [],
  attributes:   {
    ensure:      {
      type:    'Enum[present, absent]',
      desc:    'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    name:        {
      type:      'String',
      desc:      'The name of the resource you want to manage.',
      behaviour: :read_only,
    },
    id:          {
      type:      'Variant[Pattern[/\A(0x)?[0-9a-fA-F]{8}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{16}\Z/], Pattern[/\A(0x)?[0-9a-fA-F]{40}\Z/]]',
      desc:      'The ID of the webhook you want to manage.',
      behaviour: :namevar,
    },
    url:      {
      type:      'Pattern[/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/]',
      desc:      'The Git Management URL to fetch the webhook based on the ID.',
      behaviour: :read_only,
    },
    test_url:      {
      type:      'Pattern[/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/]',
      desc:      'The Git Management URL to test the webhook based on the ID.',
      behaviour: :read_only,
    },
    ping_url:      {
      type:      'Pattern[/\A((hkp|http|https):\/\/)?([a-z\d])([a-z\d-]{0,61}\.)+[a-z\d]+(:\d{2,5})?$/]',
      desc:      'The Git Management URL to ping the webhook based on the ID.',
      behaviour: :read_only,
    },
    events:        {
      type:      'Array[String]',
      desc:      'Events that can trigger the webhook',
    },
    active:        {
      type:      'Boolean',
      desc:      'Setting for if the webhook is currently activated',
    },
    config:        {
      type:      'Hash',
      desc:      'Configuration settings such as the URL to trigger and the content type',
    },
    updated_at:    {
      type:      'String',
      desc:      'Indication of when the webhook was last updated',
      behaviour: :read_only,
    },
    created_at:    {
      type:      'String',
      desc:      'Indication of when the webhook was created',
      behaviour: :read_only,
    },
  },
)
