defmodule NotificationsWeb.Jsons.WebhooksJson do
  def render("index.json", %{webhooks: webhooks}) do
    %{data: Enum.map(webhooks, &webhook_json/1)}
  end

  def render("show.json", %{webhook_event: webhook}) do
    %{data: webhook_json(webhook)}
  end

  defp webhook_json(webhook) do
    %{
      id: webhook.id,
      endpoint: webhook.endpoint,
      user_id: webhook.user_id,
      inserted_at: webhook.inserted_at
    }
  end
end
