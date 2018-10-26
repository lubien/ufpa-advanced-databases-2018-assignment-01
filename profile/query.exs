defmodule Profile.Query do
  import ExProf.Macro

  def run do
    profile do
      IO.inspect(Database.Query.query())
    end
  end
end

Profile.Query.run()
