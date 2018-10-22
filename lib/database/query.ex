defmodule Database.Query do
  alias Database.Person
  alias Database.Hashing
  alias Database.Query.Utils

  @db_file "priv/people1000kk.db"

  def run(file, index) do
    queries = %{
      0 => &count_by_gender/1,
      1 => &count_by_country_and_gender/1,
      2 => &count_by_country_gender_and_age/1,
      3 => &average_income_by_country_and_gender/1,
      4 => &average_age_by_country_and_gender/1,
      5 => &count_by_country_and_gender_country_15/1,
      6 => &count_by_country_and_gender_country_15_gender_male/1,
      7 => &count_by_country_and_gender_country_lte_15/1,
      8 => &count_by_country_and_gender/1,
      9 => &count_by_country_and_gender/1,
      10 => &count_by_country_and_gender/1
    }

    func = Map.get(queries, index)
    func.(file)
  end

  def count_by_gender(file \\ @db_file) do
    Utils.generic_hashing_count(file, &Hashing.hash_gender/1, &Hashing.unhash_gender/1)
    |> Enum.map(fn {gender, count} ->
      %{
        "gender" => Person.translate(:gender, gender),
        "count" => count
      }
    end)
    |> Scribe.print()
  end

  # 1st query
  def count_by_country_and_gender(file \\ @db_file) do
    Utils.generic_hashing_count(
      file,
      &Hashing.hash_gender_country/1,
      &Hashing.unhash_gender_country/1
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

  # 2nd query (slooooooow)
  def count_by_country_gender_and_age(file \\ @db_file) do
    Utils.generic_hashing_count(
      file,
      &Hashing.hash_gender_country_age/1,
      &Hashing.unhash_gender_country_age/1
    )
    # this has potentially 65k lines so...
    |> Enum.take(-1000)
    |> Enum.map(fn {{gender, country, age}, count} ->
      %{
        "country" => Person.translate(:country, country),
        "age" => age,
        "gender" => Person.translate(:gender, gender),
        "count" => count
      }
    end)
    |> Scribe.print()
  end

  # 3rd query
  def average_income_by_country_and_gender(file \\ @db_file) do
    Utils.generic_hashing_average(
      file,
      &Hashing.hash_gender_country/1,
      &Hashing.unhash_gender_country/1,
      &Person.get_income/1
    )
    |> Enum.map(fn {{gender, country}, average} ->
      %{
        "country" => Person.translate(:country, country),
        "gender" => Person.translate(:gender, gender),
        "average" => average
      }
    end)
    |> Scribe.print()
  end

  # 4th query
  def average_age_by_country_and_gender(file \\ @db_file) do
    Utils.generic_hashing_average(
      file,
      &Hashing.hash_gender_country/1,
      &Hashing.unhash_gender_country/1,
      &Person.get_age/1
    )
    |> Enum.map(fn {{gender, country}, average} ->
      %{
        "country" => Person.translate(:country, country),
        "gender" => Person.translate(:gender, gender),
        "average" => round(average)
      }
    end)
    |> Scribe.print()
  end

  # 5th query
  def count_by_country_and_gender_country_15(file \\ @db_file) do
    filter_fn = fn
      <<_::size(32), 15::size(8), _::size(24)>> ->
        true

      _ ->
        false
    end

    Utils.generic_hashing_filtered_count(
      file,
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
  def count_by_country_and_gender_country_15_gender_male(file \\ @db_file) do
    filter_fn = fn
      <<1::size(1), _::size(31), 15::size(8), _::size(24)>> ->
        true

      _ ->
        false
    end

    Utils.generic_hashing_filtered_count(
      file,
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
  def count_by_country_and_gender_country_lte_15(file \\ @db_file) do
    filter_fn = fn
      <<_::size(32), country::size(8), _::size(24)>> when country <= 15 ->
        true

      _ ->
        false
    end

    Utils.generic_hashing_filtered_count(
      file,
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
end
