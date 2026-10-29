defmodule ACP.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/f1729/agent-client-protocol-elixir"

  def project do
    [
      app: :agent_client_protocol,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.35", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Elixir implementation of the Agent Client Protocol (ACP) for communication
    between code editors and AI coding agents. Includes schema types, JSON-RPC
    primitives, behaviours, and connection management.
    """
  end

  defp package do
    [
      name: "agent_client_protocol",
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib mix.exs README.md LICENSE)
    ]
  end
end
