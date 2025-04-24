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
    read() |> lexer |> parser
  end

  # Конвейер загрузки графа в libgraph
  def new do
    Leg.new()
  end

  def convert do
    read() |> lexer |> parser |> leg
  end

  # Конвейер экспорта графа в dot
  def dot do
    read() |> lexer |> parser |> leg |> toDot
  end

  # Сохранение таблиц графа
  def save do
    gr_save()
  end
end
