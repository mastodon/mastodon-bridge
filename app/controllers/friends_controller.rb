# frozen_string_literal: true

require 'twitter'

class FriendsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_page
  before_action :set_friends
  before_action :set_top_instances
  before_action :set_next_page
  before_action :paginate_friends
  before_action :set_relationships, if: -> { current_user&.mastodon }

  rescue_from Twitter::Error do |e|
    redirect_to root_path, alert: "Twitter error: #{e}"
  end

  PER_PAGE_FRIENDS = 20
  MAX_INSTANCES    = 20
  MIN_INSTANCES    = 4

  def index; end

  private

  def set_page
    @page = (params['page'] || 1).to_i
  end

  def set_next_page
    @next_page = @friends.size > (@page * PER_PAGE_FRIENDS) ? @page + 1 : nil
  end

  def set_friends
    @friends = User.where(id: Authorization.where(provider: :twitter, uid: twitter_friend_ids).map(&:user_id))
                   .includes(:twitter, :mastodon)
                   .reject { |user| user.mastodon.nil? }
  end

  def set_top_instances
    @top_instances = friends_domains.map { |k, _| fetch_instance_info(k) }.compact
  end

  def paginate_friends
    @friends = @friends.slice([(@page - 1) * PER_PAGE_FRIENDS, @friends.size].min, PER_PAGE_FRIENDS)
                       .map { |user| fetch_account_id(user) }
  end

  def friends_domains
    return default_domains.sample(MIN_INSTANCES) if @friends.empty?

    @friends.collect { |user| user&.mastodon&.uid }
            .compact
            .map { |uid| uid.split('@').last }
            .inject(Hash.new(0)) { |h, k| h[k] += 1; h }
            .sort_by { |k, v| -v }
            .take(MAX_INSTANCES)
  end

  def default_domains
    %w(
      octodon.social
      mastodon.art
      niu.moe
      todon.nl
      soc.ialis.me
      scifi.fyi
      hostux.social
      mstdn.maud.io
      mastodon.sdf.org
      x0r.be
      toot.cafe
    )
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
      next if current_user.mastodon.nil?

      begin
        user.relative_account_id = Rails.cache.fetch("#{current_user.id}/#{current_user.mastodon.domain}/#{user.mastodon.uid}", expires_in: 1.week) do
          account, _ = current_user.mastodon_client.perform_request(:get, '/api/v1/accounts/search', q: user.mastodon.uid, resolve: 'true', limit: 1)
          next if account.nil?
          account['id']
        end
      rescue Mastodon::Error, HTTP::Error, OpenSSL::SSL::SSLError
        next
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
