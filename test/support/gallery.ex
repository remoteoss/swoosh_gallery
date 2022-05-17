defmodule Support.Gallery do
  use Swoosh.Gallery

  preview("/welcome", Support.Emails.WelcomeEmail)

  group "/auth", title: "Auth" do
    preview("/reset_password", Support.Emails.ResetPasswordEmail)
  end
end
