require 'twitter'

class FriendsController < ApplicationController
  before_action :authenticate_user!

  def index
    fetch_twitter_followees
    fetch_related_mastodons
  end

  private

  def fetch_twitter_followees
    @twitter_friend_ids = twitter_client.friend_ids
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
end
