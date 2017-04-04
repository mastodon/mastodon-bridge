class AddMoreInfoToAuthorizations < ActiveRecord::Migration[5.0]
  def change
    add_column :authorizations, :profile_url, :string, null: false, default: ''
    add_column :authorizations, :display_name, :string, null: false, default: ''
  end
end
