dataset =
  for i <- 1..10_000 do
    if rem(i, 1) == 0 do
      "males"
    else
      "females"
    end
  end

reduce_count = fn data ->
  data
  |> Enum.reduce(fn key, acc ->
    Map.update(acc, key, 1, &(&1 + 1))
  end)
end

Benchee.run(
  %{
    "reduce_count" => fn ->
      dataset
      |> Enum.reduce(%{}, fn key, acc ->
        Map.update(acc, key, 1, &(&1 + 1))
      end)
    end,
    "reduce match" => fn ->
      dataset
      |> Enum.reduce(%{"males" => 0, "females" => 0}, fn
        "males", %{"males" => males, "females" => females} ->
          %{"males" => males + 1, "females" => females}

        "females", %{"males" => males, "females" => females} ->
          %{"males" => males, "females" => females + 1}
      end)
    end,
    "reduce match tuple" => fn ->
      dataset
      |> Enum.reduce({0, 0}, fn
        "males", {males, females} ->
          %{"males" => males + 1, "females" => females}
          {males + 1, females}

        "females", {males, females} ->
          {males, females + 1}
      end)
    end
    # "seed_by_writes" => fn -> Database.Seeder.seed_by_writes() end,
    # "seed_by_writes_group of 10" => fn -> Database.Seeder.seed_by_writes_group(10) end,
    # "seed_by_writes_group of 100" => fn -> Database.Seeder.seed_by_writes_group(100) end,
    # "seed_by_writes_group of 1_000" => fn -> Database.Seeder.seed_by_writes_group(1_000) end,
    # "seed_by_writes_group of 10_000" => fn -> Database.Seeder.seed_by_writes_group(10_000) end,
    # "seed_by_writes_group of 100_000" => fn -> Database.Seeder.seed_by_writes_group(100_000) end,
    # "seed_by_delayed_writes" => fn -> Database.Seeder.seed_by_delayed_writes() end,
    # "seed_by_delayed_writes_group of 10" => fn ->
    #   Database.Seeder.seed_by_delayed_writes_group(10)
    # end,
    # "seed_by_delayed_writes_group of 100" => fn ->
    #   Database.Seeder.seed_by_delayed_writes_group(100)
    # end,
    # "seed_by_delayed_writes_group of 1_000" => fn ->
    #   Database.Seeder.seed_by_delayed_writes_group(1_000)
    # end,
    # "seed_by_delayed_writes_group of 10_000" => fn ->
    #   Database.Seeder.seed_by_delayed_writes_group(10_000)
    # end,
    # "seed_by_delayed_writes_group of 100_000" => fn ->
    #   Database.Seeder.seed_by_delayed_writes_group(100_000)
    # end,
    # "seed_by_writes_flow" => fn ->
    #   Database.Seeder.seed_by_writes_flow()
    # end,
    # "seed_by_delayed_writes_flow" => fn ->
    #   Database.Seeder.seed_by_delayed_writes_flow()
    # end,
    # "seed_by_writes_group_flow of 10_000" => fn ->
    #   Database.Seeder.seed_by_writes_group_flow(10_000)
    # end,
    # "seed_by_delayed_writes_group_flow of 10_000" => fn ->
    #   Database.Seeder.seed_by_delayed_writes_group_flow(10_000)
    # end
  },
  time: 10,
  memory_time: 2
)
