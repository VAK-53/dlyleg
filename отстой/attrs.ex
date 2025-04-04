defmodule Leg.Attrs do
  alias NimbleCSV.RFC4180, as: CSV

  @root_dir Application.fetch_env!(:dly, :root_dir)

  def storage_dir(), do: @root_dir <> "/apps/leg/priv/"

  def open_node_attrs() do
    #node_attrs_csv()
    storage_dir <> "node_attrs.csv"
    |> File.read!()
    |> CSV.parse_string()
    |> Enum.map(fn row ->
      %{
        name: Enum.at(row, 0),
        type: Enum.at(row, 2),
        default: Enum.at(row, 3),
        description: Enum.at(row, 8)
      }
    end)
    |> Enum.reject(&(&1.type == "closed"))
  end
end
