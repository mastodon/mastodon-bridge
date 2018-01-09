# frozen_string_literal: true

class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:twitter, :mastodon]

  has_many :authorizations

  attr_accessor :relative_account_id, :following

  def twitter
    @twitter ||= authorizations.where(provider: :twitter).last
  end

  def twitter_client
    return if twitter.nil?

    @twitter_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CLIENT_ID']
      config.consumer_secret     = ENV['TWITTER_CLIENT_SECRET']
      config.access_token        = twitter.token
      config.access_token_secret = twitter.secret
    end
  end

  def mastodon
    @mastodon ||= authorizations.where(provider: :mastodon).last
  end

  def mastodon_client
    return if mastodon.nil?

    @mastodon_client ||= Mastodon::REST::Client.new(base_url: "https://#{mastodon.domain}", bearer_token: mastodon.token)
  end

  class << self
    def from_omniauth(auth, current_user)
      authorization = Authorization.where(provider: auth.provider, uid: auth.uid.to_s).first_or_initialize(provider: auth.provider, uid: auth.uid.to_s)
      user = current_user || authorization.user || User.new
      authorization.user   = user
      authorization.token  = auth.credentials.token
      authorization.secret = auth.credentials.secret

      if auth.provider == 'twitter'
        authorization.profile_url  = auth.info.urls['Twitter']
        authorization.display_name = auth.info.nickname
      elsif auth.provider == 'mastodon'
        authorization.profile_url  = auth.info.urls['Profile']
        authorization.display_name = auth.info.nickname
      end

      authorization.save
      authorization.user
    end
  end
end
