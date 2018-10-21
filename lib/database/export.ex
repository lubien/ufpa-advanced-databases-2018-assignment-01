defmodule Database.Export do
  @db_file "priv/people1000kk.db"

  alias Database.Person

  def run do
    Database.File.stream_groups(@db_file)
    # |> Enum.each(&process_group/1)
    |> ParallelStream.each(&process_group/1, num_workers: 16)
    |> Stream.run()
  end

  def process_group(<<>>), do: []

  def process_group(<<person::binary-size(8), rest::binary>>) do
    IO.puts(Person.to_csv(person))
    process_group(rest)
  end
end
