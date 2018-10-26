defmodule Profile.Query do
  def run do
    :fprof.apply(&Database.Query.query/0, [])
    :fprof.profile()
    :fprof.analyse([
      callers: true,
      sort: :own,
      totals: true,
      details: true
    ])
  end
end

Profile.Query.run()
