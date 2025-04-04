defmodule Example do

@moduledoc """
 > import Example
 > pars
 ...
 > new
 > convert
 ...
 > dot
 ...
"""
  import DotLY
  import Leg
  import Engine

  # Конвейер грамматического разбора
  def pars do
    str = read()
    str |> lexer |> parser
  end

  # Конвейер загрузки графа в libgraph
  def new do
    Leg.new()
  end

  def convert do
    str = read()
    str |> lexer |> parser |> leg
  end

  # Конвейер экспорта графа в dot
  def dot do
    str = read()
    str |> lexer |> parser |> leg |> toDot
  end
end
