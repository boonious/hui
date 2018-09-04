defmodule Hui.MixProject do
  use Mix.Project

  @description """
    Hui 辉 is a Solr client and library for Elixir
  """

  def project do
    [
      app: :hui,
      version: "0.4.1",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Hui",
      description: @description,
      package: package(),
      source_url: "https://github.com/boonious/hui",
      homepage_url: "https://github.com/boonious/hui",
      docs: [
        main: "Hui", # The main page in the docs
        #logo: "path/to/logo.png",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:bypass, "~> 0.8", only: :test}
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
