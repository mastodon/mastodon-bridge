# frozen_string_literal: true

class Authorization < ApplicationRecord
  belongs_to :user, inverse_of: :authorizations, required: true

  default_scope { order('id asc') }

  def info
    return @info if defined?(@info)

    if provider == 'mastodon'
      @info  = Rails.cache.fetch("mastodon-user:#{uid}", expires_in: 1.day) do
        client = Mastodon::REST::Client.new(base_url: "https://#{uid.split('@').last}", bearer_token: token)
        client.verify_credentials.attributes
      end
    else
      @info = nil
    end
  end
end
