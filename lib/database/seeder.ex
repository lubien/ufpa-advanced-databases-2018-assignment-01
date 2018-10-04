defmodule Database.Seeder do
  alias Database.Person

  @file_name "priv/people.db"
  @many_people 1_000_000

  def seed do
    seed_by_delayed_writes_group()
  end

  def seed_by_writes do
    modes = [:raw, :write]

    File.open(@file_name, modes, fn file ->
      Enum.each(1..@many_people, fn _ ->
        :file.write(file, Person.random())
      end)
    end)
  end

  def seed_by_writes_flow do
    modes = [:write]

    File.open(@file_name, modes, fn file ->
      1..@many_people
      |> Flow.from_enumerable()
      |> Flow.partition()
      |> Flow.each(fn _ ->
        :file.write(file, Person.random())
      end)
      |> Flow.run()
    end)
  end

  def seed_by_writes_group(group_size \\ 10_000) do
    modes = [:raw, :write]

    many_people = div(@many_people, group_size)

    File.open(@file_name, modes, fn file ->
      Enum.each(1..many_people, fn _ ->
        group = for _ <- 1..group_size, do: Person.random()

        :file.write(file, group)
      end)
    end)
  end

  def seed_by_writes_group_flow(group_size \\ 10_000) do
    modes = [:append]

    many_people = div(@many_people, group_size)

    File.open(@file_name, modes, fn file ->
      1..many_people
      |> Flow.from_enumerable()
      |> Flow.partition()
      |> Flow.each(fn _ ->
        group = for _ <- 1..group_size, do: Database.Person.random()
        :file.write(file, group)
      end)
      |> Flow.run()
    end)
  end

  def seed_by_delayed_writes do
    modes = [:raw, :write, :delayed_write]

    File.open(@file_name, modes, fn file ->
      Enum.each(1..@many_people, fn _ ->
        :file.write(file, Person.random())
      end)
    end)
  end

  def seed_by_delayed_writes_flow do
    modes = [:write, :delayed_write]

    File.open(@file_name, modes, fn file ->
      1..@many_people
      |> Flow.from_enumerable()
      |> Flow.partition()
      |> Flow.each(fn _ ->
        :file.write(file, Person.random())
      end)
      |> Flow.run()
    end)
  end

  def seed_by_delayed_writes_group(group_size \\ 10_000) do
    modes = [:raw, :write, :delayed_write]

    many_people = div(@many_people, group_size)

    File.open(@file_name, modes, fn file ->
      Enum.each(1..many_people, fn _ ->
        group = for _ <- 1..group_size, do: Person.random()

        :file.write(file, group)
      end)
    end)
  end

  def seed_by_delayed_writes_group_flow(group_size \\ 10_000) do
    modes = [:write, :delayed_write]

    many_people = div(@many_people, group_size)

    File.open(@file_name, modes, fn file ->
      1..many_people
      |> Flow.from_enumerable()
      |> Flow.partition()
      |> Flow.each(fn _ ->
        group = for _ <- 1..group_size, do: Person.random()

        :file.write(file, group)
      end)
      |> Flow.run()
    end)
  end
end
