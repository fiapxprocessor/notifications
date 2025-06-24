defmodule Notifications.Worker.WorkerMessageTest do
  use Notifications.DataCase, async: true
  use Oban.Testing, repo: Notifications.Repo

  import Tesla.Mock
  import ExUnit.CaptureLog

  alias Notifications.Worker.WorkerMessage

  @moduletag :capture_log

  setup do
    :ok
  end

  test "returns :success_send when webhook returns 200" do
    mock(fn
      %Tesla.Env{method: :post, url: "http://example.com/webhook"} ->
        {:ok, %Tesla.Env{status: 200, body: %{"ok" => true}}}
    end)

    job_args = %{
      "endpoint" => "http://example.com/webhook",
      "user_id" => user_id = Ecto.UUID.generate(),
      "event_type" => "processed_video"
    }

    log =
      capture_log(fn ->
        assert {:ok, :success_send} == perform_job(WorkerMessage, job_args)
      end)

    assert log =~ "Success send message to http://example.com/webhook"
    assert log =~ user_id
    assert log =~ "processed_video"
  end

  test "returns :not_send when webhook returns 500" do
    mock(fn
      %Tesla.Env{method: :post, url: "http://example.com/webhook"} ->
        {:ok, %Tesla.Env{status: 500, body: "Internal Server Error"}}
    end)

    job_args = %{
      "endpoint" => "http://example.com/webhook",
      "user_id" => Ecto.UUID.generate(),
      "event_type" => "processed_video"
    }

    log =
      capture_log(fn ->
        assert {:error, :not_send} == perform_job(WorkerMessage, job_args)
      end)

    assert log =~ "Cant send message status: 500"
  end

  test "returns :no_scheme when endpoint is invalid" do
    mock(fn
      %Tesla.Env{method: :post, url: "invalid"} ->
        {:error, {:no_scheme}}
    end)

    job_args = %{
      "endpoint" => "invalid",
      "user_id" => Ecto.UUID.generate(),
      "event_type" => "processed_video"
    }

    log =
      capture_log(fn ->
        assert {:error, :no_scheme} == perform_job(WorkerMessage, job_args)
      end)

    assert log =~ "Cant send message {:error, :no_scheme}"
  end

  test "returns :nxdomain when domain does not resolve" do
    mock(fn
      %Tesla.Env{method: :post, url: "http://nonexistent.domain"} ->
        {:error, :nxdomain}
    end)

    job_args = %{
      "endpoint" => "http://nonexistent.domain",
      "user_id" => Ecto.UUID.generate(),
      "event_type" => "processed_video"
    }

    log =
      capture_log(fn ->
        assert {:error, :nxdomain} == perform_job(WorkerMessage, job_args)
      end)

    assert log =~ "Cant send message {:error, :nxdomain}"
  end

  test "returns :undefined when unexpected error happens" do
    mock(fn
      %Tesla.Env{method: :post, url: "http://example.com/webhook"} ->
        {:error, :timeout}
    end)

    job_args = %{
      "endpoint" => "http://example.com/webhook",
      "user_id" => Ecto.UUID.generate(),
      "event_type" => "processed_video"
    }

    log =
      capture_log(fn ->
        assert {:error, :undefined} == perform_job(WorkerMessage, job_args)
      end)

    assert log =~ "Cant send message at attempt"
    assert log =~ ":timeout"
  end

  test "simulates retrying perform with failing webhook and logs each attempt" do
    mock(fn _ -> {:ok, %Tesla.Env{status: 500}} end)

    job_args = %{
      "endpoint" => "http://example.com/webhook",
      "user_id" => Ecto.UUID.generate(),
      "event_type" => "processed_video"
    }

    log =
      capture_log(fn ->
        result_1 =
          WorkerMessage.perform(%Oban.Job{
            args: job_args,
            attempt: 1,
            inserted_at: DateTime.utc_now()
          })

        assert result_1 == {:error, :not_send}

        result_2 =
          WorkerMessage.perform(%Oban.Job{
            args: job_args,
            attempt: 2,
            inserted_at: DateTime.utc_now()
          })

        assert result_2 == {:error, :not_send}
      end)

    assert log =~ "Cant send message status: 500, attempt: 1"
    assert log =~ "Cant send message status: 500, attempt: 2"
  end
end
