# dataset =
#   for i <- 1..10_000 do
#     if rem(i, 1) == 0 do
#       "males"
#     else
#       "females"
#     end
#   end

# reduce_count = fn data ->
#   data
#   |> Enum.reduce(fn key, acc ->
#     Map.update(acc, key, 1, &(&1 + 1))
#   end)
# end

elements = 100_000_000
storage_size = 64770

Benchee.run(
  %{
    "map" => fn ->
      acc =
        1..elements
        |> Enum.reduce(%{}, fn i, acc ->
          Map.update(acc, rem(i, storage_size), 1, &(&1 + 1))
        end)

      # IO.inspect(acc)

      acc
    end,
    "array" => fn ->
      arr = :array.new(storage_size)

      acc =
        1..elements
        |> Enum.reduce(arr, fn i, acc ->
          key = rem(i, storage_size)
          value = :array.get(key, acc)

          if value != :undefined do
            :array.set(key, value + 1, acc)
          else
            :array.set(key, 1, acc)
          end
        end)

      # IO.inspect(acc)

      acc
    end
  },
  time: 10,
  memory_time: 2
)
