defmodule Notifications.Broadway.BroadwayMessage do
  use Broadway

  require Logger
  alias Broadway.Message
  alias Notifications.Persistence.Webhooks
  alias Notifications.Broadway.ProcessMessage

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayKafka.Producer,
           [
             hosts: [kafka: 29092],
             group_id: "group_1",
             topics: ["notifications"],
             offset_reset_policy: :earliest,
             reconnect_timeout: 10_000
           ]},
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 10
        ]
      ],
      batchers: [
        default: [
          batch_size: 10,
          batch_timeout: 200,
          concurrency: 10
        ]
      ]
    )
  end

  @impl true
  def handle_message(_, %Message{} = message, _) do
    with message <- Message.update_data(message, fn data -> Jason.decode!(data) end),
         {:ok, endpoint} <-
           Webhooks.get_webhook_event_by_user(
             message.data["user_id"]
           ),
         {:ok, message_update} <-
           update_message_endpoint(message, endpoint) do
      message_update
    end
  end

  @impl true
  def handle_batch(:default, messages, _batch_info, _context) do
    messages_count = length(messages)
    Logger.info("Handling #{messages_count} messages")
    ProcessMessage.message(messages)
    messages
  end

  @impl true
  def handle_failed(messages, _context) do
    messages
  end

  defp update_message_endpoint(message, webhook) do
    %{endpoint: endpoint} = webhook
    %{metadata: %{ts: ts}, data: data} = message
    time_spent_kafka = DateTime.to_unix(DateTime.utc_now(), :millisecond) - ts

    Logger.info("Message from #{data["user_id"]} took #{time_spent_kafka} ms on kafka")

    message_update =
      message
      |> Message.update_data(fn data ->
        Map.put(data, "endpoint", endpoint)
      end)

    {:ok, message_update}
  end
end
