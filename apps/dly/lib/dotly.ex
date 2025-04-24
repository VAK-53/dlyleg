defmodule DotLY do
  @doc """
    чтение файла графа в нотации DOT и
    грамматический анализ.
    на выходе - список структуры графа
    """
  @root_dir Application.fetch_env!(:dly, :root_dir)

  def storage_dir(), do: @root_dir <> "/priv"

  def read() do
    file_name = String.trim_trailing(IO.gets("Введите название .dot файла без расширения\n"),"\n") <> ".dot"
    file_name = if String.at(file_name,0) do
                    Path.join(storage_dir(), file_name)
                end
    IO.puts("Обрабатываю: #{file_name}")
    case File.read(file_name) do
      {:ok, content}    -> content
      {:error, reason}  -> IO.puts("Failed to read file: #{reason}")
    end
  end

  def lexer(str) do
    case :dot_lexer.string(to_charlist(str)) do
      {:ok, tokens, _} ->
        IO.inspect(tokens)
        tokens
      {:error, reason, _} ->
        IO.puts(reason)
        []
    end
  end

 def parser(tokens) do
    with {:ok, result} <- :dot_parser.parse(tokens)
    do
      result
    else
      {:error, reason, _} ->
        IO.puts("Ошибка 1 парсера #{reason}.")
        []
      {:error, {pos, :dot_parser, reason}} ->
        IO.puts("Ошибка парсера в строке #{pos}.")
        IO.puts(reason)
        []
    end
  end
end
