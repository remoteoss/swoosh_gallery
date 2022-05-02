defmodule Sample.Mailer.Notifications.NewFollowerMailer do
  use Phoenix.Swoosh, view: SampleWeb.NotificationsMailer, layout: {SampleWeb.LayoutView, :email}

  def welcome(user, follower) do
    new()
    |> from("noreply@sample.test")
    |> to({user.name, user.email})
    |> subject("Great! #{follower.name} is following you")
    |> render_body("new_follower.html", user: user, follower: follower)
  end

  def preview, do: welcome(%{email: "user@sample.test", name: "Test User!"}, %{name: "Another User"})

  def preview_details do
    [
      title: "New Follower",
      description: "Notification when the user is followed by another person"
    ]
  end
end
