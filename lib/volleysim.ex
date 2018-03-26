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
  @dimension_order %{game_id: 10, set: 20, team: 30, player: 40, serve_streak: 60}


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


  def process_file(pbp_file, bscore_file) do
    process_play_by_play(File.read!(pbp_file), File.read!(bscore_file))
  end

  def process_play_by_play(pbp_binary, bscore_binary) do
    root = Poison.decode!(pbp_binary)
    # IO.inspect root

    boxscore = Poison.decode!(bscore_binary)

    date = root["date"] |> Date.from_iso8601!
    season = if date.month < 7, do: {date.year - 1, date.year}, else: {date.year, date.year + 1}


    game_id = root["id"]
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
    sets = Enum.map sets, fn key ->
      set_i = String.to_integer(key)
      {set_i, process_set(set_i, root["sets"][key], root["teams"], players)}
    end

    facts_fine_grain = Enum.flat_map sets, &elem(&1, 1)

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
        insert_fact acc, [set: set_i, team: team_abbr], %{kill_attempt: ta_stat}
      end
    end


    # old_team_sums = Enum.map sets, fn {set_i, point_facts_for_set} ->
    #   team_1_name_abbr = abbreviate_name(team_1_name)
    #   point_facts_for_set = put_in point_facts_for_set, [Access.key([set: set_i, team: team_1_name_abbr], %{}), :kill_attempt], get_kill_attempt_for_set.(set_i, team_1_name)
      
    #   team_2_name_abbr = abbreviate_name(team_2_name)
    #   point_facts_for_set = put_in point_facts_for_set, [Access.key([set: set_i, team: team_2_name_abbr], %{}), :kill_attempt], get_kill_attempt_for_set.(set_i, team_2_name)

    #   Enum.reduce point_facts_for_set, %{}, fn {[{:set, _set_i}, {:team, team} | _], player_stats}, acc ->
    #     update_in acc, [Access.key([set: set_i, team: team], %{})], fn team_stats -> 
    #       join_stats(team_stats, player_stats)
    #       # Enum.reduce player_stats, team_stats, fn {stat, val}, acc ->
    #       #   update_in acc, [Access.key(stat, 0)], fn prev -> prev + val end
    #       # end
    #     end
    #   end
    # end

    IO.inspect team_sum_per_set

    IO.puts("--------------------------")

    IO.puts("rollup [:team, :player]")
    player_game_sums = rollup(facts_fine_grain, [:team, :player])

    IO.inspect(player_game_sums)


    # old_player_game_sums = Enum.reduce sets, %{}, fn {_, point_facts_for_set}, acc ->
    #   Enum.reduce point_facts_for_set, acc, fn {[{:set, set_i}, {:team, team}, {:player, player} | _], player_stats}, acc ->
    #     update_in acc, [Access.key([{:team, team}, {:player, player}], %{})], fn stats -> 
    #       join_stats(stats, player_stats)
    #     end
    #   end
    # end

    # IO.puts("$$$$ match?? #{player_game_sums == old_player_game_sums}")

    # Insert extra stats from the box score
    player_game_sums = Enum.reduce Map.keys(boxscore["teams"]), player_game_sums, fn team, acc ->
      Enum.reduce boxscore["teams"][team], acc, fn [_player_id, player_name, %{"TA" => ta, "DIGS" => digs}], acc ->
        insert_fact acc, [team: abbreviate_name(team), player: player_name], %{kill_attempt: ta, digs: digs}
      end
    end
    # extra_stats_for_game = Enum.flat_map(Map.keys(boxscore["teams"]), fn team ->
    #   Enum.map boxscore["teams"][team], fn [_player_id, player_name, %{"TA" => ta, "DIGS" => digs}] ->
    #     {[{:team, abbreviate_name(team)}, {:player, player_name}], %{kill_attempt: ta, digs: digs}}
    #   end
    # end)

    

    # IO.puts("ta_stats: #{inspect(ta_stats)}")
    IO.puts("----------------------------------------------")

    IO.inspect player_game_sums

    # player_game_sums = Enum.reduce extra_stats_for_game ++ facts_fine_grain, %{}, fn 
    #     {[{:set, set_i}, {:team, team}, {:player, player} | _], player_stats}, acc ->
    #       update_in acc, [Access.key([{:team, team}, {:player, player}], %{})], fn stats -> 
    #         join_stats(stats, player_stats)
    #         # join_stats(stats, player_stats) |> Map.update :sets_played, [set_i], &Enum.uniq([set_i | &1])
    #       end

    #   {[{:team, team}, {:player, player} | _], player_stats}, acc ->
    #     update_in acc, [Access.key([{:team, team}, {:player, player}], %{})], fn stats -> 
    #       join_stats(stats, player_stats)
    #     end
    # end

    IO.puts("--------------------------------------------")
    


    # team_game_sums = Enum.reduce player_game_sums, %{}, fn {dims, measures}, acc ->
    #   measures = Map.drop(measures, [:sets_played]) # Sets played is only relevant to player granularity.
    #   update_in acc, [Access.key([team: dims[:team]], %{})], fn stats -> join_stats(stats, measures) end
    # end

    team_game_sums = rollup(player_game_sums, [:team], drop_measures: [:sets_played])

    IO.puts("Rollup [:team]")
    IO.inspect(team_game_sums)


    IO.puts("--------------------------------------------")

    IO.inspect(player_game_sums, limit: :infinity)
    IO.puts("--------------------------------------------")


    facts_fine_grain ++ Map.values(player_game_sums)
  end

  def abbreviate_name(name) do
    case name do
      "Trinity Western" -> "TWU"
      "Regina" -> "REG"
      _ -> throw("unknown name abbrv: #{name}")
    end
  end

  def process_set(set_i, set, teams, players) do
    starters = set["starters"]
    events = set["events"]

    [team_x_abbr, team_y_abbr] = Map.keys(starters)


    lookup_player_team = fn player ->
      {team_abbr, _, _, _} = players[player]
      team_abbr
    end

    # key is the set of dimensions
    # stat => measure
    insert_set_fact = fn facts, dims, stat, val ->
      dims = if dims[:team] == nil, do: put_in(dims[:team], lookup_player_team.(dims[:player])), else: dims
      insert_fact facts, dims, %{stat => val}
    end

    not_team = fn 
      ^team_x_abbr -> team_y_abbr
      ^team_y_abbr -> team_x_abbr
    end

    facts = %{}

    facts = Enum.reduce starters, facts, fn {team_abbr, players}, acc ->
      Enum.reduce players, acc, fn player, acc ->
        insert_set_fact.(acc, [set: set_i, team: team_abbr, player: player], :sets_played, [set_i])
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

    {_state, point_facts} = Enum.reduce events, {%{}, facts}, fn
      %{"event" => ["KILL", by | _], "point" => p, "server" => s}, {state, fact_acc} ->
        fact_acc = insert_set_fact.(fact_acc, [set: set_i, team: p, player: by], :kill, +1)
        |> insert_set_fact.([set: set_i, team: nil, player: s], :total_serves, +1)

        state = update_last_server.(state, s) |> update_streaming_score.(p)
        {state, fact_acc}

      %{"event" => ["SERVICE_ACE" | data], "point" => p, "server" => s}, {state, fact_acc} ->

        serve_streak = case state[:last_server] do
          {^s, i} -> i
          _ -> 0
        end

        fact_acc = insert_set_fact.(fact_acc, [set: set_i, team: p, player: s, serve_streak: serve_streak], :service_ace, +1)
        |> insert_set_fact.([set: set_i, team: p, player: s], :total_serves, +1)
         
        fact_acc = case data do
          ["TEAM"] -> insert_set_fact.(fact_acc, [set: set_i, team: not_team.(p)], :reception_error, +1)
          [player] -> insert_set_fact.(fact_acc, [set: set_i, team: not_team.(p), player: hd(data)], :reception_error, +1)
          _ -> fact_acc
        end

        state = update_last_server.(state, s) |> update_streaming_score.(p)
        {state, fact_acc}
        

      %{"event" => ["ATTACK_ERROR", by | _], "point" => p, "server" => s}, {state, fact_acc} ->
        fact_acc = insert_set_fact.(fact_acc, [set: set_i, team: not_team.(p), player: by], :attack_error, +1)
        |> insert_set_fact.([set: set_i, team: nil, player: s], :total_serves, +1)

        state = update_last_server.(state, s)
        {state, fact_acc}

      %{"event" => ["SERVICE_ERROR" | _], "point" => p, "server" => s}, {state, fact_acc} ->
        serve_streak = case state[:last_server] do
          {^s, i} -> i
          _ -> 0
        end

        fact_acc = insert_set_fact.(fact_acc, [set: set_i, team: not_team.(p), player: s, serve_streak: serve_streak], :service_error, +1)
        |> insert_set_fact.([set: set_i, team: nil, player: s], :total_serves, +1)

        state = update_last_server.(state, s) |> update_streaming_score.(p)
        {state, fact_acc}

      ["SUB", data], {state, fact_acc} ->
        # TODO: different cases for different data sources (ncaa versus canadawest)
        [_, team, player] = Regex.run(~r/^(.*?) subs: (.*?)\.$/, data)
        fact_acc = insert_set_fact.(fact_acc, [set: set_i, team: team, player: player], :sets_played, [set_i])
        {state, fact_acc}  # TODO: maybe update state?

      _, acc -> acc
    end

    point_facts
  end


  def join_stats(acc_map, map_1) do
    Map.merge acc_map, map_1, fn 
      :sets_played, v1, v2 -> Enum.uniq(v1 ++ v2)
      _k, v1, v2 -> v1 + v2 
    end
  end

  # facts :: %{}, dims :: [atom()], measures :: %{atom() => term()}
  def insert_fact(facts, dims, measures) do
    dims = Enum.sort_by dims, fn {dim, _} -> @dimension_order[dim] end
    update_in facts, [Access.key(dims, %{})], fn stats -> join_stats(stats, measures) end
  end

  def rollup(facts, dims, opts \\ []) do
    drop_measures = opts[:drop_measures]

    Enum.reduce facts, %{}, fn {fact_dims, measures}, acc ->
      measures = if drop_measures, do: Map.drop(measures, drop_measures), else: measures
      dim_key = Enum.map dims, &({&1, fact_dims[&1]})
      insert_fact acc, dim_key, measures
      # update_in acc, [Access.key(dim_key, %{})], fn stats -> join_stats(stats, measures) end
    end
  end

end
