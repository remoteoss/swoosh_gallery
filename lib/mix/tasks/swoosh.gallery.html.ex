defmodule Mix.Tasks.Swoosh.Gallery.Html do
  @moduledoc """
  Generate static files from a `Swoosh.Gallery` module that can be distributed and
  hosted without your application's code, on places like Amazon S3 or GitHub/GitLab Pages.

  ## Example

      mix swoosh.gallery.html --gallery Sample.Mailer.Gallery --path /tmp/emails
      * creating /tmp/emails
      * creating /tmp/emails/index.html
      * creating /tmp/emails/notifications.new_follower.html
      * creating /tmp/emails/notifications.new_follower/preview.html
      * creating /tmp/emails/notifications.new_message.html
      * creating /tmp/emails/notifications.new_message/preview.html
      * creating /tmp/emails/email_with_attachment.html
      * creating /tmp/emails/email_with_attachment/preview.html
      * creating /tmp/emails/email_with_attachment/attachments/0/file.pdf
      * creating /tmp/emails/welcome_users.html
      * creating /tmp/emails/welcome_users/preview.html

  ## Command line options

    * `-g`, `--gallery` - the gallery that will be used
    * `-p`, `--path` - path where the static files should be generated

  """
  use Mix.Task
  require Mix.Generator

  alias Swoosh.Gallery
  alias Swoosh.Gallery.Layout

  defmodule Options do
    @moduledoc false

    defstruct gallery: nil, path: nil
  end

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")
    opts = parse_options(argv)
    generate_html(opts)
  end

  defp parse_options(argv) do
    parse_options = [strict: [gallery: :string, path: :string]]
    {opts, _args, _} = OptionParser.parse(argv, parse_options)

    %Options{
      gallery: ensure_gallery!(opts),
      path: ensure_path!(opts)
    }
  end

  defp ensure_gallery!(opts) do
    if gallery = Keyword.get(opts, :gallery) do
      gallery
      |> List.wrap()
      |> Module.concat()
      |> Code.ensure_compiled!()
      |> tap(fn mod ->
        unless function_exported?(mod, :previews, 0) do
          Mix.raise("""
          The module #{inspect(mod)} is not a valid gallery. Make sure it uses Swoosh.Gallery:

          defmodule #{inspect(mod)} do
            use Swoosh.Gallery

            // preview(...)
          end
          """)
        end
      end)
      |> tap(&ensure_required_functions!(&1.previews))
    else
      Mix.raise("No gallery available. Please pass a gallery with the --gallery option")
    end
  end

  defp ensure_required_functions!(previews) when is_list(previews) do
    Enum.each(previews, fn %{email_mfa: {module, _fun, _args}} ->
      ensure_required_functions!(module)
    end)
  end

  defp ensure_required_functions!(module) do
    Code.ensure_compiled!(module)

    unless function_exported?(module, :preview, 0) do
      raise """

      The preview/3 function expected #{inspect(module)} to declare a function `preview/0`, but it is missing.

      Make sure it is implemented:

        def preview do
          // return Swoosh.Email.t
        end
      """
    end

    unless function_exported?(module, :preview_details, 0) do
      raise """

      The preview/3 function expected expected #{inspect(module)} to declare a function `preview_details/0`, but it is missing.

      Make sure it is implemented:

        def preview_details do
          [title: "My Email"]
        end
      """
    end
  end

  defp ensure_path!(opts) do
    if path = Keyword.get(opts, :path) do
      Mix.Generator.create_directory(path)
      path
    else
      Mix.raise("No path available. Please pass a path with the --path option")
    end
  end

  defp generate_html(%{path: destination, gallery: gallery}) do
    generate_root(gallery, destination)

    for preview <- gallery.previews do
      generate_preview(gallery, preview, destination)
    end
  end

  defp generate_root(gallery, destination) do
    root = Layout.render(gallery, base_path: "./", preview: nil, format: ".html")
    Mix.Generator.create_file(Path.join([destination, "index.html"]), root, force: true)
  end

  defp generate_preview(gallery, preview, destination) do
    preview = Gallery.eval_preview(preview)
    preview_path = Path.join([destination, preview.path])
    rendered = Layout.render(gallery, base_path: "./", preview: preview, format: ".html")
    Mix.Generator.create_file("#{preview_path}.html", rendered, force: true)

    generate_html_preview(preview_path, preview.email)
    generate_attachments(preview_path, preview)
  end

  defp generate_html_preview(preview_base_path, email) do
    Mix.Generator.create_file(Path.join([preview_base_path, "preview.html"]), email.html_body,
      force: true
    )
  end

  defp generate_attachments(preview_base_path, %{email: email} = preview) do
    Enum.with_index(email.attachments, fn attachment, index ->
      with {:ok, %{data: data}} <- Gallery.read_email_attachment_at(preview, index) do
        file_path =
          Path.join([
            preview_base_path,
            "attachments",
            Integer.to_string(index),
            attachment.filename
          ])

        Mix.Generator.create_file(file_path, data, force: true)
      end
    end)
  end
end
