defmodule Database.Query.Utils do
  alias Database.MapReduce

  defp merge_maps(map, acc) do
    Map.merge(map, acc, fn _key, x, y -> x + y end)
  end

  defp merge_averages(map, acc) do
    Map.merge(map, acc, fn _key, {acc_a, count_a}, {acc_b, count_b} ->
      {acc_a + acc_b, count_a + count_b}
    end)
  end

  def merge_kv_into_map({key, value}, acc) do
    Map.update(acc, key, value, &(&1 + value))
  end

  def merge_kv_into_map_averages({key, default}, acc) do
    {acc_a, count_a} = default

    Map.update(acc, key, default, fn {acc_b, count_b} ->
      {acc_a + acc_b, count_a + count_b}
    end)
  end

  def count_people_by_hash_in_chunk(hash_fn, chunk),
    do: count_people_by_hash_in_chunk(hash_fn, chunk, %{})

  def count_people_by_hash_in_chunk(_hash_fn, <<>>, acc), do: acc

  def count_people_by_hash_in_chunk(hash_fn, <<person::binary-size(8), rest::binary>>, acc) do
    key = hash_fn.(person)
    next_acc = Map.update(acc, key, 1, &(&1 + 1))
    count_people_by_hash_in_chunk(hash_fn, rest, next_acc)
  end

  def average_people_by_hash_in_chunk(hash_fn, get_value, chunk),
    do: average_people_by_hash_in_chunk(hash_fn, get_value, chunk, %{})

  def average_people_by_hash_in_chunk(_hash_fn, _get_value, <<>>, acc), do: acc

  def average_people_by_hash_in_chunk(
        hash_fn,
        get_value,
        <<person::binary-size(8), rest::binary>>,
        acc
      ) do
    key = hash_fn.(person)
    value = get_value.(person)
    default = {value, 1}

    next_acc =
      Map.update(acc, key, default, fn {acc_value, count} ->
        {acc_value + value, count + 1}
      end)

    average_people_by_hash_in_chunk(hash_fn, get_value, rest, next_acc)
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

  def generic_hashing_average(file, hash_fn, unhash_fn, get_value) do
    mapper = &average_people_by_hash_in_chunk(hash_fn, get_value, &1, %{})
    reducer = &merge_averages/2
    merger = &merge_kv_into_map_averages/2

    Database.File.stream_groups(file)
    |> MapReduce.map_reduce_merge(mapper, reducer, merger)
    |> Map.to_list()
    |> Enum.map(fn {key, {acc, count}} ->
      average = acc / count
      {key, average}
    end)
    |> Enum.sort_by(fn {_key, average} ->
      average
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
