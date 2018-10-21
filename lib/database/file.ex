defmodule Database.File do
  @default_file "people.db"
  @tuple_size 8
  @default_group_size 10_000

  def stream(file \\ @default_file) do
    File.stream!(file, [read_ahead: 200_000], @tuple_size)
  end

  def stream_chunks(file \\ @default_file, chunk_size) do
    read_ahead = chunk_size * 3
    File.stream!(file, [read_ahead: read_ahead], chunk_size)
  end

  def stream_groups(file \\ @default_file, group_size \\ @default_group_size) do
    stream_chunks(file, group_size * @tuple_size)
  end

  def multiple_stream_groups(file \\ @default_file, group_size \\ @default_group_size) do
    stream_count = 10

    with {:ok, stat} <- File.stat(file) do
      parts_byte_size = div(stat.size, stream_count)

      for i <- 0..stream_count do
        offset = parts_byte_size * i
        stream_groups_part(file, group_size, offset, parts_byte_size)
      end
    end
  end

  defp stream_groups_part(file, group_size, offset, parts_byte_size) do
    chunk_size = group_size * @tuple_size

    initial_acc = fn ->
      {:ok, file} = :file.open(file, [:read, :binary, :raw, {:read_ahead, 100_000}])
      :file.position(file, offset)
      {parts_byte_size, file}
    end

    next_step = fn
      {0, file} ->
        {:halt, {0, file}}

      {parts_byte_size, file} ->
        bytes_to_read = min(parts_byte_size, chunk_size)

        case :file.read(file, bytes_to_read) do
          {:ok, data} ->
            {[data], {parts_byte_size - bytes_to_read, file}}

          :eof ->
            {:halt, {parts_byte_size, file}}
        end
    end

    cleanup = fn {_parts_byte_size, file} ->
      :file.close(file)
    end

    Stream.resource(initial_acc, next_step, cleanup)
  end

  def multiple_group_streams(
        file \\ @default_file,
        group_size \\ @default_group_size,
        stream_count \\ 4
      ) do
    with {:ok, stat} <- File.stat(file) do
      parts_byte_size = div(stat.size, stream_count)
      chunk_byte_size = group_size * @tuple_size

      for i <- 0..stream_count do
        read_part(file, parts_byte_size * i, parts_byte_size, chunk_byte_size)
      end
    end
  end

  defp read_part(file, offset_in_bytes, size_in_bytes, chunk_byte_size) do
    {:ok, file} = :file.open(file, [:read, :binary])

    :file.position(file, offset_in_bytes)

    initial_acc = fn -> size_in_bytes end

    next_step = fn
      0 ->
        {:halt, 0}

      size_in_bytes ->
        bytes_to_read = min(size_in_bytes, chunk_byte_size)

        case :file.read(file, bytes_to_read) do
          {:ok, data} ->
            {[data], size_in_bytes - bytes_to_read}

          :eof ->
            {:halt, size_in_bytes}
        end
    end

    cleanup = fn _acc ->
      :file.close(file)
    end

    Stream.resource(initial_acc, next_step, cleanup)
  end
end
