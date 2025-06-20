defmodule NotificationsWeb.Jsons.ErrorJson do
  def error(%{reason: reason}) do
    %{errors: reason}
  end

  def error(%{changeset: reason}) do
    %{errors: reason}
  end
end
