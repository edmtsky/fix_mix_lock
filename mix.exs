defmodule FixMixLock.MixProject do
  use Mix.Project

  def project do
    [
      app: :fix_mix_lock,
      version: "0.2.1",
      elixir: "~> 1.12",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/edmtsky/fix_mix_lock"},
      maintainers: ["edmtsk"]
    ]
  end
end
