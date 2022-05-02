defmodule Swoosh.Gallery do
  @moduledoc ~S"""
  Swoosh.Gallery is a module used to map a preview to a path in order to later
  be exposed through Plug or generate docs with `mix swoosh.gen.gallery` task.

  ## Examples

      defmodule MyApp.SwooshGallery do
        use Swoosh.Gallery

        preview("/welcome", MyApp.Emails.Welcome)
      end

  Then in your router:

      forward "/gallery", MyApp.SwooshGallery

  Or, you can generate HTML pages from it:

      mix swoosh.gallery.html --gallery MyApp.SwooshGallery --path "_build/emails"
  """

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :previews, accumulate: true)
      Module.register_attribute(__MODULE__, :groups, accumulate: true)
      @group_path nil

      def init(opts) do
        Keyword.put(opts, :gallery, __MODULE__)
      end

      def call(conn, opts) do
        Swoosh.Gallery.Plug.call(conn, opts)
      end

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc false
      def previews, do: @previews

      def groups, do: @groups
    end
  end

  @doc ~S"""
  Declares a preview route. If expects that the module passed implements both
  `preview/0` and `preview_details/0`.

  ## Examples

      preview("/welcome", MyApp.Emails.Welcome)

  """
  @spec preview(String.t(), module()) :: no_return()
  defmacro preview(path, module) do
    path = validate_path(path)
    module = Macro.expand(module, __ENV__)
    preview_details = Macro.escape(eval_preview_details(module))

    quote do
      @previews %{
        group: @group_path,
        path: build_preview_path(@group_path, unquote(path)),
        email_mfa: {unquote(module), :preview, []},
        preview_details: unquote(preview_details)
      }
    end
  end

  @doc """
  Defines a scope in which previews can be nested. Each group needs a path and a `:title`
  option.

  ## Example

      group "/onboarding", title: "Onboarding Emails" do
        preview "/welcome", MyApp.Emails.Welcome
        preview "/account-confirmed", MyApp.Emails.AccountConfirmed
      end

  ## Options

  The supported options are:

    * `:title` - a string containing the group name.
  """
  defmacro group(path, opts, do: block) do
    path = validate_path(path)

    group =
      opts
      |> Keyword.put(:path, path)
      |> Keyword.validate!([:path, :title])
      |> Map.new()
      |> Macro.escape()

    quote do
      is_nil(@group_path) || raise "`group/3` cannot be nested"

      @group_path unquote(path)

      @groups unquote(group)
      unquote(block)
      @group_path nil
    end
  end

  @doc ~S"""
  Evaluates a preview. It loads the results of email_mfa into the email property.
  """
  @spec eval_preview(%{:email_mfa => {module(), atom(), list()}}) :: map()
  def eval_preview(%{email: _email} = preview), do: preview

  def eval_preview(%{email_mfa: {module, fun, opts}} = preview) do
    Map.put(preview, :email, apply(module, fun, opts))
  end

  @doc ~S"""
  Evaluates a preview and reads the attachment at a given index position.
  """
  @spec read_email_attachment_at(%{email_mfa: {atom, atom, list}}, integer()) ::
          {:error, :invalid_attachment | :not_found}
          | {:ok, %{content_type: String.t(), data: any}}
  def read_email_attachment_at(preview, index) do
    preview
    |> eval_preview()
    |> Map.get(:email)
    |> case do
      %{attachments: attachments} when length(attachments) > index ->
        case Enum.at(attachments, index) do
          %{data: data, content_type: content_type} when not is_nil(data) ->
            {:ok, %{content_type: content_type, data: data}}

          %{path: path, content_type: content_type} when not is_nil(path) ->
            {:ok, %{content_type: content_type, data: File.read!(path)}}

          _other ->
            {:error, :invalid_attachment}
        end

      _no_attachments ->
        {:error, :not_found}
    end
  end

  defp eval_preview_details(module) do
    module
    |> apply(:preview_details, [])
    |> Keyword.validate!([:title, :description, tags: []])
    |> Map.new()
    |> tap(&ensure_title!/1)
  end

  defp ensure_title!(details) do
    unless Map.has_key?(details, :title) do
      raise """

      The `title` is required in preview_details/0. Make sure it's being returned:

         def preview_details, do: [title: "Welcome email"]

      """
    end
  end

  defp validate_path("/" <> path), do: path

  defp validate_path(path) when is_binary(path), do: path

  defp validate_path(path) do
    raise ArgumentError, "router paths must be strings, got: #{inspect(path)}"
  end

  def build_preview_path(nil, path), do: path
  def build_preview_path(group, path), do: "#{group}.#{path}"
end
