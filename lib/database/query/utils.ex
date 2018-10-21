defmodule Database.Query.Utils do
  alias Database.MapReduce

  defp merge_maps(map, acc) do
    Map.merge(map, acc, fn _key, x, y -> x + y end)
  end

  def merge_kv_into_map({key, value}, acc) do
    Map.update(acc, key, value, &(&1 + value))
  end

  def count_people_by_hash_in_chunk(hash_fn, chunk),
    do: count_people_by_hash_in_chunk(hash_fn, chunk, %{})

  def count_people_by_hash_in_chunk(_hash_fn, <<>>, acc), do: acc

  def count_people_by_hash_in_chunk(hash_fn, <<person::binary-size(8), rest::binary>>, acc) do
    key = hash_fn.(person)
    next_acc = Map.update(acc, key, 1, &(&1 + 1))
    count_people_by_hash_in_chunk(hash_fn, rest, next_acc)
  end

  def count_people_by_hash_in_chunk_filter(hash_fn, filter_fn, chunk),
    do: count_people_by_hash_in_chunk_filter(hash_fn, filter_fn, chunk, %{})

  def count_people_by_hash_in_chunk_filter(_hash_fn, _filter_fn, <<>>, acc), do: acc

  def count_people_by_hash_in_chunk_filter(
        hash_fn,
        filter_fn,
        <<person::binary-size(8), rest::binary>>,
        acc
      ) do
    next_acc =
      if filter_fn.(person) do
        key = hash_fn.(person)
        Map.update(acc, key, 1, &(&1 + 1))
      else
        acc
      end

    count_people_by_hash_in_chunk_filter(hash_fn, filter_fn, rest, next_acc)
  end

  def generic_hashing_count(file, hash_fn, unhash_fn) do
    mapper = &count_people_by_hash_in_chunk(hash_fn, &1, %{})
    reducer = &merge_maps/2
    merger = &merge_kv_into_map/2

    Database.File.stream_groups(file)
    |> MapReduce.map_reduce_merge(mapper, reducer, merger)
    |> Map.to_list()
    |> Enum.sort_by(fn {_key, count} ->
      count
    end)
    |> Enum.map(fn {key, count} ->
      unhashed = unhash_fn.(key)
      {unhashed, count}
    end)
  end

  def generic_hashing_filtered_count(file, hash_fn, unhash_fn, filter_fn) do
    mapper = &count_people_by_hash_in_chunk_filter(hash_fn, filter_fn, &1, %{})
    reducer = &merge_maps/2
    merger = &merge_kv_into_map/2

    Database.File.stream_groups(file)
    |> MapReduce.map_reduce_merge(mapper, reducer, merger)
    |> Map.to_list()
    |> Enum.sort_by(fn {_key, count} ->
      count
    end)
    |> Enum.map(fn {key, count} ->
      unhashed = unhash_fn.(key)
      {unhashed, count}
    end)
  end
end
