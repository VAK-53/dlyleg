defmodule Leg do
  @moduledoc """
  Documentation for `Leg`.
  """

  @doc """
    преобразование списка в структура графа пакета libgraph
    """
  import Leg.Attrs
  # создаём таблицу таблиц графов
  def new() do
    :ets.new(:table4tables, [:named_table, :bag])
  end

  # преобразуем список в граф libgraph
  def leg(branch) do
    IO.puts("Преобразуем в графовый список")
    #IO.inspect(branch)
    graph = Graph.new()
    [[:digraph, gr_name] | _] = branch
    tbl_name = List.to_atom(gr_name)
    test = :ets.lookup(:table4tables, tbl_name)
    graph=case test do
        [] ->   gr_table = :ets.new(tbl_name, [:named_table, :bag])
                :ets.insert(:table4tables, {tbl_name, gr_name})
                # проход по элементам списка
                graph=Enum.reduce(branch, graph, fn element, graph -> el_insert(graph, tbl_name, element)
                                                   end )
                vnum = Graph.num_vertices(graph)
                enum = Graph.num_edges(graph)
                IO.puts("Сделано")
                IO.puts("узлов #{vnum}, ребер #{enum}")
                IO.puts("Таблица таблиц #{:table4tables}")
                IO.inspect( :ets.tab2list(:table4tables))
                IO.puts("Таблица #{gr_table}")
                IO.inspect(:ets.tab2list(gr_table))
                graph
        [{^tbl_name, _}] -> IO.puts("Граф #{tbl_name} уже существует")
    end
    graph
  end

  # это шапка графа, уже обработали, поэтому пропускаем
  def el_insert(graph, _table, [:digraph, name]) do
    IO.puts("Начинаем конвертировать граф #{name}")
    graph
  end

  # вставляем узлы и их атрибуты
  def el_insert(graph, table, [:node, node] )   do
    nodes = preparing(node) # это может быть и сборка
    nodes_insert(graph, table, nodes, [])
  end

  def el_insert(graph, table, [:node, node, attrs] )   do
    nodes = preparing(node) # это может быть и сборка
    attrs = Enum.filter(attrs, fn {key, _value} -> valid_type?(:node, key) end)
    nodes_insert(graph, table, nodes, attrs)
  end

  # вставляем ребра, узлы и атрибуты рёбер
  def el_insert(graph, table, [:op, [first | tail]]) do
    origins = preparing(first)
    # вставляем начальные узлы
    graph = Enum.reduce(origins,
                        graph,
                        fn node, graph ->  case :ets.lookup(table, node) do
                                                [] ->  node_insert(graph, table, node, [])
                                                [_ | _] -> graph
                                           end
                        end )
    edges_insert(graph, table, origins, tail, [])
  end

  def el_insert(graph, table, [:op, [first | tail], attrs ]) do
    origins = preparing(first)
    attrs = Enum.filter(attrs, fn {key, _value} -> valid_type?(:edge, key) end)
    # вставляем начальные узлы
    graph = Enum.reduce(origins,
                        graph,
                        fn node, graph ->  case :ets.lookup(table, node) do
                                                [] ->  node_insert(graph, table, node, [])
                                                [_ | _] -> graph
                                           end
                              end )
    edges_insert(graph, table, origins, tail, attrs)
  end

  # устанавливаем атрибуты графа
  def el_insert(graph, table, [:grph_attrs, {key, attr}] )  do
    if valid_type?(:graph, key) do
      :ets.insert(table, {:grph_attrs, {key, attr}})
    else
      IO.puts("Графовый атрибут #{key} отсутствует в списке разрешённых")
    end
    graph
  end

  # устанавливаем родовые атрибуты узлов
  def el_insert(graph, table, [:node_attrs, attrs])  do
    if attrs != [] do
      attrs = Enum.filter(attrs, fn {key, _value} -> valid_type?(:node, key) end)
      :ets.insert(table, {:__node, attrs})
    end
    graph
  end

  # устанавливаем родовые атрибуты рёбра
  def el_insert(graph, table, [:edge_attrs, attrs])  do
    if attrs != [] do
      attrs = Enum.filter(attrs, fn {key, _value} -> valid_type?(:edge, key) end)
      :ets.insert(table, {:__edge, attrs})
    end
    graph
  end

  def edges_insert(graph, table, origins, tail, attrs) do
    [nexts | tail] = hd(tail)

    stocks = preparing(nexts)
    # вставляем в таблицу и граф следующие узлы !!!!
    graph = nodes_insert(graph, table, stocks, [])

    # генерируем списки ребер
    edges = for g <-origins, s<-stocks, do: {g, s}

    # вставляем ребра в graph и их атрибуты в таблицу
    graph=Enum.reduce(edges,
                      graph,
                      fn {g,s}, graph ->  edge_name = g <> "-" <> s
                                          new_attr =  {:name, edge_name}
                                          new_attrs = if attrs == [] do
                                            [new_attr]
                                          else
                                            [new_attr | attrs]
                                          end
                                          map = {edge_name, new_attrs}
                                          :ets.insert(table, map)
                                          Graph.add_edge(graph, g, s)
                      end )
    # обрабатываем следующий узел/узлы
    graph = if tail != [] do
      edges_insert(graph, table, stocks, tail, attrs)
    else
      graph
    end
    graph
  end

  # вставляем узел в граф и таблицу
  def node_insert(graph, table, node, attrs) do
    case :ets.lookup(table, node) do
           [] ->  :ets.insert(table, {node,{:x, nil}})
                  :ets.insert(table, {node,{:y, nil}})
                  # это фактически замена атрибутов
                  if attrs != [], do: :ets.insert(table, {node, attrs})
                  Graph.add_vertex(graph, node)
           [^node, _] -> graph
         end
  end

  def nodes_insert(graph, table, nodes, attrs) do
    Enum.reduce(nodes,
                graph,
                fn node, graph ->  case :ets.lookup(table, node) do
                                        [] ->  node_insert(graph, table, node, attrs)
                                        [_ | _] -> graph
                                   end
                end )
  end

  # Утилиты
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
