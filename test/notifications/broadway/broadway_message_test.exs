defmodule Notifications.Broadway.BroadwayMessageTest do
  use ExUnit.Case, async: true
  use Oban.Testing, repo: Notifications.Repo

  import Tesla.Mock

  alias Broadway.Message
  alias Notifications.Broadway.BroadwayMessage
  alias Notifications.Persistence.Webhooks

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Notifications.Repo)

    # cria um user_id válido
    user_id = Ecto.UUID.generate()

    # insere um webhook no banco para esse user_id
    {:ok, webhook} =
      Webhooks.create_webhook_event(%{
        user_id: user_id,
        endpoint: "http://example.com/webhook"
      })

    # retorna o user_id para o teste usar
    {:ok, user_id: user_id, webhook: webhook}
  end

  describe "handle_message/3" do
    test "enriches message with endpoint when webhook is found", %{user_id: user_id} do
      ts = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

      data = %{
        "user_id" => user_id,
        "event_type" => "processed_video",
        "video_id" => Ecto.UUID.generate()
      }

      message = %Message{
        data: Jason.encode!(data),
        metadata: %{ts: ts},
        acknowledger: {Broadway.NoopAcknowledger, :ack_data, :ack_opts},
        batcher: :default,
        batch_key: :default,
        status: :ok
      }

      updated_message = BroadwayMessage.handle_message(:default, message, %{})

      assert updated_message.data["user_id"] == user_id
      assert updated_message.data["endpoint"] == "http://example.com/webhook"
    end
  end

  describe "handle_batch/4" do
    test "calls ProcessMessage and logs batch size", %{user_id: user_id} do
      mock(fn
        %Tesla.Env{method: :post} ->
          {:ok, %Tesla.Env{status: 200, body: %{"ok" => true}}}
      end)

      ts = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

      data = %{
        "user_id" => user_id,
        "event_type" => "processed_video",
        "video_id" => Ecto.UUID.generate()
      }

      message = %Message{
        data: data,
        metadata: %{ts: ts},
        acknowledger: {Broadway.NoopAcknowledger, :ack_data, :ack_opts},
        batcher: :default,
        batch_key: :default,
        status: :ok
      }

      result = BroadwayMessage.handle_batch(:default, [message], %{}, %{})

      assert length(result) == 1
      assert result == [message]
    end
  end
end
