class AddClientTokenToMastodonClients < ActiveRecord::Migration[5.1]
  def change
    add_column :mastodon_clients, :client_token, :string
  end
end
