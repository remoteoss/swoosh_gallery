defmodule Sample.Mailer.DownloadMailer do
  use Phoenix.Swoosh, view: SampleWeb.UserMailerView, layout: {SampleWeb.LayoutView, :email}

  def welcome(user) do
    file = Path.join([Application.app_dir(:sample, "priv"), "attachments", "file.pdf"])
    new()
    |> from("noreply@sample.test")
    |> to({user.name, user.email})
    |> subject("Here is the file you asked")
    |> render_body("download.html", user: user)
    |> attachment(file)
  end

  def preview, do: welcome(%{email: "user@sample.test", name: "Test User!"})

  def preview_details do
    [
      title: "File Download",
      description: "An email that has an attachment"
    ]
  end
end
