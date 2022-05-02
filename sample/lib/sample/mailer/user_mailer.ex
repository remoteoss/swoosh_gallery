defmodule Sample.Mailer.UserMailer do
  use Phoenix.Swoosh, view: SampleWeb.UserMailerView, layout: {SampleWeb.LayoutView, :email}

  def welcome(user) do
    new()
    |> from("noreply@sample.test")
    |> to({user.name, user.email})
    |> subject("Welcome to Sample App")
    |> render_body("welcome.html", user: user)
  end

  def preview, do: welcome(%{email: "user@sample.test", name: "Test User!"})

  def preview_details do
    [
      title: "Welcome to Sample",
      description: "First email to welcome users into the platform"
    ]
  end
end
