defmodule Mix.Tasks.Export do
  use Mix.Task

  alias Database.Export

  def run(_) do
    Export.run()
  end
end
