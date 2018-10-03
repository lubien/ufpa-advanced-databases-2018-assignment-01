defmodule Mix.Tasks.Seed do
  use Mix.Task

  alias Database.Seeder

  def run(_) do
    {microseconds, _} = :timer.tc(&Seeder.seed/0)

    seconds = div(microseconds, 1_000_000)

    Mix.shell().info("Seeded in #{seconds}s")
  end
end
