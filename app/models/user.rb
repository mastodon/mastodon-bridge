class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:twitter, :mastodon]

  has_many :authorizations

  class << self
    def from_omniauth(auth, current_user)
      authorization = Authorization.where(provider: auth.provider, uid: auth.uid.to_s).first_or_initialize
      user = current_user || User.new
      authorization.user   = user
      authorization.token  = auth.credentials.token
      authorization.secret = auth.credentials.secret
      authorization.save
      authorization.user
    end
  end
end
