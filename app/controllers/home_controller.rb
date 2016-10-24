class HomeController < ApplicationController
  def index
    @twitter_count  = Authorization.where(provider: :twitter).count
    @mastodon_count = Authorization.where(provider: :mastodon).count
  end
end
