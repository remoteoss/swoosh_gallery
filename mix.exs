defmodule SwooshGallery.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :swoosh_gallery,
      version: @version,
      description: "Preview and display your Swoosh mailers to everyone",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:plug_cowboy, ">= 1.0.0"},
      {:swoosh, "~> 1.5"},
      {:ex_doc, "~> 0.21", only: [:dev, :test], runtime: false},
      {:hackney, "~> 1.9", only: [:test]},
      {:tailwind, "~> 0.1", only: [:dev, :test]}
    ]
  end

  defp docs do
    [
      main: "Swoosh.Gallery",
      source_ref: "v#{@version}",
      source_url: "https://github.com/remoteoss/swoosh_gallery"
    ]
  end

  defp package do
    [
      maintainers: ["Remote"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/remoteoss/swoosh_gallery"}
    ]
  end
end
