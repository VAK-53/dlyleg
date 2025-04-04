defmodule Leg.Attrs do
  alias NimbleCSV.RFC4180, as: CSV

  @root_dir Application.fetch_env!(:dly, :root_dir)

  @files ["node_attrs.csv", "edge_attrs.csv","graph_attrs.csv"]

  for file <- @files do
    area = String.to_atom(Enum.at(String.split(file, ~r/_\s?/),0))
    IO.puts(area)
    for row <- @root_dir <> "/apps/leg/priv/" <> file
        |> File.stream!()
        |> CSV.parse_stream() do
      attr  = Enum.at(row,0)
      types = Enum.at(row,1)
      attr = String.to_atom(:binary.copy(String.trim(attr)))
      #IO.puts(attr)
      types = Enum.map(String.split(types, ~r/,\s?/),
                       fn x -> String.trim(x) end)
      def type_of_attr(unquote(area), unquote(attr)), do: unquote(types)
    end
  end

  def type_of_attr(_area,_attr), do: []
  def valid_type?(area, attr), do: type_of_attr(area,attr) |> Enum.any?
end
