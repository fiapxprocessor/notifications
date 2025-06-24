defmodule Notifications.Persistence.Webhooks.Webhook do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "webhooks" do
    field :endpoint, :string
    field :user_id, :binary_id

    timestamps()
  end

  def changeset(webhook_event, attrs) do
    webhook_event
    |> cast(attrs, [:endpoint, :user_id])
    |> validate_required([:endpoint, :user_id])
    |> unique_constraint([:user_id], name: :user_id_index)
  end
end
