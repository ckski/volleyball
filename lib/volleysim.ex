defmodule Volleysim do

  # To run, install Elixir and run from command-line
  # $ mix deps.get
  # $ iex -S mix
  # iex(1)> Volleysim.process_file("gamedata.json", "boxscore.json") 


  # Data cleaning notes:

  # names have typos / not standard, appears differently across files, count instances to resolve

  # Sam Taylor parks / Sam Taylor Parks , Daniel Eikland rod / Rod
  # Pearce / Pearson
  # Elliott versus Elliot
  # Konel / Kornel
  # Nick / Nicholas

  # first last / last,first


  # Volleysim.rollup(facts, [:player]) |> Volleysim.add_derived_measure(:hit_pct, [:kill, :attack_error, :kill_attempt], fn k, e, ta -> if(ta == 0, do: 0, else: Float.round((k - e) / ta, 3)) end)


  # Action influencer rule

  # use rule if fun 1 == true, apply rule when game state is ?, apply to select players fun, 

  # If state filter_fun, then select players -> set influencer on action to 
  # {filter_fun, selector_fun, set_influencer_fun}

  # Alternatives need to get updated! to balance out with 1 probability sum

  # stats_db

  # player :: {name, id, stats, quality_ratings, state, action p map, action influencers}
  # action p map :: %{ action => base_probability }

  # game state :: { current_rotations, cur_positions, points :: %{set => {home, visiting}, }, set num, sets won, action_history}

  # team :: { name, id, players :: [], stats, state?, qaulity ratings}

  # stats :: %{}

  # KEY
  # SP=Set played
  # A+Assists
  # K=Kills
  # E = Errors
  # D = Digs
  # PCT = %
  # BHE=Ball Handling Errors
  # TA = Total Attempts
  # RE = Receiving Errors
  # RA = Reception Attempts
  # BS = Block Solos
  # BA = Block Assists
  # BE = Block Errors
  # SA = Service Aces
  # SE = Service Errors
  # ATT = Service Attempts
  # TEAM BLOCKS = BS + 1/2 BA
  # HITTING PTC = (K -E) TA
  # PTS = K + SA+BS+1/2 BA



  # Configuration for the data cube
  @dimension_order %{game: 10, set: 20, team: 30, player: 40, score_gap: 50, serve_streak: 60}

  @boxscore_dir "game_data/canadawest.org/boxscore/"

  def simulate_game() do
    # simulate set, test win condition
  end


  def simulate_set() do
    # simulate round, test_win condition
    # apply rotation, repeat
  end


  def simulate_round() do

      rotation = [1, 2, 3, 4, 5, 6]

      # Teams are :home | :visiting
      # do_action(state, :serve, :home)

      # calc_probability(), 

      # serve -> ace | error | ..

  end

  def rotate(list), do: tl(list) ++ [hd(list)]

  def load_cache_file(cache_file) do
    start_time = :erlang.monotonic_time(1)
    result = File.read!(cache_file) |> :erlang.binary_to_term
    IO.puts("Loading cache file took #{:erlang.monotonic_time(1) - start_time} seconds")
    result
  end

  def batch_job do
    # Trinity Western 2016-17
    twu_files = [
      "2016-10-28 Trinity Western vs Regina.json",
      "2016-10-29 Trinity Western vs Regina.json",
      "2016-11-04 Calgary vs Trinity Western.json",
      "2016-11-05 Calgary vs Trinity Western.json",
      "2016-11-18 MacEwan vs Trinity Western.json",
      "2016-11-19 MacEwan vs Trinity Western.json",
      "2016-11-25 Trinity Western vs UBC.json",
      "2016-11-26 UBC vs Trinity Western.json",
      "2016-12-02 Trinity Western vs Mount Royal.json",
      "2016-12-03 Trinity Western vs Mount Royal.json",
      "2017-01-06 Saskatchewan vs Trinity Western.json",
      "2017-01-07 Saskatchewan vs Trinity Western.json",
      "2017-01-13 Thompson Rivers vs Trinity Western.json",
      "2017-01-14 Thompson Rivers vs Trinity Western.json",
      "2017-01-20 Trinity Western vs UBC Okanagan.json",
      "2017-01-21 Trinity Western vs UBC Okanagan.json",
      "2017-01-27 Trinity Western vs Alberta.json",
      "2017-01-28 Trinity Western vs Alberta.json",
      "2017-02-03 Brandon vs Trinity Western.json",
      "2017-02-04 Brandon vs Trinity Western.json",
      "2017-02-17 Trinity Western vs Winnipeg.json",
      "2017-02-18 Trinity Western vs Winnipeg.json",
      "2017-02-24 Manitoba vs Trinity Western.json",
      "2017-02-25 Manitoba vs Trinity Western.json"
    ]

    # UBC 2016-17
    ubc_files = [
      "2016-10-28 UBC vs Saskatchewan.json",
      "2016-10-29 UBC vs Saskatchewan.json",
      "2016-11-04 Winnipeg vs UBC.json",
      "2016-11-05 Winnipeg vs UBC.json",
      "2016-11-18 UBC vs Thompson Rivers.json",
      "2016-11-19 UBC vs Thompson Rivers.json",
      # "2016-11-25 Trinity Western vs UBC.json",
      # "2016-11-26 UBC vs Trinity Western.json",
      "2016-12-02 UBC vs MacEwan.json",
      "2016-12-03 UBC vs MacEwan.json",
      "2017-01-06 UBC Okanagan vs UBC.json",
      "2017-01-07 UBC Okanagan vs UBC.json",
      "2017-01-13 UBC vs Manitoba.json",
      "2017-01-14 UBC vs Manitoba.json",
      "2017-01-20 Mount Royal vs UBC.json",
      "2017-01-21 Mount Royal vs UBC.json",
      "2017-01-27 UBC vs Calgary.json",
      "2017-01-28 UBC vs Calgary.json",
      "2017-02-10 Regina vs UBC.json",
      "2017-02-11 Regina vs UBC.json",
      "2017-02-17 Alberta vs UBC.json",
      "2017-02-18 Alberta vs UBC.json",
      "2017-02-24 UBC vs Brandon.json",
      "2017-02-25 UBC vs Brandon.json",
    ]

    tru_files = [
      "2016-10-28 Alberta vs Thompson Rivers.json",
      "2016-10-29 Alberta vs Thompson Rivers.json",
      "2016-11-04 Thompson Rivers vs Brandon.json",
      "2016-11-05 Thompson Rivers vs Brandon.json",
      "2016-11-11 Mount Royal vs Thompson Rivers.json",
      "2016-11-12 Mount Royal vs Thompson Rivers.json",
      # "2016-11-18 UBC vs Thompson Rivers.json",
      # "2016-11-19 UBC vs Thompson Rivers.json",
      "2016-11-25 Thompson Rivers vs MacEwan.json",
      "2016-11-26 Thompson Rivers vs MacEwan.json",
      "2017-01-05 Thompson Rivers vs Calgary.json",
      "2017-01-06 Thompson Rivers vs Calgary.json",
      # "2017-01-13 Thompson Rivers vs Trinity Western.json",
      # "2017-01-14 Thompson Rivers vs Trinity Western.json",
      "2017-01-27 Regina vs Thompson Rivers.json",
      "2017-01-28 Regina vs Thompson Rivers.json",
      "2017-02-03 Thompson Rivers vs Manitoba.json",
      "2017-02-04 Thompson Rivers vs Manitoba.json",
      "2017-02-10 Winnipeg vs Thompson Rivers.json",
      "2017-02-11 Winnipeg vs Thompson Rivers.json",
      "2017-02-16 UBC Okanagan vs Thompson Rivers.json",
      "2017-02-18 Thompson Rivers vs UBC Okanagan.json",
      "2017-02-24 Thompson Rivers vs Saskatchewan.json",
      "2017-02-25 Thompson Rivers vs Saskatchewan.json"
    ]

    alberta_files = [
      # "2016-10-28 Alberta vs Thompson Rivers.json",
      # "2016-10-29 Alberta vs Thompson Rivers.json",
      "2016-11-10 Alberta vs MacEwan.json",
      "2016-11-11 MacEwan vs Alberta.json",
      "2016-11-18 Alberta vs Manitoba.json",
      "2016-11-19 Alberta vs Manitoba.json",
      "2016-11-25 Winnipeg vs Alberta.json",
      "2016-11-26 Winnipeg vs Alberta.json",
      "2016-12-02 Regina vs Alberta.json",
      "2016-12-03 Regina vs Alberta.json",
      "2017-01-06 Alberta vs Brandon.json",
      "2017-01-07 Alberta vs Brandon.json",
      "2017-01-20 Alberta vs Saskatchewan.json",
      "2017-01-21 Alberta vs Saskatchewan.json",
      # "2017-01-27 Trinity Western vs Alberta.json",
      # "2017-01-28 Trinity Western vs Alberta.json",
      "2017-02-03 Mount Royal vs Alberta.json",
      "2017-02-04 Mount Royal vs Alberta.json",
      "2017-02-10 UBC Okanagan vs Alberta.json",
      "2017-02-11 UBC Okanagan vs Alberta.json",
      # "2017-02-17 Alberta vs UBC.json",
      # "2017-02-18 Alberta vs UBC.json",
      "2017-02-24 Alberta vs Calgary.json",
      "2017-02-25 Alberta vs Calgary.json"
    ]

    macewan_files = [
      "2016-10-28 MacEwan vs Winnipeg.json",
      "2016-10-29 MacEwan vs Winnipeg.json",
      "2016-11-04 Saskatchewan vs MacEwan.json",
      "2016-11-05 Saskatchewan vs MacEwan.json",
      # "2016-11-10 Alberta vs MacEwan.json",
      # "2016-11-11 MacEwan vs Alberta.json",
      # "2016-11-18 MacEwan vs Trinity Western.json",
      # "2016-11-19 MacEwan vs Trinity Western.json",
      # "2016-11-25 Thompson Rivers vs MacEwan.json",
      # "2016-11-26 Thompson Rivers vs MacEwan.json",
      # "2016-12-02 UBC vs MacEwan.json",
      # "2016-12-03 UBC vs MacEwan.json",
      "2017-01-13 Calgary vs MacEwan.json",
      "2017-01-14 Calgary vs MacEwan.json",
      "2017-01-20 Brandon vs MacEwan.json",
      "2017-01-21 Brandon vs MacEwan.json",
      "2017-01-27 MacEwan vs Mount Royal.json",
      "2017-01-28 MacEwan vs Mount Royal.json",
      "2017-02-03 MacEwan vs Regina.json",
      "2017-02-04 MacEwan vs Regina.json",
      "2017-02-10 Manitoba vs MacEwan.json",
      "2017-02-11 Manitoba vs MacEwan.json",
      "2017-02-24 MacEwan vs UBC Okanagan.json",
      "2017-02-25 MacEwan vs UBC Okanagan.json"
    ]

    winnipeg_files = [
      # "2016-10-28 MacEwan vs Winnipeg.json",
      # "2016-10-29 MacEwan vs Winnipeg.json",
      # "2016-11-04 Winnipeg vs UBC.json",
      # "2016-11-05 Winnipeg vs UBC.json",
      "2016-11-12 Winnipeg vs Calgary.json",
      "2016-11-13 Winnipeg vs Calgary.json",
      # "2016-11-25 Winnipeg vs Alberta.json",
      # "2016-11-26 Winnipeg vs Alberta.json",
      "2016-12-01 Winnipeg vs Brandon.json",
      "2016-12-02 Brandon vs Winnipeg.json",
      "2016-12-07 Manitoba vs Winnipeg.json",
      "2016-12-08 Winnipeg vs Manitoba.json",
      "2017-01-13 UBC Okanagan vs Winnipeg.json",
      "2017-01-14 UBC Okanagan vs Winnipeg.json",
      "2017-01-20 Winnipeg vs Regina.json",
      "2017-01-21 Winnipeg vs Regina.json",
      "2017-01-27 Saskatchewan vs Winnipeg.json",
      "2017-01-28 Saskatchewan vs Winnipeg.json",
      # "2017-02-10 Winnipeg vs Thompson Rivers.json",
      # "2017-02-11 Winnipeg vs Thompson Rivers.json",
      # "2017-02-17 Trinity Western vs Winnipeg.json",
      # "2017-02-18 Trinity Western vs Winnipeg.json",
      "2017-02-24 Mount Royal vs Winnipeg.json",
      "2017-02-25 Mount Royal vs Winnipeg.json"
    ]

    calgary_files = [
      # "2016-11-04 Calgary vs Trinity Western.json",
      # "2016-11-05 Calgary vs Trinity Western.json",
      # "2016-11-12 Winnipeg vs Calgary.json",
      # "2016-11-13 Winnipeg vs Calgary.json",
      "2016-11-18 Calgary vs Brandon.json",
      "2016-11-19 Calgary vs Brandon.json",
      "2016-11-24 Mount Royal vs Calgary.json",
      "2016-11-26 Calgary vs Mount Royal.json",
      "2016-12-02 Calgary vs UBC Okanagan.json",
      "2016-12-03 Calgary vs UBC Okanagan.json",
      # "2017-01-05 Thompson Rivers vs Calgary.json",
      # "2017-01-06 Thompson Rivers vs Calgary.json",
      # "2017-01-13 Calgary vs MacEwan.json",
      # "2017-01-14 Calgary vs MacEwan.json",
      "2017-01-20 Calgary vs Manitoba.json",
      "2017-01-21 Calgary vs Manitoba.json",
      # "2017-01-27 UBC vs Calgary.json",
      # "2017-01-28 UBC vs Calgary.json",
      "2017-02-10 Calgary vs Saskatchewan.json",
      "2017-02-11 Calgary vs Saskatchewan.json",
      "2017-02-17 Regina vs Calgary.json",
      "2017-02-18 Regina vs Calgary.json",
      # "2017-02-24 Alberta vs Calgary.json",
      # "2017-02-25 Alberta vs Calgary.json"
    ]

    brandon_files = [
      "2016-10-28 Brandon vs UBC Okanagan.json",
      "2016-10-29 Brandon vs UBC Okanagan.json",
      # "2016-11-04 Thompson Rivers vs Brandon.json",
      # "2016-11-05 Thompson Rivers vs Brandon.json",
      # "2016-11-18 Calgary vs Brandon.json",
      # "2016-11-19 Calgary vs Brandon.json",
      "2016-11-25 Brandon vs Saskatchewan.json",
      "2016-11-26 Brandon vs Saskatchewan.json",
      # "2016-12-01 Winnipeg vs Brandon.json",
      # "2016-12-02 Brandon vs Winnipeg.json",
      # "2017-01-06 Alberta vs Brandon.json",
      # "2017-01-07 Alberta vs Brandon.json",
      "2017-01-12 Regina vs Brandon.json",
      "2017-01-13 Regina vs Brandon.json",
      # "2017-01-20 Brandon vs MacEwan.json",
      # "2017-01-21 Brandon vs MacEwan.json",
      "2017-01-27 Manitoba vs Brandon.json",
      "2017-01-28 Manitoba vs Brandon.json",
      # "2017-02-03 Brandon vs Trinity Western.json",
      # "2017-02-04 Brandon vs Trinity Western.json",
      "2017-02-10 Brandon vs Mount Royal.json",
      "2017-02-11 Brandon vs Mount Royal.json",
      # "2017-02-24 UBC vs Brandon.json",
      # "2017-02-25 UBC vs Brandon.json"
    ]

    sask_files = [
      # "2016-10-28 UBC vs Saskatchewan.json",
      # "2016-10-29 UBC vs Saskatchewan.json",
      # "2016-11-04 Saskatchewan vs MacEwan.json",
      # "2016-11-05 Saskatchewan vs MacEwan.json",
      "2016-11-18 Saskatchewan vs Regina.json",
      "2016-11-19 Saskatchewan vs Regina.json",
      # "2016-11-25 Brandon vs Saskatchewan.json",
      # "2016-11-26 Brandon vs Saskatchewan.json",
      "2016-12-02 Manitoba vs Saskatchewan.json",
      "2016-12-03 Manitoba vs Saskatchewan.json",
      # "2017-01-06 Saskatchewan vs Trinity Western.json",
      # "2017-01-07 Saskatchewan vs Trinity Western.json",
      # "2017-01-20 Alberta vs Saskatchewan.json",
      # "2017-01-21 Alberta vs Saskatchewan.json",
      # "2017-01-27 Saskatchewan vs Winnipeg.json",
      # "2017-01-28 Saskatchewan vs Winnipeg.json",
      "2017-02-03 Saskatchewan vs UBC Okanagan.json",
      "2017-02-04 Saskatchewan vs UBC Okanagan.json",
      # "2017-02-10 Calgary vs Saskatchewan.json",
      # "2017-02-11 Calgary vs Saskatchewan.json",
      "2017-02-17 Saskatchewan vs Mount Royal.json",
      "2017-02-18 Saskatchewan vs Mount Royal.json",
      # "2017-02-24 Thompson Rivers vs Saskatchewan.json",
      # "2017-02-25 Thompson Rivers vs Saskatchewan.json"
    ]

    regina_files = [
      # "2016-10-28 Trinity Western vs Regina.json",
      # "2016-10-29 Trinity Western vs Regina.json",
      "2016-11-04 Regina vs Manitoba.json",
      "2016-11-05 Regina vs Manitoba.json",
      # "2016-11-18 Saskatchewan vs Regina.json",
      # "2016-11-19 Saskatchewan vs Regina.json",
      "2016-11-25 UBC Okanagan vs Regina.json",
      "2016-11-26 UBC Okanagan vs Regina.json",
      # "2016-12-02 Regina vs Alberta.json",
      # "2016-12-03 Regina vs Alberta.json",
      "2017-01-06 Mount Royal vs Regina.json",
      "2017-01-07 Mount Royal vs Regina.json",
      # "2017-01-12 Regina vs Brandon.json",
      # "2017-01-13 Regina vs Brandon.json",
      # "2017-01-20 Winnipeg vs Regina.json",
      # "2017-01-21 Winnipeg vs Regina.json",
      # "2017-01-27 Regina vs Thompson Rivers.json",
      # "2017-01-28 Regina vs Thompson Rivers.json",
      # "2017-02-03 MacEwan vs Regina.json",
      # "2017-02-04 MacEwan vs Regina.json",
      # "2017-02-10 Regina vs UBC.json",
      # "2017-02-11 Regina vs UBC.json",
      # "2017-02-17 Regina vs Calgary.json",
      # "2017-02-18 Regina vs Calgary.json"
    ]

    ubco_files = [
      # "2016-10-28 Brandon vs UBC Okanagan.json",
      # "2016-10-29 Brandon vs UBC Okanagan.json",
      # "2016-11-11 Manitoba vs UBC Okanagan.json",
      "2016-11-12 Manitoba vs UBC Okanagan.json",
      "2016-11-18 UBC Okanagan vs Mount Royal.json",
      "2016-11-19 UBC Okanagan vs Mount Royal.json",
      # "2016-11-25 UBC Okanagan vs Regina.json",
      # "2016-11-26 UBC Okanagan vs Regina.json",
      # "2016-12-02 Calgary vs UBC Okanagan.json",
      # "2016-12-03 Calgary vs UBC Okanagan.json",
      # "2017-01-06 UBC Okanagan vs UBC.json",
      # "2017-01-07 UBC Okanagan vs UBC.json",
      # "2017-01-13 UBC Okanagan vs Winnipeg.json",
      # "2017-01-14 UBC Okanagan vs Winnipeg.json",
      # "2017-01-20 Trinity Western vs UBC Okanagan.json",
      # "2017-01-21 Trinity Western vs UBC Okanagan.json",
      # "2017-02-03 Saskatchewan vs UBC Okanagan.json",
      # "2017-02-04 Saskatchewan vs UBC Okanagan.json",
      # "2017-02-10 UBC Okanagan vs Alberta.json",
      # "2017-02-11 UBC Okanagan vs Alberta.json",
      # "2017-02-16 UBC Okanagan vs Thompson Rivers.json",
      # "2017-02-18 Thompson Rivers vs UBC Okanagan.json",
      # "2017-02-24 MacEwan vs UBC Okanagan.json",
      # "2017-02-25 MacEwan vs UBC Okanagan.json"
    ]

    mru_files = [
      "2016-10-28 Manitoba vs Mount Royal.json",
      "2016-10-29 Manitoba vs Mount Royal.json"
    ]

    # Manitoba files are all already covered.


    cache_obj = case File.read("cached_facts") do
      {:ok, bin} -> :erlang.binary_to_term(bin)
      {:error, :enoent} -> %{games: [], data: %{}}
    end

    file_sets = [{"Trinity Western 2016-17", twu_files}, 
                 {"UBC 2016-17", ubc_files}, 
                 {"TRU 2016-17", tru_files}, 
                 {"Alberta 2016-17", alberta_files},
                 {"MacEwan 2016-17", macewan_files},
                 {"Winnipeg 2016-17", winnipeg_files},
                 {"Calgary 2016-17", calgary_files},
                 {"Brandon 2016-17", brandon_files},
                 {"Saskatchewan 2016-17", sask_files},
                 {"Regina 2016-17", regina_files},
                 {"UBCO 2016-17", ubco_files},
                 {"Mount Royal 2016-17", mru_files}]
    # file_sets = [{"Alberta 2016-17", alberta_files}]

    cache_obj = Enum.reduce file_sets, cache_obj, fn {dir, files}, cache_obj ->
      cache_obj = Enum.reduce files, cache_obj, fn file, acc ->
        process_file_series("game_data/canadawest.org/" <> dir <> "/" <> file, acc)
      end
    end

    # cache_obj = Enum.reduce ubc_files, cache_obj, fn file, acc ->
    #   process_file_series("game_data/canadawest.org/UBC 2016-17/" <> file, acc)
    # end

    # cache_obj = Enum.reduce ubc_files, cache_obj, fn file, acc ->
    #   process_file_series("game_data/canadawest.org/UBC 2016-17/" <> file, acc)
    # end

    File.write!("cached_facts", :erlang.term_to_binary(cache_obj))
    :ok
  end

  def process_file_series(pbp_file, cache_obj) do
    IO.puts("Processing: #{pbp_file}")
    {:ok, game_id, facts} = process_play_by_play(File.read!(pbp_file))

    if game_id in cache_obj[:games] do
      IO.puts("Game already found in cache: #{game_id}")
    else
      cache_obj = update_in(cache_obj[:games], &([game_id | &1]))
      |> update_in([:data], &Map.merge(&1, facts))
    end

    cache_obj
  end


  def process_file(pbp_file, cache_file) do
    cache_obj = case File.read(cache_file) do
      {:ok, bin} -> :erlang.binary_to_term(bin)
      {:error, :enoent} -> %{games: [], data: %{}}
    end
    IO.puts("Processing: #{pbp_file}")
    {:ok, game_id, facts} = process_play_by_play(File.read!(pbp_file))

    unless game_id in cache_obj[:games] do
      cache_obj = update_in(cache_obj[:games], &([game_id | &1]))
      |> update_in([:data], &Map.merge(&1, facts))

      IO.puts("Game #{game_id} written to cache")

      File.write!(cache_file, :erlang.term_to_binary(cache_obj))
    end

    :ok
  end

  def process_play_by_play(pbp_binary) do
    root = Poison.decode!(pbp_binary)
    # IO.inspect root
    game_id = root["id"]
    date = root["date"] |> Date.from_iso8601!
    [_, base_id] = Regex.run(~r/\/(.*?)$/, game_id)

    IO.puts("process_play_by_play game #{base_id}, #{to_string(date)}")

    bscore_binary = File.read!(@boxscore_dir <> base_id <> ".json")

    boxscore = Poison.decode!(bscore_binary)

    season = if date.month < 7, do: {date.year - 1, date.year}, else: {date.year, date.year + 1}


    [team_1, team_2] = root["teams"]
    [team_1_id, team_1_name] = team_1
    [team_2_id, team_2_name] = team_2

    t1_players = Enum.map boxscore["teams"][team_1_name], fn
      [id, name, %{"TA" => ta, "DIGS" => digs}] -> {name, {abbreviate_name(team_1_name), id, name, %{:kill_attempt => ta, :digs => digs}}}
    end

    t2_players = Enum.map boxscore["teams"][team_2_name], fn
      [id, name, %{"TA" => ta, "DIGS" => digs}] -> {name, {abbreviate_name(team_2_name), id, name, %{:kill_attempt => ta, :digs => digs}}}
    end

    # player name => player info :: {abbr team, player id, name, stats}
    players = Enum.into t1_players ++ t2_players, %{}
    
    sets = Map.keys root["sets"]
    facts_fine_grain = Enum.reduce sets, %{}, fn key, acc ->
      Map.merge acc, process_set(game_id, String.to_integer(key), root["sets"][key], root["teams"], players)
    end

    # facts_fine_grain = Enum.flat_map(sets, &elem(&1, 1)) |> Enum.into(%{})

    # IO.puts("boxscore for ta per set: #{inspect(boxscore["ta_per_set"])}")

    get_kill_attempt_for_set = fn set, team ->
      boxscore["ta_per_set"][team] |> Enum.at(set - 1)
    end

    # Enum.reduce point_facts_for_set 

    # team_sum_per_set = rollup(facts_fine_grain, [:set, :team], drop_measures: [:sets_played])

    # Insert kill attempt stats (per set) into facts.
    facts_fine_grain = Enum.reduce [team_1_name, team_2_name], facts_fine_grain, fn team, acc ->
      team_abbr = abbreviate_name(team)
      Enum.reduce Enum.with_index(boxscore["ta_per_set"][team], 1), acc, fn {ta_stat, set_i}, acc -> 
        insert_fact acc, [game: game_id, set: set_i, team: team_abbr], %{kill_attempt: ta_stat}
      end
    end

    # IO.inspect team_sum_per_set

    # IO.puts("--------------------------")

    # IO.puts("rollup [:team, :player]")
    # player_game_sums = rollup(facts_fine_grain, [:team, :player])

    # IO.inspect(player_game_sums)


    # Insert extra stats from the box score
    facts_fine_grain = Enum.reduce Map.keys(boxscore["teams"]), facts_fine_grain, fn team, acc ->
      Enum.reduce boxscore["teams"][team], acc, fn [_player_id, player_name, %{"TA" => ta, "DIGS" => digs}], acc ->
        insert_fact acc, [game: game_id, team: abbreviate_name(team), player: player_name], %{kill_attempt: ta, digs: digs}
      end
    end

    # IO.puts("ta_stats: #{inspect(ta_stats)}")
    # IO.puts("----------------------------------------------")

    # IO.inspect player_game_sums


    # IO.puts("--------------------------------------------")

    # team_game_sums = rollup(player_game_sums, [:team], drop_measures: [:sets_played])

    # IO.puts("Rollup [:team]")
    # IO.inspect(team_game_sums)


    # IO.puts("--------------------------------------------")

    # IO.inspect(player_game_sums, limit: :infinity)
    # IO.puts("--------------------------------------------")


    # facts_fine_grain ++ Map.values(player_game_sums)
    # all_facts = facts_fine_grain |> join_facts(team_game_sums) |> join_facts(player_game_sums)
    all_facts = facts_fine_grain

    all_facts = insert_fact(all_facts, [game: game_id, team: abbreviate_name(team_1_name)], %{games: 1})
    |> insert_fact([game: game_id, team: abbreviate_name(team_2_name)], %{games: 1})

    {:ok, game_id, all_facts}
  end

  def abbreviate_name(name) do
    case name do
      "Trinity Western" -> "TWU"
      "Regina" -> "REG"
      "Calgary" -> "CGY"
      "MacEwan" -> "MACEWAN"
      "UBC" -> "UBC"
      "Mount Royal" -> "MRU"
      "Saskatchewan" -> "SASK"
      "Thompson Rivers" -> "TRU"
      "UBC Okanagan" -> "UBCO"
      "Alberta" -> "AB"
      "Brandon" -> "BRNM"
      "Winnipeg" -> "WPGM"
      "Manitoba" -> "MAN"
      _ -> throw("unknown name abbrv: #{name}")
    end
  end

  def process_set(game_id, set_i, set, teams, players) do
    starters = set["starters"]
    events = set["events"]

    [team_x_abbr, team_y_abbr] = Map.keys(starters)


    lookup_player_team = fn player ->
      if players[player] == nil, do: throw("Missing player: #{player} from: #{inspect(players)}")

      {team_abbr, _, _, _} = players[player]
      team_abbr
    end

    # key is the set of dimensions
    # stat => measure
    insert_set_fact = fn facts, dims, stat, val ->
      dims = if dims[:team] == nil, do: put_in(dims[:team], lookup_player_team.(dims[:player])), else: dims
      dims = put_in dims[:set], set_i
      dims = put_in dims[:game], game_id
      insert_fact facts, dims, %{stat => val}
    end

    not_team = fn 
      ^team_x_abbr -> team_y_abbr
      ^team_y_abbr -> team_x_abbr
    end

    facts = %{}

    facts = Enum.reduce starters, facts, fn {team_abbr, players}, acc ->
      Enum.reduce players, acc, fn player, acc ->
        insert_set_fact.(acc, [team: team_abbr, player: player], :sets_played, [set_i])
      end
    end

    update_last_server = fn state, s ->
      # Update last server state
      update_in state, [Access.key(:last_server)], fn 
        nil -> {s, 1}
        {^s, i} -> {s, i+1}
        {_, _} -> {s, 1}
      end
    end

    left = team_x_abbr
    right = team_y_abbr

    update_streaming_score = fn state, point_to_team ->
      update_in state, [Access.key(:score_stream)], fn
        nil when point_to_team == left -> {point_to_team, {1, 0}, 0}
        nil when point_to_team == right -> {point_to_team, {0, 1}, 0}

        {^point_to_team, {l, r}, streak} when point_to_team == left -> {point_to_team, {l+1, r}, streak+1}
        {^point_to_team, {l, r}, streak} when point_to_team == right -> {point_to_team, {l, r+1}, streak+1}

        {_, {l, r}, _streak} = all when point_to_team == left -> {point_to_team, {l+1, r}, 0}
        {_, {l, r}, _streak} = all when point_to_team == right -> {point_to_team, {l, r+1}, 0}
      end
    end

    get_score_gap = fn state, team ->
      case state[:score_stream] do
        nil -> 0    # Score at beginning is 0-0

        {_team, {l, r}, _streak} when team == left and l-r > 5 -> 2
        {_team, {l, r}, _streak} when team == left and l-r > 0 -> 1
        {_team, {l, r}, _streak} when team == left and l-r == 0 -> 0
        {_team, {l, r}, _streak} when team == left and l-r < -5 -> -2
        {_team, {l, r}, _streak} when team == left and l-r < 0 -> -1

        {_team, {l, r}, _streak} when team == right and r-l > 5 -> 2
        {_team, {l, r}, _streak} when team == right and r-l > 0 -> 1
        {_team, {l, r}, _streak} when team == right and r-l == 0 -> 0
        {_team, {l, r}, _streak} when team == right and r-l < -5 -> -2
        {_team, {l, r}, _streak} when team == right and r-l < 0 -> -1
      end
    end

    {_state, point_facts} = Enum.reduce events, {%{}, facts}, fn
      # TODO: handle points/serves first, if points = 25/15, give set win to team.

      %{"event" => ["KILL", by | _], "point" => p, "server" => s} = e, {state, fact_acc} ->

        serving_team = lookup_player_team.(s)
        serve_streak = case state[:last_server] do
          {^s, i} -> i
          _ -> 0
        end

        fact_acc = insert_set_fact.(fact_acc, [team: p, player: by, score_gap: get_score_gap.(state, p)], :kill, +1)
        |> insert_set_fact.([team: serving_team, player: s, score_gap: get_score_gap.(state, serving_team), serve_streak: serve_streak], :total_serves, +1)
        |> insert_set_fact.([team: p], :points, +1)

        state = update_last_server.(state, s) |> update_streaming_score.(p)
        {state, fact_acc}

      %{"event" => ["SERVICE_ACE" | data], "point" => p, "server" => s}, {state, fact_acc} ->

        serve_streak = case state[:last_server] do
          {^s, i} -> i
          _ -> 0
        end

        fact_acc = insert_set_fact.(fact_acc, [team: p, player: s, score_gap: get_score_gap.(state, p), serve_streak: serve_streak], :service_ace, +1)
        |> insert_set_fact.([team: p, player: s, score_gap: get_score_gap.(state, p), serve_streak: serve_streak], :total_serves, +1)
        |> insert_set_fact.([team: p], :points, +1)

        fact_acc = case data do
          ["TEAM"] -> insert_set_fact.(fact_acc, [team: not_team.(p), score_gap: get_score_gap.(state, not_team.(p))], :reception_error, +1)
          [player] -> insert_set_fact.(fact_acc, [team: not_team.(p), player: hd(data), score_gap: get_score_gap.(state, not_team.(p))], :reception_error, +1)
          _ -> fact_acc
        end

        state = update_last_server.(state, s) |> update_streaming_score.(p)
        {state, fact_acc}
        

      %{"event" => ["ATTACK_ERROR", by | _], "point" => p, "server" => s}, {state, fact_acc} ->
        serving_team = lookup_player_team.(s)

        serve_streak = case state[:last_server] do
          {^s, i} -> i
          _ -> 0
        end

        fact_acc = insert_set_fact.(fact_acc, [team: not_team.(p), player: by, score_gap: get_score_gap.(state, not_team.(p))], :attack_error, +1)
        |> insert_set_fact.([team: serving_team, player: s, score_gap: get_score_gap.(state, serving_team), serve_streak: serve_streak], :total_serves, +1)
        |> insert_set_fact.([team: p], :points, +1)

        state = update_last_server.(state, s)
        {state, fact_acc}

      %{"event" => ["SERVICE_ERROR" | _], "point" => p, "server" => s}, {state, fact_acc} ->
        serve_streak = case state[:last_server] do
          {^s, i} -> i
          _ -> 0
        end

        serving_team = lookup_player_team.(s)

        fact_acc = insert_set_fact.(fact_acc, [team: not_team.(p), player: s, score_gap: get_score_gap.(state, not_team.(p)), serve_streak: serve_streak], :service_error, +1)
        |> insert_set_fact.([team: serving_team, player: s, score_gap: get_score_gap.(state, serving_team), serve_streak: serve_streak], :total_serves, +1)
        |> insert_set_fact.([team: p], :points, +1)

        state = update_last_server.(state, s) |> update_streaming_score.(p)
        {state, fact_acc}

      ["SUB", data], {state, fact_acc} ->
        # TODO: different cases for different data sources (ncaa versus canadawest)
        [_, team, _, player] = Regex.run(~r/^(.*?) subs: (.*; )?(.*?)\.$/, data)

        # [_, team, player] = Regex.run(~r/^(.*?) subs: (.*?)\.$/, data)  # TODO: fix for ; where two players specified

        fact_acc = insert_set_fact.(fact_acc, [team: team, player: player], :sets_played, [set_i])
        |> insert_set_fact.([team: team, score_gap: get_score_gap.(state, team)], :subs, +1)

        {state, fact_acc}  # TODO: maybe update state?

      _, acc -> acc
    end

    point_facts
  end

  def join_facts(acc_map, map_1) do
    Map.merge acc_map, map_1, fn 
      :sets_played, v1, v2 -> Enum.uniq(v1 ++ v2)
      _k, v1, v2 -> v1 + v2 
    end
  end

  # facts :: %{}, dims :: [atom()], measures :: %{atom() => term()}
  def insert_fact(facts, dims, measures, opts \\ []) do
    # measures = if count > 0, do: Map.put(measures, :count, count), else: measures
    dims = if opts[:keep_dim_order], do: dims, else: Enum.sort_by(dims, fn {dim, _} -> @dimension_order[dim] end)
    update_in facts, [Access.key(dims, %{})], fn stats -> join_facts(stats, measures) end
  end

  def rollup(facts, dims, opts \\ []) do
    drop_measures = opts[:drop_measures]

    Enum.reduce facts, %{}, fn {fact_dims, measures}, acc ->
      measures = if drop_measures, do: Map.drop(measures, drop_measures), else: measures
      dim_key = Enum.map dims, &({&1, fact_dims[&1]})

      if !opts[:keep_nil] and Enum.any?(dim_key, &(elem(&1, 1) == nil)) do
        acc  # Ignore if the dimension is missing from the fact.
      else
        insert_fact acc, dim_key, measures, keep_dim_order: true
      end
      # update_in acc, [Access.key(dim_key, %{})], fn stats -> join_facts(stats, measures) end
    end
  end

  def filter_facts(facts, dim_filters, measure_filters \\ []) do
    Enum.filter facts, fn {fact_dims, measures} ->
      Enum.all?(dim_filters, fn {dim, fun} -> fun.(fact_dims[dim]) end) and
      Enum.all?(measure_filters, fn {measure, fun} -> fun.(measures[measure]) end)
    end
  end

  def add_derived_measure(facts, name, d_measures, fun) do
    Enum.reduce facts, facts, fn {facts_dim, measures}, acc ->
      args = Enum.map d_measures, &(get_in(measures, [Access.key(&1, 0)]))
      put_in acc, [facts_dim, name], apply(fun, args)
    end
  end

  def top_n(facts, measure, n) do
    Enum.reduce(facts, [], fn
      {facts_dim, %{^measure => val}}, acc when length(acc) < n -> Enum.sort [{val, facts_dim} | acc]
      {facts_dim, %{^measure => val}}, [{lowest, _} | rest] when val > lowest ->
        Enum.sort [{val, facts_dim} | rest]
      _, acc -> acc
    end) 
    |> Enum.reverse
    |> Enum.map fn {a, b} -> {b, a} end
  end

end
