defmodule Support.Emails.WelcomeEmail do
  import Swoosh.Email

  def preview() do
    new()
    |> subject("Welcome")
    |> html_body("Welcome to the Company!.")
    |> attachment(__DIR__ <> "/my_file.txt")
  end

  def preview_details() do
    [
      title: "Welcome",
      description: "Sends a warm welcome to the user",
      tags: [attachments: "yes"]
    ]
  end
end
