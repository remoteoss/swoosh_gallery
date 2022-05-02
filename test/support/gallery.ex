defmodule Support.Gallery do
  use Swoosh.Gallery

  preview("/welcome", Support.Emails.WelcomeEmail)
  preview("/reset_password", Support.Emails.ResetPasswordEmail)
end
