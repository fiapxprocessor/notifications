defmodule NotificationsWeb.Jsons.ChangesetJson do
  import NotificationsWeb.Jsons.ErrorHelpers

  @fields_translation [
    {:email, "email"},
    {:cpf, "cpf"},
    {:first_name, "first_name"},
    {:last_name, "last_name"},
    {:admin, "admin"}
  ]

  def translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end

  defp translate_fields(erros) do
    @fields_translation
    |> Enum.reduce(erros, fn {field, translated_field}, erros ->
      field_value = Map.get(erros, field)

      if field_value != nil do
        translated_erros =
          erros
          |> Map.put(translated_field, field_value)
          |> Map.delete(field)

        translated_erros
      else
        erros
      end
    end)
  end

  def error(%{changeset: changeset}) do
    erros =
      changeset
      |> translate_errors()
      |> translate_fields()

    %{errors: erros}
  end
end
