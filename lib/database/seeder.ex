defmodule Database.Seeder do
  alias Database.Person

  @file_name "priv/people.db"
  @file_open_modes [:write, :raw]
  @many_people 1_000_000

  def seed do
    seed_by_writes()
  end

  def seed_by_writes do
    File.open(@file_name, @file_open_modes, fn file ->
      Enum.each(1..@many_people, fn _ ->
        :file.write(file, Person.random())
      end)
    end)
  end
end
