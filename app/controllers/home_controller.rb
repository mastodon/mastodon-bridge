# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @twitter_count  = Rails.cache.fetch('total_twitter_count', expires_in: 15.minutes)  { Authorization.where(provider: :twitter).count }
    @mastodon_count = Rails.cache.fetch('total_mastodon_count', expires_in: 15.minutes) { Authorization.where(provider: :mastodon).count }
  end
end
