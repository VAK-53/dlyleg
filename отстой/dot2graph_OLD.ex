defmodule Dot2graph do
  def parse(str) do
    {:ok, tokens, _} = str |> to_char_list |> :dot_lexer.string
    result       = :dot_parser.parse(tokens)
    IO.inspect(result)
    case result do
      {:ok, ast} ->
        ast
      {:error, {position, :dot_parser, reason}} ->
        to_string(reason)
    end
  end

  def read() do
    {:ok, cur_dir} = File.cwd()
    #IO.puts("Текущий каталог: #{cur_dir}")
    file_name = "/priv/simple_graph.gv"

    case File.read(Path.join(cur_dir, file_name)) do
      {:ok, content} -> IO.puts("Content of file:\n#{content}")
                        content
      {:error, reason} -> IO.puts("Failed to read file: #{reason}")
    end
  end
end
