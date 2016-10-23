class Authorization < ApplicationRecord
  belongs_to :user, inverse_of: :authorizations
end
