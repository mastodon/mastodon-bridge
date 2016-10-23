require 'twitter'

class FriendsController < ApplicationController
  before_action :authenticate_user!

  def index
    fetch_twitter_followees
    fetch_related_mastodons
  end

  def follow
    user = User.find(params[:id])
    mastodon_uid = user.authorizations.find_by(provider: :mastodon).uid
    mastodon_client.follow_by_uri(mastodon_uid)
    redirect_to friends_path, notice: "Successfully followed #{mastodon_uid} from your Mastodon account"
  end

  private

  def fetch_twitter_followees
    @twitter_friend_ids = Rails.cache.fetch("#{current_user.id}/twitter-friends", expires_in: 1.minute) do
      twitter_client.friend_ids
    end
  end

  def fetch_related_mastodons
    @friends = User.where(id: Authorization.where(provider: :twitter, uid: @twitter_friend_ids.to_a).pluck(:user_id)).includes(:authorizations)
  end

  def twitter_client
    @twitter_client ||= Twitter::REST::Client.new do |config|
      authorization = current_user.authorizations.find_by(provider: :twitter)

      config.consumer_key        = ENV['TWITTER_CLIENT_ID']
      config.consumer_secret     = ENV['TWITTER_CLIENT_SECRET']
      config.access_token        = authorization.try(:token)
      config.access_token_secret = authorization.try(:secret)
    end
  end

  def mastodon_client
    authorization = current_user.authorizations.find_by(provider: :mastodon)
    _, domain = authorization.uid.split('@')
    @mastodon_client ||= Mastodon::REST::Client.new(base_url: "https://#{domain}", bearer_token: authorization.token)
  end
end
