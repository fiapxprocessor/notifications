defmodule Notifications.Persistence.Webhooks do
  import Ecto.Query, warn: false
  alias Notifications.Repo

  alias Notifications.Persistence.Webhooks.Webhook

  def list_webhook_events do
    Repo.all(Webhook)
  end

  def get_webhook_event!(id), do: Repo.get!(Webhook, id)

  def get_webhook_event_by_user(user_id) do
    {:ok, Repo.get_by(Webhook, user_id: user_id)}
  end

  def create_webhook_event(attrs \\ %{}) do
    %Webhook{}
    |> Webhook.changeset(attrs)
    |> Repo.insert()
  end

  def update_webhook_event(%Webhook{} = webhook_event, attrs) do
    webhook_event
    |> Webhook.changeset(attrs)
    |> Repo.update()
  end

  def delete_webhook_event(%Webhook{} = webhook_event) do
    Repo.delete(webhook_event)
  end

  def change_webhook_event(%Webhook{} = webhook_event, attrs \\ %{}) do
    Webhook.changeset(webhook_event, attrs)
  end

  def list_webhook_events_by_user(user_id) do
    Webhook
    |> where([w], w.user_id == ^user_id)
    |> Repo.all()
  end
end
