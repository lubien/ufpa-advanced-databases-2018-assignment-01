defmodule Database.Hashing do
  def hash_gender(<<gender::1, _::63>>) do
    gender
  end

  def unhash_gender(hashed) do
    hashed
  end

  def hash_gender_country(<<gender::1, _::31, country::8, _::24>>) do
    <<hashed::9>> = <<gender::1, country::8>>
    hashed
  end

  def unhash_gender_country(hashed) do
    <<gender::1, country::8>> = <<hashed::9>>
    {gender, country}
  end

  def hash_gender_country_age(<<gender::1, age::7, _::24, country::8, _::24>>) do
    <<hashed::16>> = <<gender::1, age::7, country::8>>
    hashed
  end

  def unhash_gender_country_age(hashed) do
    <<gender::1, age::7, country::8>> = <<hashed::16>>
    {gender, country, age}
  end

  def hash_country_scholarity(<<_::18, scholarity::2, _::12, country::8, _::24>>) do
    <<hashed::10>> = <<scholarity::2, country::8>>
    hashed
  end

  def unhash_country_scholarity(hashed) do
    <<scholarity::2, country::8>> = <<hashed::10>>
    {country, scholarity}
  end

  def hash_country_idiom(<<_::20, idiom::12, country::8, _::24>>) do
    <<hashed::20>> = <<idiom::12, country::8>>
    hashed
  end

  def unhash_country_idiom(hashed) do
    <<idiom::12, country::8>> = <<hashed::20>>
    {country, idiom}
  end

  def hash_country_coordinates(<<_::32, country::8, coordinates::24>>) do
    <<hashed::32>> = <<coordinates::24, country::8>>
    hashed
  end

  def unhash_country_coordinates(hashed) do
    <<coordinates::24, country::8>> = <<hashed::32>>
    {country, coordinates}
  end
end
