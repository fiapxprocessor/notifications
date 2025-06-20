defmodule Notifications.Repo.Migrations.CreatesWebhooksTable do
  use Ecto.Migration

  def change do
    create table(:webhooks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :endpoint, :string, null: false
      add :user_id, :uuid, null: false

      timestamps()
    end

    create unique_index(:webhooks, [:endpoint], name: :webhooks_endpoint_index)
    create index(:webhooks, [:user_id])
  end
end
