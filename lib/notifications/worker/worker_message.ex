defmodule Notifications.Worker.WorkerMessage do
  use Oban.Worker, max_attempts: 4, queue: :default

  require Logger

  alias Notifications.Worker.EndpointMessage

  @attempts %{
    "1" => 0,
    "2" => 7,
    "3" => 15,
    "4" => 60
  }

  @status 200..299

  @spec perform(Oban.Job.t()) ::
          {:error, :no_scheme | :not_send | :nxdomain} | {:ok, :success_send}
  @impl Oban.Worker
  def perform(%Oban.Job{
        args:
          %{
            "user_id" => user_id,
            "endpoint" => endpoint,
            "event_type" => event_type
          } = data,
        attempt: attempt
      }) do
    Logger.info(
      "Trying send message to #{endpoint}, from client: #{user_id} and event #{event_type} at attempt #{attempt}"
    )

    with {:ok, %Tesla.Env{status: status}} when status in @status <-
           EndpointMessage.send_webhook(data, endpoint) do
      Logger.info(
        "Success send message to #{endpoint} with status: #{status}, from client: #{user_id} and event #{event_type}, at attempt: #{attempt}"
      )

      {:ok, :success_send}
    else
      {:ok, %Tesla.Env{status: status}} ->
        Logger.error("Cant send message status: #{status}, attempt: #{attempt}")
        {:error, :not_send}

      {:error, {:no_scheme}} ->
        Logger.error("Cant send message {:error, :no_scheme}, attempt: #{attempt}")
        {:error, :no_scheme}

      {:error, :nxdomain} ->
        Logger.error("Cant send message {:error, :nxdomain}, attempt: #{attempt}")
        {:error, :nxdomain}

      error ->
        Logger.error("Cant send message at attempt: #{attempt}, with error: #{inspect(error)}")
        {:error, :undefined}
    end
  end

  @spec backoff(Oban.Job.t()) :: non_neg_integer()
  def backoff(%Oban.Job{attempt: attempt}) do
    Map.get(@attempts, Integer.to_string(attempt))
  end
end
