defmodule Hui.MixProject do
  use Mix.Project

  @description """
    Hui 辉 is a Solr client and library for Elixir
  """

  def project do
    [
      app: :hui,
      version: "0.10.3",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],

      # Docs
      name: "Hui",
      description: @description,
      package: package(),
      source_url: "https://github.com/boonious/hui",
      homepage_url: "https://github.com/boonious/hui",
      docs: [
        # The main page in the docs
        main: "Hui",
        # logo: "path/to/logo.png",
        extras: ["README.md", "CHANGELOG.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [applications: applications(Mix.env())]
  end

  def applications(env) when env in [:dev, :test], do: [:logger, :inets, :ssl, :httpoison]
  def applications(_), do: [:logger, :inets, :ssl]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2"},
      {:httpoison, "~> 1.7", optional: true},
      {:bypass, "~> 1.0", only: :test},
      {:dialyxir, "~> 1.0.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:excoveralls, "~> 0.13", only: :test}
    ]
  end

  defp package do
    [
      name: "hui",
      maintainers: ["Boon Low"],
      licenses: ["Apache 2.0"],
      links: %{
        Changelog: "https://github.com/boonious/hui/blob/master/CHANGELOG.md",
        GitHub: "https://github.com/boonious/hui"
      }
    ]
  end
end
