defmodule Volleysim do

  # To run, install Elixir and run from command-line
  # $ mix deps.get
  # $ iex -S mix
  # iex(1)> Volleysim.process_file("gamedata.json", "boxscore.json") 


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
    files = [
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

    cache_obj = case File.read("cached_facts") do
      {:ok, bin} -> :erlang.binary_to_term(bin)
      {:error, :enoent} -> %{games: [], data: %{}}
    end

    cache_obj = Enum.reduce files, cache_obj, fn file, acc ->
      process_file_series("game_data/canadawest.org/Trinity Western 2016-17/" <> file, acc)
    end

    File.write!("cached_facts", :erlang.term_to_binary(cache_obj))
    :ok
  end

  def process_file_series(pbp_file, cache_obj) do
    {:ok, game_id, facts} = process_play_by_play(File.read!(pbp_file))

    unless game_id in cache_obj[:games] do
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

    team_sum_per_set = rollup(facts_fine_grain, [:set, :team], drop_measures: [:sets_played])

    # Insert kill attempt stats (per set) into facts.
    team_sum_per_set = Enum.reduce [team_1_name, team_2_name], team_sum_per_set, fn team, acc ->
      team_abbr = abbreviate_name(team)
      Enum.reduce Enum.with_index(boxscore["ta_per_set"][team], 1), acc, fn {ta_stat, set_i}, acc -> 
        insert_fact acc, [game: game_id, set: set_i, team: team_abbr], %{kill_attempt: ta_stat}
      end
    end

    # IO.inspect team_sum_per_set

    # IO.puts("--------------------------")

    # IO.puts("rollup [:team, :player]")
    player_game_sums = rollup(facts_fine_grain, [:team, :player])

    # IO.inspect(player_game_sums)


    # Insert extra stats from the box score
    player_game_sums = Enum.reduce Map.keys(boxscore["teams"]), player_game_sums, fn team, acc ->
      Enum.reduce boxscore["teams"][team], acc, fn [_player_id, player_name, %{"TA" => ta, "DIGS" => digs}], acc ->
        insert_fact acc, [game: game_id, team: abbreviate_name(team), player: player_name], %{kill_attempt: ta, digs: digs}
      end
    end

    # IO.puts("ta_stats: #{inspect(ta_stats)}")
    # IO.puts("----------------------------------------------")

    # IO.inspect player_game_sums


    # IO.puts("--------------------------------------------")

    team_game_sums = rollup(player_game_sums, [:team], drop_measures: [:sets_played])

    # IO.puts("Rollup [:team]")
    IO.inspect(team_game_sums)


    # IO.puts("--------------------------------------------")

    # IO.inspect(player_game_sums, limit: :infinity)
    # IO.puts("--------------------------------------------")


    # facts_fine_grain ++ Map.values(player_game_sums)
    all_facts = facts_fine_grain |> join_facts(team_game_sums) |> join_facts(player_game_sums)

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
      "Thompson Rivers" -> "TRUMVB"
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

      %{"event" => ["KILL", by | _], "point" => p, "server" => s}, {state, fact_acc} ->

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
        [_, team, player] = Regex.run(~r/^(.*?) subs: (.*?)\.$/, data)  # TODO: fix for ; where two players specified

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

end
