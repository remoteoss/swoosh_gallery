defmodule Support.Emails.ResetPasswordEmail do
  import Swoosh.Email

  def preview() do
    new()
    |> subject("Reset")
    |> text_body("Please, reset your password: http://reset.pw")
    |> html_body("Please, reset your password <a href=\"http://reset.pw\">here</a>.")
  end

  def preview_details() do
    [
      title: "Reset Password",
      description: "Sends instructions on how to reset password",
      tags: [passwords: "yes"]
    ]
  end
end
