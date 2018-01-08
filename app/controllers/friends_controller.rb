# frozen_string_literal: true

require 'twitter'

class FriendsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_friends, only: :index
  before_action :set_top_instances, only: :index

  rescue_from Twitter::Error do |e|
    redirect_to root_path, alert: "Twitter error: #{e}"
  end

  def index; end

  private

  def set_friends
    @friends = User.where(id: Authorization.where(provider: :twitter, uid: twitter_friend_ids).map(&:user_id))
                   .includes(:authorizations)
                   .reject { |user| user.mastodon.nil? }
  end

  def set_top_instances
    @top_instances = @friends.collect { |user| user&.mastodon&.uid }
                             .compact
                             .map { |uid| uid.split('@').last }
                             .inject(Hash.new(0)) { |h, k| h[k] += 1; h }
                             .sort_by { |k, v| v }
                             .map { |k, _| fetch_instance_info(k) }
                             .compact
  end

  def twitter_friend_ids
    Rails.cache.fetch("#{current_user.id}/twitter-friends", expires_in: 15.minutes) { twitter_client.friend_ids.to_a }
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

  def fetch_instance_info(host)
    Rails.cache.fetch("instance:#{host}", expires_in: 1.week) { Oj.load(HTTP.get("https://#{host}/api/v1/instance").to_s, mode: :strict) }
  rescue HTTP::Error, OpenSSL::SSL::SSLError, Oj::ParseError
    nil
  end
end
