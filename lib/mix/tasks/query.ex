defmodule Mix.Tasks.Query do
  use Mix.Task

  alias Database.Query

  def run(_) do
    {microseconds, result} = :timer.tc(&Query.query/0)

    seconds = microseconds / 1_000_000

    IO.inspect(result)

    # ft =
    #   result
    #   |> Enum.reduce(%{}, fn {key, val}, acc ->
    #     Map.update(acc, key, val, &(&1 + val))
    #   end)

    # IO.inspect({result, ft, ft.true + ft.false})

    Mix.shell().info("Queried in #{seconds}s")
  end
end
