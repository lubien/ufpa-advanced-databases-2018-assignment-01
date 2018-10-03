defmodule Seed do
  def run do
    {time, _} =
      :timer.tc(fn ->
        File.open("foo.txt", [:write, :raw], fn file ->
          Enum.each(1..1_000_000, fn _i ->
            :file.write(file, person())
          end)
        end)
      end)

    IO.puts("#{div(time, 1_000_000)}s")
  end

  def person do
    <<
      # Sex
      random_bits(1)::size(1),
      # Age
      random_bits(7)::size(7),
      # Monthly Income (* 1000 / year)
      random_bits(10)::size(10),
      # Scholarity
      random_bits(2)::size(2),
      # Idiom
      random_bits(12)::size(12),
      # Country
      random_bits(8)::size(8),
      # Coordinates
      random_bits(24)::size(24)
    >>
  end

  defp random_bits(size) do
    min = 0
    max = trunc(:math.pow(2, size) - 1)
    Enum.random(min..max)
  end
end

Seed.run()
|> IO.inspect()
