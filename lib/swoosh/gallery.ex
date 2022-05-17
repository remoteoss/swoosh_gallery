defmodule Swoosh.Gallery do
  @moduledoc ~S"""
  Swoosh.Gallery is a library to preview and display your Swoosh mailers to everyone,
  either by exposing the previews on your application's router or publishing it on
  your favorite static host solution.

  ## Getting Started

  You will a gallery module to organize all your previews, and implement the expected
  callbacks on your mailer modules:

      defmodule MyApp.Mailer.Gallery do
        use Swoosh.Gallery

        preview("/welcome", MyApp.Mailer.WelcomeMailer)
      end

      defmodule MyApp.Mailer.WelcomeMailer do
        # the expected Swoosh / Phoenix.Swoosh code that you already have to deliver emails
        use Phoenix.Swoosh, view: SampleWeb.WelcomeMailerView, layout: {MyApp.LayoutView, :email}

        def welcome(user) do
          new()
          |> from("noreply@sample.test")
          |> to({user.name, user.email})
          |> subject("Welcome to Sample App")
          |> render_body("welcome.html", user: user)
        end

        # `preview/0` function that builds your email using fixture data
        def preview do
          welcome(%{email: "user@sample.test", name: "Test User!"})
        end

        # `preview_details/0` with some useful metadata about your mailer
        def preview_details do
          [
            title: "Welcome to MyApp!",
            description: "First email to welcome users into the platform"
          ]
        end
      end

  Then in your router, you can mount your Gallery to expose it to the web:

      forward "/gallery", MyApp.Mailer.Gallery

  Or, you can generate static web pages with all the previews from your gallery:

      mix swoosh.gallery.html --gallery MyApp.Mailer.Gallery --path "_build/emails"

  ### Generating preview data

  Previews should be built using in memory fixture data and we do **not recommend** that you
  reuse your application's code to query for existing data or generate files during runtime. The
  `preview/0` can be invoked multiple times as you navigate through your gallery on your browser
  when mounting it on the router or when using the `swoosh.gallery.html` task to generate the static
  pages.

      defmodule MyApp.Mailer.SendContractEmail do
        def send_contract(user, blob) do
          contract =
            Swoosh.Attachment.new({:data, blob}, filename: "contract.pdf", content_type: "application/pdf")

          new()
          |> to({user.name, user.email})
          |> subject("Here is your Contract")
          |> attachment(contract)
          |> render_body(:contract, user: user)
        end

        # Bad - invokes application code to query data and generate the PDF contents
        def preview do
          user = MyApp.Users.find_user("testuser@acme.com")
          {:ok, blob} = MyApp.Contracts.build_contract(user)
          build(user, blob)
        end

        # Good - uses in memory structs and existing fixtures
        def preview do
          blob = File.read!("#{Application.app_dir(:tiger, "my_app")}/fixtures/sample.pdf")
          build(%User{}, blob)
        end
      end
  """

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :previews, accumulate: true)
      Module.register_attribute(__MODULE__, :groups, accumulate: true)
      @group_path nil

      def init(opts) do
        Keyword.put(opts, :gallery, __MODULE__.get())
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
      def get do
        previews = eval_details(@previews)
        %{previews: previews, groups: @groups}
      end
    end
  end

  @doc ~S"""
  Declares a preview route. If expects that the module passed implements both
  `preview/0` and `preview_details/0`.

  ## Examples

      defmodule MyApp.Mailer.Gallery do
        use Swoosh.Gallery

        preview "/welcome", MyApp.Emails.Welcome
        preview "/account-confirmed", MyApp.Emails.AccountConfirmed
        preview "/password-reset", MyApp.Emails.PasswordReset

      end
  """
  @spec preview(String.t(), module()) :: no_return()
  defmacro preview(path, module) do
    path = validate_path(path)
    module = Macro.expand(module, __ENV__)
    validate_preview_details!(module)

    quote do
      @previews %{
        group: @group_path,
        path: build_preview_path(@group_path, unquote(path)),
        email_mfa: {unquote(module), :preview, []},
        details_mfa: {unquote(module), :preview_details, []}
      }
    end
  end

  @doc """
  Defines a scope in which previews can be nested when rendered on your gallery.
  Each group needs a path and a `:title` option.

  ## Example

      defmodule MyApp.Mailer.Gallery do
        use Swoosh.Gallery

        group "/onboarding", title: "Onboarding Emails" do
          preview "/welcome", MyApp.Emails.Welcome
          preview "/account-confirmed", MyApp.Emails.AccountConfirmed
        end

        preview "/password-reset", MyApp.Emails.PasswordReset
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

  # Evaluates a preview. It loads the results of email_mfa and details_mfa into the email
  # and preview_details properties respectively.
  @doc false
  @spec eval_preview(%{
          :email_mfa => {module(), atom(), list()},
          :details_mfa => {module(), atom(), list()}
        }) :: map()
  def eval_preview(%{email: _email} = preview), do: preview

  def eval_preview(preview) do
    preview
    |> eval_email()
    |> eval_details()
  end

  defp eval_email(%{email_mfa: {module, fun, opts}} = preview) do
    Map.put(preview, :email, apply(module, fun, opts))
  end

  # Evaluates preview details. It loads the results of details_mfa into the
  # preview_details property.
  @doc false
  @spec eval_details(
          %{:details_mfa => {module(), atom(), list()}}
          | list(%{:details_mfa => {module(), atom(), list()}})
        ) :: map()
  def eval_details(%{preview_details: _details} = preview), do: preview

  def eval_details(%{details_mfa: {module, fun, opts}} = preview) do
    Map.put(preview, :preview_details, validate_preview_details!(module, fun, opts))
  end

  def eval_details(previews) when is_list(previews) do
    Enum.map(previews, fn %{details_mfa: _mfa} = preview ->
      eval_details(preview)
    end)
  end

  # Evaluates a preview and reads the attachment at a given index position.
  @doc false
  @spec read_email_attachment_at(%{email_mfa: {module, atom, list}}, integer()) ::
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

  defp validate_preview_details!(module, fun \\ :preview_details, opts \\ []) do
    module
    |> apply(fun, opts)
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

  @doc false
  def build_preview_path(nil, path), do: path
  def build_preview_path(group, path), do: "#{group}.#{path}"
end
