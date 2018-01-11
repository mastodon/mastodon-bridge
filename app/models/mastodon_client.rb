# frozen_string_literal: true

class MastodonClient < ApplicationRecord
  class << self
    def obtain!(domain, callback_url)
      new_client = Mastodon::REST::Client.new(base_url: "https://#{domain}").create_app('Mastodon Bridge', callback_url, 'read follow')
      client     = self.new(domain: domain)

      client.client_id     = new_client.client_id
      client.client_secret = new_client.client_secret

      client.save!
      client
    end
  end

  def client_token
    return attributes['client_token'] if attributes['client_token'].present?

    res = http_client.post("https://#{domain}/oauth/token", params: {
      grant_type: 'client_credentials',
      client_id: client_id,
      client_secret: client_secret,
    })

    info = Oj.load(res.to_s, mode: :null)

    return if info.nil?

    update!(client_token: info['access_token'])
    info['access_token']
  end

  def still_valid?
    return false if client_token.blank?

    res = http_client.get("https://#{domain}/api/v1/apps/verify_credentials", headers: { 'Authorization': "Bearer #{client_token}" })
    res.code == 200
  end

  private

  def http_client
    HTTP.timeout(:per_operation, connect: 2, read: 5, write: 5)
  end
end
