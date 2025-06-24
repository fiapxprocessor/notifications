defmodule Notifications.Persistence.WebhooksTest do
  use Notifications.DataCase, async: true

  alias Notifications.Persistence.Webhooks
  alias Notifications.Persistence.Webhooks.Webhook

  describe "webhook events" do
    @valid_attrs %{
      endpoint: "https://example.com/webhook",
      user_id: Ecto.UUID.generate()
    }

    @update_attrs %{
      endpoint: "https://example.com/updated"
    }

    @invalid_attrs %{endpoint: nil, event_type: nil}

    setup do
      {:ok, webhook} = Webhooks.create_webhook_event(@valid_attrs)
      %{webhook: webhook}
    end

    test "list_webhook_events/0 returns all webhook events", %{webhook: webhook} do
      result = Webhooks.list_webhook_events()
      assert length(result) == 1
      assert Enum.any?(result, fn w -> w.id == webhook.id end)
    end

    test "get_webhook_event!/1 returns the webhook with given id", %{webhook: webhook} do
      assert Webhooks.get_webhook_event!(webhook.id).id == webhook.id
    end

    test "get_webhook_event_by_user/1 returns the webhook by user_id", %{webhook: webhook} do
      assert {:ok, result} = Webhooks.get_webhook_event_by_user(webhook.user_id)
      assert result.id == webhook.id
    end

    test "create_webhook_event/1 with valid data creates a webhook" do
      valid_attrs = %{
        endpoint: "https://example.com/webhook2",
        user_id: Ecto.UUID.generate()
      }

      assert {:ok, %Webhook{} = webhook} = Webhooks.create_webhook_event(valid_attrs)
      assert webhook.endpoint == valid_attrs.endpoint
    end

    test "create_webhook_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Webhooks.create_webhook_event(@invalid_attrs)
    end

    test "update_webhook_event/2 with valid data updates the webhook", %{webhook: webhook} do
      updated_attrs = %{endpoint: "https://example.com/changed"}
      {:ok, updated_webhook} = Webhooks.update_webhook_event(webhook, updated_attrs)
      assert updated_webhook.endpoint == "https://example.com/changed"
    end

    test "update_webhook_event/2 with invalid data returns error changeset", %{webhook: webhook} do
      assert {:error, %Ecto.Changeset{}} = Webhooks.update_webhook_event(webhook, @invalid_attrs)
    end

    test "delete_webhook_event/1 deletes the webhook", %{webhook: webhook} do
      {:ok, _deleted} = Webhooks.delete_webhook_event(webhook)

      assert_raise Ecto.NoResultsError, fn ->
        Webhooks.get_webhook_event!(webhook.id)
      end
    end

    test "change_webhook_event/2 returns a valid changeset", %{webhook: webhook} do
      changeset = Webhooks.change_webhook_event(webhook, %{endpoint: "https://new.url"})
      assert changeset.valid?
      assert changeset.changes.endpoint == "https://new.url"
    end

    test "list_webhook_events_by_user/1 returns webhooks for user", %{webhook: webhook} do
      result = Webhooks.list_webhook_events_by_user(webhook.user_id)
      assert length(result) == 1
      assert hd(result).id == webhook.id
    end
  end
end
