defmodule Notifications.Broadway.ProcessMessage do
  @spec message(List.t()) :: [Oban.Job.t()] | Ecto.Multi.t()
  def message(messages) do
    messages
    |> Enum.map(fn messages -> build_message(messages.data) end)
    |> Enum.map(fn message -> Notifications.Worker.WorkerMessage.new(message) end)
    |> Oban.insert_all()
  end

  defp build_message(data) do
    %{
      event_type: data["event_type"],
      message_id: data["message_id"],
      user_id: data["user_id"],
      endpoint: data["endpoint"]
    }
  end
end
