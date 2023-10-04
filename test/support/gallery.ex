defmodule Support.Gallery do
  use Swoosh.Gallery

  preview("/welcome", Support.Emails.WelcomeEmail)

  group "/auth", title: "Auth" do
    preview("/reset_password", Support.Emails.ResetPasswordEmail)
  end
end

defmodule Support.GallerySortFalse do
  use Swoosh.Gallery, sort: false
end

defmodule Support.GallerySortIsAFunction do
  use Swoosh.Gallery, sort: &Support.GallerySortIsAFunction.sort/1

  @impl true
  def sort(previews) do
    Enum.sort_by(previews, fn %{preview_details: %{description: descritpion}} ->
      String.length(descritpion)
    end)
  end
end
