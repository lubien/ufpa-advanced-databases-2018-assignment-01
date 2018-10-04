Benchee.run(
  %{
    "seed_by_writes" => fn -> Database.Seeder.seed_by_writes() end,
    "seed_by_writes_group of 10" => fn -> Database.Seeder.seed_by_writes_group(10) end,
    "seed_by_writes_group of 100" => fn -> Database.Seeder.seed_by_writes_group(100) end,
    "seed_by_writes_group of 1_000" => fn -> Database.Seeder.seed_by_writes_group(1_000) end,
    "seed_by_writes_group of 10_000" => fn -> Database.Seeder.seed_by_writes_group(10_000) end,
    "seed_by_writes_group of 100_000" => fn -> Database.Seeder.seed_by_writes_group(100_000) end,
    "seed_by_delayed_writes" => fn -> Database.Seeder.seed_by_delayed_writes() end,
    "seed_by_delayed_writes_group of 10" => fn ->
      Database.Seeder.seed_by_delayed_writes_group(10)
    end,
    "seed_by_delayed_writes_group of 100" => fn ->
      Database.Seeder.seed_by_delayed_writes_group(100)
    end,
    "seed_by_delayed_writes_group of 1_000" => fn ->
      Database.Seeder.seed_by_delayed_writes_group(1_000)
    end,
    "seed_by_delayed_writes_group of 10_000" => fn ->
      Database.Seeder.seed_by_delayed_writes_group(10_000)
    end,
    "seed_by_delayed_writes_group of 100_000" => fn ->
      Database.Seeder.seed_by_delayed_writes_group(100_000)
    end,
    "seed_by_writes_flow" => fn ->
      Database.Seeder.seed_by_writes_flow()
    end,
    "seed_by_delayed_writes_flow" => fn ->
      Database.Seeder.seed_by_delayed_writes_flow()
    end,
    "seed_by_writes_group_flow of 10_000" => fn ->
      Database.Seeder.seed_by_writes_group_flow(10_000)
    end,
    "seed_by_delayed_writes_group_flow of 10_000" => fn ->
      Database.Seeder.seed_by_delayed_writes_group_flow(10_000)
    end
  },
  time: 10,
  memory_time: 2
)
