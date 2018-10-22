defmodule Mix.Tasks.Query do
  use Mix.Task

  alias Database.Query

  def run(args) do
    {parsed_args, _} = OptionParser.parse!(args, strict: [query: :integer, db: :string])

    db = Keyword.get(parsed_args, :db, "priv/people.db")
    query = Keyword.get(parsed_args, :query, :undefined)

    if query == :undefined do
      IO.warn("Undefined --query option")
      System.halt(1)
    end

    if query < 1 or query > 10 do
      IO.warn("--query must be between 1 and 10")
      System.halt(1)
    end

    Query.run(db, query)
  end
end
