class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:twitter, :mastodon]

  has_many :authorizations

  def twitter
    @twitter ||= authorizations.find_by(provider: :twitter)
  end

  def mastodon
    @mastodon ||= authorizations.find_by(provider: :mastodon)
  end

  class << self
    def from_omniauth(auth, current_user)
      authorization = Authorization.where(provider: auth.provider, uid: auth.uid.to_s).first_or_initialize
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
