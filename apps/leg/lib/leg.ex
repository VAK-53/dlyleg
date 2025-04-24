defmodule Leg do
  @moduledoc """
  Documentation for `Leg`.
  """

  @doc """
    преобразование списка в структура графа пакета libgraph
    """
  import Leg.Attrs
  @root_dir Application.fetch_env!(:leg, :root_dir)

  # создаём таблицу таблиц графов
  def new() do
    :ets.new(:global_table, [:named_table, :set])
    :ets.insert(:global_table, {:graphs, []}) # для дальнейшей проверки коллизии графа
  end

  # преобразуем список в граф libgraph
  def leg(branch) do
    [[:digraph, gr_name] | _] = branch # Из ветки вытаскиваем название графа

    [graphs: gr_names] = :ets.lookup(:global_table, :graphs)
    case Enum.member?(gr_names, gr_name) do
      true  -> IO.puts("Граф #{gr_name} уже существует")
      false -> IO.puts("Преобразуем результат анализа графа в таблицы")
               gr_names = [gr_name | gr_names]
               IO.puts(gr_names)
               :ets.insert(:global_table, {:graphs, gr_names}) # для дальнейшей проверки коллизии графа
               processing(branch, gr_name)
    end
  end

  def processing(branch, gr_name) do
     dot_tbl_name  = List.to_atom('dot_' ++ gr_name)
     appl_tbl_name = List.to_atom('appl_' ++ gr_name)
     routing_name  = List.to_atom('rout_' ++ gr_name)
     :ets.new(dot_tbl_name,  [:named_table, :bag]) # таблица графических атрибутов
     :ets.new(appl_tbl_name, [:named_table, :set]) # таблица прикладных атрибутов
     :ets.new(routing_name,  [:named_table, :bag]) # таблица маршрутизации
     graph = treatment(branch, dot_tbl_name, appl_tbl_name, routing_name)
     report(graph, dot_tbl_name, appl_tbl_name, routing_name, gr_name)
  end

  def treatment(branch, dot_tbl_name, appl_tbl_name, routing) do    # проход по элементам списка
    graph = Graph.new()
    Enum.reduce(branch, graph, fn element, graph -> el_insert(graph, element, dot_tbl_name, appl_tbl_name, routing)
                                       end )
  end

  def report(graph, dot_tbl_name, appl_tbl_name, routing, gr_name) do
    vnum = Graph.num_vertices(graph)
    enum = Graph.num_edges(graph)
    IO.puts("Выполненно:")
    IO.puts("узлов #{vnum}, ребер #{enum}")
    IO.puts("Таблица таблиц #{:global_table}")
    IO.inspect( :ets.tab2list(:global_table))
    IO.puts("Таблица атрибутов элементов графа #{gr_name}")
    IO.inspect(:ets.tab2list(dot_tbl_name))
    IO.puts("Таблица сервисов вершин графа #{gr_name}")
    IO.inspect(:ets.tab2list(appl_tbl_name))
    IO.puts("Таблица маршрутизация в графе #{gr_name}")
    IO.inspect(:ets.tab2list(routing))
    graph
  end

  # это шапка графа, которую уже обработали, поэтому пропускаем
  def el_insert(graph, [:digraph, name], _dot_table, _appl_table, _routing) do     #
    IO.puts("Начинаем конвертировать граф #{name}")
    graph
  end

  # вставляем узлы без атрибутов
  def el_insert(graph, [:node, node], dot_table, appl_table, _routing) do
    nodes = preparing(node) # это может быть и сборка
    nodes_insert(graph, dot_table, appl_table, nodes, [])
  end

  # вставляем узлы и их атрибуты
  def el_insert(graph, [:node, node, attrs], dot_table, appl_table, _routing) do      #
    nodes = preparing(node) # это может быть и сборка
    #attrs = Enum.filter(attrs, fn {key, _value} -> valid_type?(:node, key) end)
    nodes_insert(graph, dot_table, appl_table, nodes, attrs)
  end

  # вставляем ребра, узлы
  def el_insert(graph, [:op, [first | tail]], dot_table, appl_table, routing) do     #
    origins = preparing(first)

    graph = Enum.reduce(origins, graph,         # вставляем начальные узлы
                fn node, graph ->  case :ets.lookup(dot_table, node) do
                                        [] ->  node_insert(graph, dot_table, appl_table, node, [])
                                        [_ | _] -> graph
                                   end
                end )
    edges_insert(graph, dot_table, appl_table, routing, origins, tail, [])
  end

  # вставляем ребра, узлы и атрибуты рёбер
  def el_insert(graph, [:op, [first | tail], attrs], dot_table, appl_table, routing) do     #
    origins = preparing(first)
    attrs = Enum.filter(attrs, fn {key, _value} -> valid_type?(:edge, key) end)

    graph = Enum.reduce(origins,  graph,         # вставляем начальные узлы
                fn node, graph ->  case :ets.lookup(dot_table, node) do
                                        [] ->  node_insert(graph, dot_table, appl_table, node, [])
                                        [_ | _] -> graph
                                   end
                end )
    edges_insert(graph, dot_table, appl_table, routing, origins, tail, attrs)
  end

  # устанавливаем атрибуты графа
  def el_insert(graph, [:grph_attrs, {key, attr}], dot_table, _appl_table, _routing) do    #
    if valid_type?(:graph, key) do
      :ets.insert(dot_table, {:grph_attrs, {key, attr}})
    else
      IO.puts("Графовый атрибут #{key} отсутствует в списке разрешённых")
    end
    graph
  end

  # устанавливаем родовые атрибуты узлов
  def el_insert(graph, [:node_attrs, attrs], dot_table, _appl_table, _routing) do          #
    if attrs != [] do
      attrs = Enum.filter(attrs, fn {key, _value} -> valid_type?(:node, key) end)
      :ets.insert(dot_table, {:__node, attrs})
    end
    graph
  end

  # устанавливаем родовые атрибуты рёбра
  def el_insert(graph, [:edge_attrs, attrs], dot_table, _appl_table, _routing) do          #
    if attrs != [] do
      attrs = Enum.filter(attrs, fn {key, _value} -> valid_type?(:edge, key) end)
      :ets.insert(dot_table, {:__edge, attrs})
    end
    graph
  end

  def edges_insert(graph, dot_table, appl_table, routing, origins, tail, attrs) do
    [nexts | tail] = hd(tail)

    stocks = preparing(nexts)
    # вставляем в таблицу и граф следующие узлы !!!!
    graph = nodes_insert(graph, dot_table, appl_table, stocks, [])

    # генерируем списки ребер
    edges = for o <- origins, s <- stocks, do: {o, s}

    # вставляем ребра в graph и их атрибуты в таблицу
    graph=Enum.reduce(edges,
              graph,
              fn {o, s}, graph ->  edge_name = o <> "-" <> s
                                  new_attr =  {:label, edge_name}
                                  new_attrs = if attrs == [] do
                                        [new_attr]
                                      else
                                        [new_attr | attrs]
                                      end
                                  map = {edge_name, new_attrs}
                                  :ets.insert(dot_table, map)
                                  # маршрутизация
                                  :ets.insert(routing, {o, {:out, s}})
                                  :ets.insert(routing, {s, {:in, o}})
                                  Graph.add_edge(graph, o, s)
              end )
    # обрабатываем следующий узел/узлы
    graph = if tail != [] do
      edges_insert(graph, dot_table, appl_table, routing, stocks, tail, attrs)
    else
      graph
    end
    graph
  end

  # вставляем узел в граф и таблицу
  def node_insert(graph, dot_table, appl_table, node, attrs) do
    if attrs != [] do
      Enum.each(attrs, fn {key, value} ->
                        case valid_type?(:node, key) do
                            false -> :ets.insert(appl_table, {node, {key, value}})
                            true  -> :ets.insert(dot_table, {node, {key, value}})
                        end
                     end)
    end
    Graph.add_vertex(graph, node)
  end

  def nodes_insert(graph, dot_table, appl_table, nodes, attrs) do
    Enum.reduce(nodes,
        graph,
        fn node, graph ->  case :ets.lookup(dot_table, node) do
                                [] ->  node_insert(graph, dot_table, appl_table, node, attrs)
                                [_ | _] -> graph
                           end
        end )
  end

  def gr_save do
    # таблица всех графов
    [graphs: gr_names] = :ets.lookup(:global_table, :graphs)
    n = length(gr_names)
    Enum.each(1..n,
        fn x ->
            IO.write(x-1)
            IO.write("\t")
            IO.puts(Enum.at(gr_names, x-1))
        end )
    n = IO.gets("Введите номер нужного графа для сохранения ") #|> String.to_integer
    IO.inspect(n)

    i =  String.trim(n, "\n")
    IO.inspect(i)
    i = String.to_integer(i)
    gr_name = Enum.at(gr_names, i)
    IO.puts("сохраняю данные о графе #{gr_name} ")

    # сохраняем маршрутизацию
    routing_name  = List.to_atom('rout_' ++ gr_name)
    file_name = List.to_string(gr_name) <> ".rtg"
    file_name = Path.join(out_dir(), file_name)
    #list_of_tuples = :ets.tab2list(routing_name)
    #bytes = :erlang.term_to_binary(list_of_tuples)
    #File.write!(file_name, bytes)
    case :ets.tab2file(routing_name, String.to_charlist(file_name)) do
      :ok -> IO.puts("Записан файл маршрутизации #{file_name}")
      {:error, Reason} -> IO.puts(Reason)
    end

    # сохраняем прикладные атрибуты
    appl_name  = List.to_atom('appl_' ++ gr_name)
    file_name = List.to_string(gr_name) <> ".atr"
    file_name = Path.join(out_dir(), file_name)
    list_of_tuples = :ets.tab2list(appl_name)
    bytes = :erlang.term_to_binary(list_of_tuples)
    File.write!(file_name, bytes)
    case :ets.tab2file(appl_name, String.to_charlist(file_name)) do
      :ok -> IO.puts("Записан файл атрибутов #{file_name}")
      {:error, Reason} -> IO.puts(Reason)
    end
  end

  # Утилиты
  def out_dir(), do: @root_dir <> "/priv/result"

  def preparing(nodes) do
    if List.ascii_printable?(nodes) do
      [List.to_string(nodes)] # преобразуем лексему узла в string и забираем в список
    else
      Enum.map(nodes, fn x -> List.to_string(x) end )
    end
  end

  # первый элемент хвоста
  def get_tail_head(lst) do
    [_h|t] = lst
    [h|_t] = t
    h
  end

  def list_to_map(list) do
    list |> Map.new(fn [k, v] -> {k, v} end)
  end

end
