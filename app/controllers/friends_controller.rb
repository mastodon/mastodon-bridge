# frozen_string_literal: true

require 'twitter'

class FriendsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_friends, only: :index
  before_action :set_top_instances, only: :index
  before_action :set_relationships, if: -> { current_user&.mastodon }

  rescue_from Twitter::Error do |e|
    redirect_to root_path, alert: "Twitter error: #{e}"
  end

  def index; end

  private

  def set_friends
    @friends = User.where(id: Authorization.where(provider: :twitter, uid: twitter_friend_ids).map(&:user_id))
                   .includes(:authorizations)
                   .reject { |user| user.mastodon.nil? }
                   .map { |user| fetch_account_id(user) }
  end

  def set_top_instances
    @top_instances = @friends.collect { |user| user&.mastodon&.uid }
                             .compact
                             .map { |uid| uid.split('@').last }
                             .inject(Hash.new(0)) { |h, k| h[k] += 1; h }
                             .sort_by { |k, v| -v }
                             .map { |k, _| fetch_instance_info(k) }
                             .compact
  end

  def twitter_friend_ids
    Rails.cache.fetch("#{current_user.id}/twitter-friends", expires_in: 15.minutes) { current_user.twitter_client.friend_ids.to_a }
  end

  def fetch_instance_info(host)
    Rails.cache.fetch("instance:#{host}", expires_in: 1.week) { Oj.load(HTTP.get("https://#{host}/api/v1/instance").to_s, mode: :strict) }
  rescue HTTP::Error, OpenSSL::SSL::SSLError, Oj::ParseError
    nil
  end

  def fetch_account_id(user)
    user.tap do |user|
      begin
        user.relative_account_id = Rails.cache.fetch("#{current_user.id}/#{current_user.mastodon.domain}/#{user.mastodon.uid}", expires_in: 1.week) do
          account, _ = current_user.mastodon_client.perform_request(:get, '/api/v1/accounts/search', q: user.mastodon.uid, resolve: 'true', limit: 1)
          next if account.nil?
          account['id']
        end
      rescue Mastodon::Error, HTTP::Error, OpenSSL::SSL::SSLError
        user.relative_account_id = nil
      end
    end
  end

  def set_relationships
    account_map = @friends.map { |user| [user.relative_account_id, user] }.to_h
    account_ids = @friends.collect { |user| user.relative_account_id }.compact
    param_str   = account_ids.map { |id| "id[]=#{id}" }.join('&')

    current_user.mastodon_client.perform_request(:get, "/api/v1/accounts/relationships?#{param_str}").each do |relationship|
      account_map[relationship['id']].following = relationship['following']
    end
  rescue Mastodon::Error, HTTP::Error, OpenSSL::SSL::SSLError
    nil
  end
end
