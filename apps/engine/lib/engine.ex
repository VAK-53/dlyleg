defmodule Engine do
  @moduledoc """
  Documentation for `Engine`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Engine.hello()
      :world

  """
  @root_dir Application.fetch_env!(:engine, :root_dir)

  def out_dir(), do: @root_dir <> "/priv/result"

  def write_file() do
    file_name = String.trim_trailing(IO.gets("Введите название файла для вывода без расширения\n"),"\n") <> ".dot"
    Path.join(out_dir(), file_name)
  end


  def toDot(graph) do
    {:ok, dot} = Graph.to_dot(graph)
    file_name = write_file()
    IO.puts(file_name)
    test = File.write(file_name, dot)
    IO.puts(test)
    case test do
      :ok    -> IO.puts("Выполнено")
      {:error, reason}  -> IO.puts("Failed to read file: #{reason}")
    end
  end
end
