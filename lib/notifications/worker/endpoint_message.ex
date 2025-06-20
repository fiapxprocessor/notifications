defmodule Notifications.Worker.EndpointMessage do
  @middleware [
    {Tesla.Middleware.JSON, []},
    {Tesla.Middleware.Logger, []}
  ]

  def client do
    Tesla.client(@middleware)
  end

  @spec send_webhook(map(), String.t()) :: {:ok, Tesla.Env.t()} | {:error, any()}
  def send_webhook(data, endpoint) do
    client()
    |> Tesla.post(endpoint, data)
  end
end
