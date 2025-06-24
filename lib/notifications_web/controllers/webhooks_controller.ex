defmodule NotificationsWeb.WebhooksController do
  use NotificationsWeb, :controller

  alias Notifications.Persistence.Webhooks, as: WebhooksControl
  alias Notifications.Persistence.Webhooks.Webhook

  action_fallback(NotificationsWeb.FallbackController)

  plug :put_view, json: NotificationsWeb.Jsons.WebhooksJson

  def create(conn, %{"endpoint" => endpoint, "user_id" => user_id}) do
    attrs = %{
      "endpoint" => endpoint,
      "user_id" => user_id
    }

    with {:ok, %Webhook{} = webhook_event} <- WebhooksControl.create_webhook_event(attrs) do
      conn
      |> put_status(:created)
      |> render("show.json", webhook_event: webhook_event)
    end
  end

  def index(conn, %{"user_id" => user_id}) do
    webhooks = WebhooksControl.list_webhook_events_by_user(user_id)

    render(conn, "index.json", webhooks: webhooks)
  end

  def delete(conn, %{"user_id" => user_id}) do
    with {:ok, %Webhook{} = webhook_event} <- WebhooksControl.get_webhook_event_by_user(user_id),
         {:ok, _} <- WebhooksControl.delete_webhook_event(webhook_event) do
      conn
      |> put_status(:ok)
      |> render("show.json", webhook_event: webhook_event)
    end
  end
end
