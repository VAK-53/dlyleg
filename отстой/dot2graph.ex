defmodule Dot2graph do
  def parse(str) do
    with {:ok, tokens, _} <- :dot_lexer.string(to_charlist(str)),
         IO.inspect({tokens}),
         {:ok, result} <- :dot_parser.parse(tokens)
    do
      result
    else
      {:error, reason, _} ->
        IO.inspect("Ошибка 1 парсера.")
        reason
      {:error, {pos, :dot_parser, reason}} ->
        IO.inspect("Ошибка парсера в строке #{pos}.")
        to_string(reason)
    end
  end

  def lexer(str) do
    case :dot_lexer.string(to_charlist(str)) do
      {:ok, tokens, _} ->
        tokens
      {:error, reason, _} ->
        reason
    end
  end


  def read() do
    {:ok, cur_dir} = File.cwd()
    file_name = String.trim_trailing(IO.gets("Название файла без расширения?\n"),"\n")
    file_name = "/priv/" <> file_name <> ".dot"
    #IO.puts(file_name)
    case File.read(Path.join(cur_dir, file_name)) do
      {:ok, content}    -> content
      {:error, reason}  -> IO.puts("Failed to read file: #{reason}")
    end
  end
end
