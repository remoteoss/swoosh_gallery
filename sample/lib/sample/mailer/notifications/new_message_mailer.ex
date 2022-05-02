defmodule Sample.Mailer.Notifications.NewMessageMailer do
  use Phoenix.Swoosh, view: SampleWeb.NotificationsMailer, layout: {SampleWeb.LayoutView, :email}

  def welcome(user) do
    new()
    |> from("noreply@sample.test")
    |> to({user.name, user.email})
    |> subject("You have a new message")
    |> render_body("new_message.html", user: user)
  end

  def preview, do: welcome(%{email: "user@sample.test", name: "Test User!"})

  def preview_details do
    [
      title: "New Message",
      description: "Notification when the user receives a new direct message"
    ]
  end
end
