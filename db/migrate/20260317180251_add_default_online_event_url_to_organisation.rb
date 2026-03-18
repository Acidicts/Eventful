class AddDefaultOnlineEventUrlToOrganisation < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :default_online_event_url, :string, default: "https://eventful.bing-bong.uk"
  end
end
