defmodule Swoosh.Gallery.Layout do
  @moduledoc """
  This is the base layout of the Gallery. This is used both on Swoosh.Gallery.Plug and
  Mix.Tasks.Swoosh.Gallery.Html.
  """

  alias Swoosh.Email.Render
  alias Swoosh.Gallery
  require EEx

  @external_resource index_file = Path.join([__DIR__, "templates", "index.html.eex"])
  @external_resource table_file = Path.join([__DIR__, "templates", "table.html.eex"])
  @external_resource preview_file = Path.join([__DIR__, "templates", "preview.html.eex"])
  @external_resource styles_file = Path.join([__DIR__, "app.css"])

  @styles File.read!(styles_file)
  # Colors need to be declared entirely. Otherwise, the Tailwind CLI will ignore them.
  @tag_bg_colors ~w(bg-orange-100 bg-fuchsia-100 bg-amber-100 bg-red-100 bg-green-100 bg-neutral-100 bg-pink-100 bg-indigo-100 bg-emerald-100 bg-rose-100 bg-sky-100 bg-zinc-100 bg-yellow-100 bg-teal-100 bg-purple-100 bg-violet-100 bg-lime-100 bg-stone-100 bg-blue-100 bg-slate-100 bg-cyan-100 bg-gray-100)
  @tag_text_colors ~w(text-orange-800 text-fuchsia-800 text-amber-800 text-red-800 text-green-800 text-neutral-800 text-pink-800 text-indigo-800 text-emerald-800 text-rose-800 text-sky-800 text-zinc-800 text-yellow-800 text-teal-800 text-purple-800 text-violet-800 text-lime-800 text-stone-800 text-blue-800 text-slate-800 text-cyan-800 text-gray-800)

  EEx.function_from_file(:defp, :render_page, index_file, [:assigns])
  EEx.function_from_file(:defp, :render_table, table_file, [:assigns])
  EEx.function_from_file(:defp, :render_preview, preview_file, [:assigns])

  @doc ~S"""
  Renders a layout. See template.html.eex to find all the properties used by this.
  """
  @spec render(atom, keyword) :: binary
  def render(gallery, assigns \\ []) do
    previews = Gallery.eval_details(gallery.previews)

    ungrouped_previews =
      previews
      |> ungrouped_previews()
      |> sort_by_title()

    groups = grouped_previews(gallery.groups, previews)

    assigns
    |> Keyword.put(:ungrouped_previews, ungrouped_previews)
    |> Keyword.put(:groups, groups)
    |> Keyword.put(:styles, @styles)
    |> Keyword.put_new(:format, nil)
    |> render_page()
  end

  defp preview_path(preview, base_path, opts) do
    path = Keyword.get(opts, :path, "")
    format = Keyword.get(opts, :format, nil)

    add_format(Path.join([base_path, preview.path, path]), format)
  end

  defp add_format(string, nil), do: string
  defp add_format(string, format), do: "#{string}#{format}"

  defp to_absolute_url(base_path, path) do
    Path.join(base_path, path)
  end

  defp render_recipient(recipient) do
    case Render.render_recipient(recipient) do
      "" -> nil
      recipient -> Plug.HTML.html_escape(recipient)
    end
  end

  defp to_tag_color(tag_name) do
    index = :erlang.phash2(tag_name, length(@tag_bg_colors))
    {Enum.at(@tag_bg_colors, index), Enum.at(@tag_text_colors, index)}
  end

  defp ungrouped_previews(previews) do
    Enum.filter(previews, &is_nil(&1.group))
  end

  defp sort_by_title(previews) when is_list(previews) do
    Enum.sort_by(previews, fn %{preview_details: %{title: title}} -> title end)
  end

  defp grouped_previews(groups, previews) do
    groups
    |> Enum.map(fn group ->
      grouped_previews =
        previews
        |> Enum.filter(fn %{group: path} -> group.path == path end)
        |> sort_by_title()

      Map.put(group, :previews, grouped_previews)
    end)
    |> Enum.sort_by(fn %{title: title} -> title end)
  end
end
