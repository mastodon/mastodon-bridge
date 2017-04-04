class HomeController < ApplicationController
  def index
    @twitter_count  = Authorization.where(provider: :twitter).count
    @mastodon_count = Authorization.where(provider: :mastodon).count
    @has_twitter    = user_signed_in? && !current_user.twitter.nil?
    @has_mastodon   = user_signed_in? && !current_user.mastodon.nil?
  end
end
