defmodule Database.Person do
  @letter_A 65

  def random do
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

  def is_male?(<<1::size(1), _rest::size(63)>>), do: true
  # def is_male?(_), do: false
  def is_male?(<<0::size(1), _rest::size(63)>>), do: false

  # def is_male?(bytes) do
  #   <<a::binary-size(1), _rest::binary>> = bytes
  #   IO.inspect({"bytes", byte_size(bytes), a, bytes})
  #   Process.exit(self(), 1)
  #   false
  # end

  def is_female?(tuple), do: not is_male?(tuple)

  def get_gender(<<gender::size(1), _rest::size(63)>>), do: gender
  def get_age(<<_head::size(1), age::size(7), _rest::size(56)>>), do: age
  def get_income(<<_head::8, income::10, _rest::46>>), do: income
  def get_country(<<_head::size(32), country::size(8), _rest::size(24)>>), do: country

  def hash_country_gender_age(<<
        gender::size(1),
        age::size(7),
        _::size(24),
        country::size(8),
        _::size(24)
      >>),
      do: {gender, age, country}

  def translate(:gender, 1), do: "Male"
  def translate(:gender, 0), do: "Female"

  def translate(:country, number) do
    <<left::4, right::4>> = <<number::8>>
    <<left + @letter_A::8, right + @letter_A::8>>
  end

  def translate(:country_and_gender, {country, gender}) do
    "[#{translate(:country, country)}] #{translate(:gender, gender)}"
  end

  def to_csv(<<
        sex::size(1),
        age::size(7),
        income::size(10),
        scholarity::size(2),
        idiom::size(12),
        country::size(8),
        coodinates::size(24)
      >>) do
    "#{sex},#{age},#{income},#{scholarity},#{idiom},#{country},#{coodinates}"
  end

  defp random_bits(size) do
    min = 0
    max = trunc(:math.pow(2, size) - 1)
    Enum.random(min..max)
  end
end
