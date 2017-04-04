class Authorization < ApplicationRecord
  belongs_to :user, inverse_of: :authorizations

  default_scope { order('id asc') }
end
