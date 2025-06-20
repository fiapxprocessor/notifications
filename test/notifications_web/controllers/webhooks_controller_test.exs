defmodule NotificationsWeb.WebhooksControllerTest do
  use NotificationsWeb.ConnCase, async: true

  alias Notifications.Repo
  alias Notifications.Persistence.Webhooks.Webhook

  @webhook_url "https://example.com/webhook"

  describe "POST /api/webhooks" do
    test "creates a webhook with valid data", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      conn =
        post(conn, "/api/webhooks", %{
          "endpoint" => @webhook_url,
          "user_id" => user_id
        })

      assert %{"data" => data} = json_response(conn, 201)
      assert data["endpoint"] == @webhook_url
      assert data["user_id"] == user_id

      assert Repo.get_by(Webhook, user_id: user_id)
    end
  end

  describe "GET /api/webhooks?user_id=..." do
    test "returns list of webhooks for a given user", %{conn: conn} do
      user_id = Ecto.UUID.generate()

      {:ok, webhook} =
        Repo.insert(%Webhook{
          endpoint: @webhook_url,
          user_id: user_id
        })

      conn = get(conn, "/api/webhooks", %{"user_id" => user_id})

      assert %{"data" => [item]} = json_response(conn, 200)
      assert item["id"] == webhook.id
      assert item["endpoint"] == webhook.endpoint
    end

    test "returns empty list when no webhooks found", %{conn: conn} do
      conn = get(conn, "/api/webhooks", %{"user_id" => Ecto.UUID.generate()})
      assert %{"data" => []} = json_response(conn, 200)
    end
  end
end
