defmodule Swoosh.Gallery.Plug do
  @moduledoc """
  Plug that serves pages useful for previewing the gallery of emails in development.

  ## Examples

      # in a Phoenix router
      defmodule Sample.Router do
        scope "/dev" do
          pipe_through [:browser]
          forward "/mailbox/gallery", Swoosh.Gallery.Plug, gallery: Sample.EmailGallery
        end
      end
  """

  alias Swoosh.Gallery
  alias Swoosh.Gallery.Layout

  use Plug.Router
  use Plug.ErrorHandler

  def call(conn, opts) do
    gallery = Keyword.fetch!(opts, :gallery)

    conn =
      conn
      |> assign(:base_path, Path.join(["/" | conn.script_name]))
      |> assign(:gallery, gallery)

    super(conn, opts)
  end

  plug(:match)
  plug(:dispatch)

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(
      200,
      Layout.render(conn.assigns.gallery, base_path: conn.assigns.base_path, preview: nil)
    )
  end

  get "/:id/preview.html" do
    preview = fetch_preview!(conn.assigns.gallery, id)
    preview = Gallery.eval_preview(preview)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, replace_inline_references(preview.email))
  end

  get "/:id/attachments/:index/:filename" do
    index = String.to_integer(index)

    preview = fetch_preview!(conn.assigns.gallery, id)

    case Gallery.read_email_attachment_at(preview, index) do
      {:ok, %{data: data, content_type: content_type}} ->
        conn
        |> put_resp_content_type(content_type)
        |> send_resp(200, data)

      {:error, :invalid_attachment} ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(500, "Attachment cannot be displayed")

      {:error, :not_found} ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(404, "Attachment Not Found")
    end
  end

  get "/:id" do
    preview = fetch_preview!(conn.assigns.gallery, id)
    preview = Gallery.eval_preview(preview)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(
      200,
      Layout.render(conn.assigns.gallery, base_path: conn.assigns.base_path, preview: preview)
    )
  end

  defp fetch_preview!(gallery, id) do
    case Enum.find(gallery.previews, fn %{path: path} -> path == id end) do
      nil ->
        raise """
        Could not find an Email Preview with the path: #{id}
        """

      preview ->
        preview
    end
  end

  defp replace_inline_references(%{html_body: nil, text_body: text_body}) do
    text_body
  end

  defp replace_inline_references(%{html_body: html_body, attachments: attachments}) do
    ~r/"cid:([^"]*)"/
    |> Regex.scan(html_body)
    |> Enum.reduce(html_body, fn [_, ref], body ->
      case Enum.find_index(attachments, &(&1.filename == ref)) do
        nil -> html_body
        index -> String.replace(body, "cid:#{ref}", "attachments/#{index}")
      end
    end)
  end
end
