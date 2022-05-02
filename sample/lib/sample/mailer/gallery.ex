defmodule Sample.Mailer.Gallery do
  use Swoosh.Gallery

  preview "/welcome_users", Sample.Mailer.UserMailer
  preview "/email_with_attachment", Sample.Mailer.DownloadMailer

  group "/notifications", title: "Notifications" do
    preview "/new_message", Sample.Mailer.Notifications.NewMessageMailer
    preview "/new_follower", Sample.Mailer.Notifications.NewFollowerMailer
  end
end
