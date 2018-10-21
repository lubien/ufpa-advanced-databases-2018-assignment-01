defmodule Database.Hashing do
  def hash_gender(<<gender::size(1), _::size(63)>>) do
    gender
  end

  def unhash_gender(hashed) do
    hashed
  end

  def hash_gender_country(<<gender::size(1), _::size(31), country::size(8), _::size(24)>>) do
    # :binary.decode_unsigned(<<gender::size(8), country::size(8)>>)
    <<hashed::9>> = <<gender::1, country::8>>
    hashed
  end

  def unhash_gender_country(hashed) do
    <<gender::1, country::8>> = <<hashed::9>>
    # <<_::size(7), gender::size(1), country::size(8)>> = <<hashed::size(16)>>
    {gender, country}
  end

  def hash_gender_country_age(<<gender::size(1), age::size(7), _::size(24), country::size(8), _::size(24)>>) do
    <<hashed::16>> = <<gender::1, age::7, country::8>>
    hashed
    # {gender, country, age}
  end

  def unhash_gender_country_age(hashed) do
    <<gender::1, age::7, country::8>> = <<hashed::16>>
    {gender, country, age}
    # hashed
  end
end
