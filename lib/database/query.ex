defmodule Database.Query do
  alias Database.Person
  # alias Database.Progress
  alias Database.MapReduce
  alias Database.Hashing

  @db_file "priv/people100kk.db"

  def query do
    count_by_country_gender_and_age()
  end

  def count_by_sex do
    mapper = &count_gender_in_chunks({0, 0}, &1)
    reducer = &merge_maps/2
    merger = &merge_kv_into_map/2

    Database.File.stream_groups(@db_file)
    |> MapReduce.map_reduce_merge(mapper, reducer, merger)
  end

  def count_by_sex_parallel_stream do
    mapper = &count_gender_in_chunks({0, 0}, &1)
    merger = &merge_kv_into_map/2

    Database.File.stream_groups(@db_file)
    |> MapReduce.parallel_map_merge(mapper, merger)
  end

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

  def generic_hashing_count(hash_fn, unhash_fn) do
    mapper = &count_people_by_hash_in_chunk(hash_fn, &1, %{})
    reducer = &merge_maps/2
    merger = &merge_kv_into_map/2

    Database.File.stream_groups(@db_file)
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

  def generic_hashing_filtered_count(hash_fn, unhash_fn, filter_fn) do
    mapper = &count_people_by_hash_in_chunk_filter(hash_fn, filter_fn, &1, %{})
    reducer = &merge_maps/2
    merger = &merge_kv_into_map/2

    Database.File.stream_groups(@db_file)
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

  def count_by_gender do
    generic_hashing_count(&Hashing.hash_gender/1, &Hashing.unhash_gender/1)
    |> Enum.map(fn {gender, count} ->
      %{
        "gender" => Person.translate(:gender, gender),
        "count" => count
      }
    end)
    |> Scribe.print()
  end

  # 1st query
  def count_by_country_and_gender do
    generic_hashing_count(&Hashing.hash_gender_country/1, &Hashing.unhash_gender_country/1)
    |> Enum.map(fn {{gender, country}, count} ->
      %{
        "country" => Person.translate(:country, country),
        "gender" => Person.translate(:gender, gender),
        "count" => count
      }
    end)
    |> Scribe.print()
  end

  # 2nd query (slooooooow)
  def count_by_country_gender_and_age do
    generic_hashing_count(&Hashing.hash_gender_country_age/1, &Hashing.unhash_gender_country_age/1)
    |> Enum.map(fn {{gender, country, age}, count} ->
      %{
        "country" => Person.translate(:country, country),
        "age" => age,
        "gender" => Person.translate(:gender, gender),
        "count" => count
      }
    end)
    # |> Enum.count
    |> IO.inspect
    # |> Scribe.print()
  end

  # 5th query
  def count_by_country_and_gender_country_15 do
    filter_fn = fn
      <<_::size(32), 15::size(8), _::size(24)>> ->
        true
      _ ->
        false
    end

    generic_hashing_filtered_count(
      &Hashing.hash_gender_country/1,
      &Hashing.unhash_gender_country/1,
      filter_fn
    )
    |> Enum.map(fn {{gender, country}, count} ->
      %{
        "country" => Person.translate(:country, country),
        "gender" => Person.translate(:gender, gender),
        "count" => count
      }
    end)
    |> Scribe.print()
  end

  # 6th query
  def count_by_country_and_gender_country_15_gender_male do
    filter_fn = fn
      <<1::size(1), _::size(31), 15::size(8), _::size(24)>> ->
        true
      _ ->
        false
    end

    generic_hashing_filtered_count(
      &Hashing.hash_gender_country/1,
      &Hashing.unhash_gender_country/1,
      filter_fn
    )
    |> Enum.map(fn {{gender, country}, count} ->
      %{
        "country" => Person.translate(:country, country),
        "gender" => Person.translate(:gender, gender),
        "count" => count
      }
    end)
    |> Scribe.print()
  end

  # 7th query
  def count_by_country_and_gender_country_lte_15 do
    filter_fn = fn
      <<_::size(32), country::size(8), _::size(24)>> when country <= 15 ->
        true
      _ ->
        false
    end

    generic_hashing_filtered_count(
      &Hashing.hash_gender_country/1,
      &Hashing.unhash_gender_country/1,
      filter_fn
    )
    |> Enum.map(fn {{gender, country}, count} ->
      %{
        "country" => Person.translate(:country, country),
        "gender" => Person.translate(:gender, gender),
        "count" => count
      }
    end)
    |> Scribe.print()
  end

  # defp count_gender_in_chunks(people), do: count_gender_in_chunks({0, 0}, people)

  defp count_gender_in_chunks({males, females}, <<>>) do
    %{"males" => males, "females" => females}
  end

  defp count_gender_in_chunks({males, females}, <<1::size(1), _::size(63), rest::binary>>),
    do: count_gender_in_chunks({males + 1, females}, rest)

  defp count_gender_in_chunks({males, females}, <<_female::size(64), rest::binary>>),
    do: count_gender_in_chunks({males, females + 1}, rest)

  # def count_by_country_sex_and_age_flow do
  #   people_per_chunk = 10_000
  #   bytes_per_chunk = people_per_chunk * @tuple_byte_size

  #   # hasher = fn person ->
  #   #   {
  #   #     Person.get_country(person),
  #   #     Person.get_gender(person),
  #   #     Person.get_age(person)
  #   #   }
  #   # end

  #   Progress.start_link([:read_people, :count_chunk, :count_merged])

  #   data =
  #     File.stream!(@db_file, [read_ahead: bytes_per_chunk * 2], bytes_per_chunk)
  #     |> Stream.map(fn chunk ->
  #       Progress.incr(:read_people, people_per_chunk)
  #       chunk
  #     end)
  #     |> Flow.from_enumerable()
  #     |> Flow.partition(max_demand: 1)
  #     |> Flow.map(fn chunk ->
  #       hashes = hash_chunks(&Person.hash_country_gender_age/1, chunk)
  #       Progress.incr(:count_chunk, people_per_chunk)
  #       hashes
  #     end)
  #     |> Enum.reduce(%{}, fn group, acc ->
  #       Map.merge(group, acc, fn _key, x, y -> x + y end)
  #     end)
  #     |> Map.to_list()
  #     |> Enum.map(fn {{gender, age, country}, count} ->
  #       %{
  #         "country" => country,
  #         "gender" => Person.translate(:gender, gender),
  #         "age" => age,
  #         "count" => count
  #       }
  #     end)
  #     |> Enum.sort_by(fn %{"count" => count} -> count end)
  #     |> Scribe.print(colorize: false)

  #   Progress.stop()

  #   data
  # end

  # def count_by_country_and_gender_flow_each do
  #   people_per_chunk = 10_000
  #   bytes_per_chunk = people_per_chunk * @tuple_byte_size

  #   Progress.start_link([:read_people, :count_chunk, :count_merged])

  #   hasher = fn person ->
  #     {
  #       Person.get_country(person),
  #       Person.get_gender(person)
  #     }
  #   end

  #   data =
  #     File.stream!(@db_file, [read_ahead: 100_000], 8)
  #     |> Stream.map(fn chunk ->
  #       hashed = hasher.(chunk)
  #       Progress.incr(:read_people, people_per_chunk)
  #       # IO.puts("hashed")
  #       hashed
  #     end)
  #     |> Flow.from_enumerable()
  #     # |> Flow.partition(min_demand: 500, max_demand: 1000)
  #     # |> Flow.map(fn person ->
  #     #   hashed = hasher.(person)
  #     #   Progress.incr(:count_chunk, 1)
  #     #   hashed
  #     # end)
  #     # |> Flow.map(&count_gender_in_chunks/1)
  #     # |> Flow.partition(window: Flow.Window.count(100_000), stages: 1)
  #     |> Flow.partition(min_demand: 0, max_demand: 10_000)
  #     |> Flow.reduce(fn -> %{} end, fn hash, acc ->
  #       next_acc =
  #         acc
  #         |> Map.update(hash, 1, &(&1 + 1))

  #       Progress.incr(:count_chunk, 1)

  #       next_acc
  #     end)
  #     # |> Flow.on_trigger(fn map, b, c ->
  #     #   IO.inspect({Enum.count(Map.to_list(map)), b, c})
  #     #   {[], map}
  #     # end)
  #     |> Enum.reduce(%{}, fn {key, count}, acc ->
  #       next_acc =
  #         acc
  #         |> Map.update(key, count, &(&1 + count))

  #       Progress.incr(:count_merged, count)

  #       next_acc

  #       # IO.inspect(acc)
  #       # Map.merge(hashes, acc, fn _key, x, y -> x + y end)
  #     end)

  #   # |> Enum.count()

  #   # |> Enum.to_list()

  #   Progress.stop()

  #   data
  # end

  # def count_by_country_and_gender_flow_alt do
  #   people_per_chunk = 10_000
  #   bytes_per_chunk = people_per_chunk * @tuple_byte_size

  #   Progress.start_link([:read_people, :count_chunk, :count_merged])

  #   hasher = fn person ->
  #     {
  #       Person.get_country(person),
  #       Person.get_gender(person)
  #     }
  #   end

  #   data =
  #     File.stream!(@db_file, [read_ahead: 100_000], 8)
  #     |> Stream.map(fn chunk ->
  #       # hashed = hasher.(chunk)

  #       # IO.puts("hashed")
  #       chunk
  #     end)
  #     |> Flow.from_enumerable()
  #     |> Flow.map(fn person ->
  #       hashed = hasher.(person)
  #       Progress.incr(:read_people, 1)
  #       hashed
  #     end)
  #     |> Flow.partition()
  #     |> Flow.group_by(fn hashed ->
  #       Progress.incr(:count_chunk, 1)
  #       hashed
  #     end)
  #     |> Flow.partition()
  #     |> Flow.map_values(fn values ->
  #       count = Enum.count(values)
  #       Progress.incr(:count_merged, count)
  #       count
  #     end)
  #     |> Enum.to_list()

  #   # |> Flow.partition(min_demand: 500, max_demand: 1000)
  #   # |> Flow.map(fn person ->
  #   #   hashed = hasher.(person)
  #   #   Progress.incr(:count_chunk, 1)
  #   #   hashed
  #   # end)
  #   # |> Flow.map(&count_gender_in_chunks/1)
  #   # |> Flow.partition(window: Flow.Window.count(100_000), stages: 1)
  #   # |> Flow.partition(min_demand: 0, max_demand: 10_000)
  #   # |> Flow.reduce(fn -> %{} end, fn hash, acc ->
  #   #   next_acc =
  #   #     acc
  #   #     |> Map.update(hash, 1, &(&1 + 1))

  #   #   Progress.incr(:count_chunk, 1)

  #   #   next_acc
  #   # end)
  #   # # |> Flow.on_trigger(fn map, b, c ->
  #   # #   IO.inspect({Enum.count(Map.to_list(map)), b, c})
  #   # #   {[], map}
  #   # # end)
  #   # |> Enum.reduce(%{}, fn {key, count}, acc ->
  #   #   next_acc =
  #   #     acc
  #   #     |> Map.update(key, count, &(&1 + count))

  #   #   Progress.incr(:count_merged, count)

  #   #   next_acc

  #   #   # IO.inspect(acc)
  #   #   # Map.merge(hashes, acc, fn _key, x, y -> x + y end)
  #   # end)

  #   # |> Enum.count()

  #   # |> Enum.to_list()

  #   Progress.stop()

  #   data
  # end

  # defp hash_chunks(hasher, chunk), do: hash_chunks(hasher, chunk, %{})

  # defp hash_chunks(_hasher, <<>>, acc), do: acc

  # defp hash_chunks(hasher, <<person::binary-size(8), rest::binary>>, acc) do
  #   hash = hasher.(person)

  #   acc =
  #     acc
  #     |> Map.update(hash, 1, &(&1 + 1))

  #   hash_chunks(hasher, rest, acc)
  # end

  # def count_by_sex_flow_eager_chuncked do
  #   people_per_chunk = 10_000
  #   bytes_per_chunk = people_per_chunk * @tuple_byte_size

  #   Progress.start_link([:read_people, :count_chunk, :count_merged])

  #   data =
  #     File.stream!(@db_file, [read_ahead: bytes_per_chunk * 2], bytes_per_chunk)
  #     |> Stream.map(fn chunk ->
  #       Progress.incr(:read_people, people_per_chunk)
  #       chunk
  #     end)
  #     # |> Flow.from_enumerable(max_demand: 100)
  #     # |> Flow.partition(stages: 10, max_demand: 1)
  #     |> Stream.map(fn chunk ->
  #       count = count_gender_in_chunks4(chunk)
  #       Progress.incr(:count_chunk, people_per_chunk)
  #       count
  #     end)

  #     # |> Flow.map(&count_gender_in_chunks/1)
  #     # |> Flow.partition(min_demand: 500)
  #     |> Enum.reduce(%{}, fn %{"males" => males, "females" => females}, acc ->
  #       next_acc =
  #         acc
  #         |> Map.update("males", 1, &(&1 + males))
  #         |> Map.update("females", 1, &(&1 + females))

  #       Progress.incr(:count_merged, males + females)

  #       next_acc
  #     end)
  #     |> Enum.to_list()

  #   Progress.stop()

  #   data
  # end

  # defp count_gender_in_chunks(people), do: count_gender_in_chunks(%{}, people)

  # defp count_gender_in_chunks(acc, <<>>), do: acc

  # defp count_gender_in_chunks(acc, <<x::size(1), _::size(63), rest::binary>>) do
  #   if x == 1 do
  #     acc = Map.update(acc, "males", 1, &(&1 + 1))
  #     count_gender_in_chunks(acc, rest)
  #   else
  #     acc = Map.update(acc, "females", 1, &(&1 + 1))
  #     count_gender_in_chunks(acc, rest)
  #   end
  # end

  # defp count_gender_in_chunks2(people), do: count_gender_in_chunks2({0, 0}, people)

  # defp count_gender_in_chunks2({males, females}, <<>>),
  #   do: %{"males" => males, "females" => females}

  # defp count_gender_in_chunks2({males, females}, <<x::size(1), _::size(63), rest::binary>>) do
  #   if x == 1 do
  #     count_gender_in_chunks2({males + 1, females}, rest)
  #   else
  #     count_gender_in_chunks2({males, females + 1}, rest)
  #   end
  # end

  # defp count_gender_in_chunks4(people), do: count_gender_in_chunks4({0, 0}, people)

  # defp count_gender_in_chunks4({males, females}, <<>>),
  #   do: %{"males" => males, "females" => females}

  # defp count_gender_in_chunks4({males, females}, <<person::binary-size(8), rest::binary>>) do
  #   if Person.is_male?(person) do
  #     count_gender_in_chunks4({males + 1, females}, rest)
  #   else
  #     count_gender_in_chunks4({males, females + 1}, rest)
  #   end
  # end

  # defp count_gender_in_chunks5(chunk) do
  #   for <<person::binary-size(8) <- chunk>> do
  #     if Person.is_male?(person) do
  #       "males"
  #     else
  #       "females"
  #     end
  #   end
  #   |> Enum.reduce(%{}, fn key, acc ->
  #     Map.update(acc, key, 1, &(&1 + 1))
  #   end)
  # end
end
