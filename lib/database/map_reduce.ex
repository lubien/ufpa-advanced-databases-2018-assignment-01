defmodule Database.MapReduce do
  def map_reduce_merge(stream, mapper, reducer, merger) do
    stream
    |> Flow.from_enumerable(max_demand: 500, stages: 8)
    |> Flow.map(mapper)
    |> Flow.reduce(fn -> %{} end, reducer)
    |> Enum.reduce(%{}, merger)
  end

  def windowed_map_reduce_merge(
        stream,
        mapper,
        reducer,
        merger,
        window \\ Flow.Window.count(1_000)
      ) do
    start = Time.utc_now()

    stream
    |> Flow.from_enumerable(max_demand: 500, stages: 16)
    |> Flow.map(mapper)
    |> Flow.partition(window: window)
    |> Flow.reduce(fn -> %{} end, reducer)
    |> Flow.on_trigger(fn acc, arg_b, arg_c ->
      time_diff = Time.diff(Time.utc_now(), start, :milliseconds) / 1_000

      IO.inspect({"window", arg_b, arg_c, "time:", time_diff, acc})

      {[], acc}
    end)
    |> Enum.reduce(%{}, merger)
  end

  def parallel_map_merge(stream, mapper, merger) do
    stream
    |> ParallelStream.map(mapper)
    |> Enum.reduce(%{}, merger)
  end
end
