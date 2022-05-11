defmodule Hui.MixProject do
  use Mix.Project

  @source_url "https://github.com/boonious/hui"
  @version "0.10.5"

  def project do
    [
      app: :hui,
      version: "0.10.5",
      elixir: "~> 1.10",
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
      package: package(),
      docs: docs()
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
      {:jason, "~> 1.3"},
      {:finch, "~> 0.12", optional: true},
      {:httpoison, "~> 1.7", optional: true},
      {:bypass, "~> 2.1", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.28.3", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14.4", only: :test}
    ]
  end

  defp package do
    [
      name: "hui",
      description: "Hui 辉 is a Solr client and library for Elixir",
      maintainers: ["Boon Low"],
      licenses: ["Apache-2.0"],
      links: %{
        Changelog: "https://hexdocs.pm/hui/changelog.html",
        GitHub: @source_url
      }
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        LICENSE: [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      extra_section: "guides",
      source_url: @source_url,
      source_ref: "v#{@version}",
      homepage_url: @source_url,
      formatters: ["html"],
      groups_for_modules: [
        Queries: [
          Hui.Query.Common,
          Hui.Query.DisMax,
          Hui.Query.Facet,
          Hui.Query.FacetInterval,
          Hui.Query.FacetRange,
          Hui.Query.Highlight,
          Hui.Query.HighlighterFastVector,
          Hui.Query.HighlighterOriginal,
          Hui.Query.HighlighterUnified,
          Hui.Query.Metrics,
          Hui.Query.MoreLikeThis,
          Hui.Query.SpellCheck,
          Hui.Query.Standard,
          Hui.Query.Suggest,
          Hui.Query.Update
        ]
      ]
    ]
  end
end
