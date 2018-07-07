defmodule WebServer.Server do
  use GenServer

  require Logger

  @port 80
  @sensor_data_table_name :sensor_data

  @data_src_table_name :data_sources
  @data_sources_folder "priv/data"
  @data_sources_info @data_sources_folder <> "/info.json"

  # @game_tables %{table_1: [:sensor_1]}

  defstruct tables: %{}, data_sources_info: nil

  defmodule SensorData do
    defstruct id: 0, timestamp: 0, value: 0
  end

  defmodule TableStatus do
    defstruct latest_activity: nil 
  end

  def start_link(args, _opts) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init(args) do
    # :ets.new(@sensor_data_table_name, [:duplicate_bag , :named_table, :public])

    :ets.new(@data_src_table_name, [:named_table, :public])

    data_src_map = load_data_sources()

    Logger.info("Web server started. Listening on port #{inspect @port}")
    dispatch = :cowboy_router.compile([
      {:_, [
        {"/health", __MODULE__.Health, %{}},
        {"/tables/:table_id", __MODULE__.TablesEndpoint, %{}},
        {"/tables", __MODULE__.TablesEndpoint, %{}},
        {"/tables/:table_id/sensors", __MODULE__.SensorsEndpoint, %{}},

        {"/api/data/sources", __MODULE__.DataSourcesEndpoint, %{map: data_src_map}},
        {"/api/data/sources/:source_id", __MODULE__.DataSourcesEndpoint, %{map: data_src_map}},
        {"/api/data/sources/:source_id/rollup", __MODULE__.DataSourcesEndpoint, %{map: data_src_map, rollup: true}},

        # {"/api/data/sources/"} => [ {"title": "hiearchy title", "id": "id", "children": {"title": "title", "id": "id"}} ]
        # {"/api/data/sources/:source_id"} => { info, "dimensions": [{"dim title", "id"} ], "measures": [] }
        # {"/api/data/sources/:source_id/rollup?dims=[id1,id2,id3]"} => [ [ dim val, dim val, dim val, measures.. ], [   ]  ]

        # {"api/test/:source_id/rollup", __MODULE__}

        # {"api/test/:source_id/rollup", }  => [  [], [], [] ]

        # {"/api/data/seasons "}  => 
        # {"/api/data/seasons/:season_id "}

        {"/volleyvisapp", :cowboy_static, {:file, "volleyvisapp/build/index.html"}},
        {"/css/[...]", :cowboy_static, {:dir, "volleyvisapp/build/css"}},
        {"/volleyvisapp/[...]", :cowboy_static, {:dir, "volleyvisapp/build"}}
      ]},
    ])

    {:ok, _} = :cowboy.start_clear(:volleysim, [port: @port], %{:env => %{:dispatch => dispatch}})  # TODO: pass in port?
    {:ok, %__MODULE__{data_sources_info: data_src_map}}
  end


  def load_data_sources do
    info = File.read!(@data_sources_info) |> Poison.decode!()
    Enum.reduce info, %{}, fn data_src, acc ->
      Logger.info("Loading data source: #{inspect data_src["id"]}")
      path = Path.join([@data_sources_folder, data_src["dir"], data_src["facts_file"]])

      if File.exists?(path) do
        data = path |> File.read! |> :erlang.binary_to_term
        :ets.insert(@data_src_table_name, {data_src["id"], data})
        Logger.info("Successfully loaded data source: #{inspect data_src["id"]}")
        Map.put(acc, data_src["id"], data_src)
      else
        Logger.warn("Missing file #{inspect(path)}")
        acc
      end
    end
  end

  defmodule Health do
    def init(req, state) do
      # Logger.info("Got request: #{inspect req}, state: #{inspect(state)}")
      req = :cowboy_req.reply(200, %{"content-type" => "application/json"}, "{\"status\": \"up\"}", req)
          # req = :cowboy_req.reply(204, %{}, "", req)
      {:ok, req, state}
    end
  end

  defmodule DataSourcesEndpoint do
    @data_src_table_name :data_sources
    @dimension_atoms [:game, :set, :team, :player, :score_gap, :serve_streak]
    @dim_string_to_atom Map.new(Enum.map(@dimension_atoms, &({Atom.to_string(&1), &1})))

    def init(req, state) do
      {:cowboy_rest, req, state}
    end

    def resource_exists(req, state = %{map: src_map}) do
      case :cowboy_req.binding(:source_id, req) do
        :undefined -> 
          {true, req, Map.put(state, :resource, :all)}

        res ->
          {Map.has_key?(src_map, res), req, Map.put(state, :resource, res)}
      end
    end

    def malformed_request(req, state = %{rollup: true}) do
      case :cowboy_req.match_qs([{:dims, [], ""}], req) do
        %{dims: true} -> 
          {true, req, state}

        %{dims: dims} ->
          {String.match?(dims, ~r/[^A-Za-z0-9,]/), req, state}

        _ ->
          {true, req, state}
      end
    end

    def malformed_request(req, state), do: {false, req, state}

    def to_json(req, state = %{resource: :all, map: src_map}) do
      # [{"title": "title", "id": "id"}]
      body = Enum.map(src_map, fn {key, val} -> %{"id": key, "title": val["title"]} end) |> Poison.encode!
      {body, req, state}
    end

    def to_json(req, state = %{resource: resource, map: src_map, rollup: true}) do
      src_id = :cowboy_req.binding(:source_id, req)
      [{_, data}] = :ets.lookup(@data_src_table_name, src_id)
      facts = data[:data]
      
      rollup_dims = :cowboy_req.match_qs([{:dims, [], ""}], req)[:dims] 
      |> String.split(",", trim: true)
      |> Enum.map(&(@dim_string_to_atom[&1]))

      measures = [:total_serves, :service_ace, :service_error, :reception_error, :kill_attempt, 
                  :attack_error, :kill, :points, :subs]  # TODO: add digs, it seems to be missing from data too.

      data = Volleysim.rollup(facts, rollup_dims) |> Volleysim.facts_to_json_ready(rollup_dims, measures)

      body = %{dims: rollup_dims, measures: measures, data: data} |> Poison.encode!
      {body, req, state}
    end

    def to_json(req, state = %{resource: resource, map: src_map}) do
      ret_keys = ["title", "measures", "dimensions", "id"]

      body = src_map[resource] |> Map.take(ret_keys) |> Poison.encode!
      {body, req, state}
    end

    def content_types_provided(req, state) do
      provided = [{{"application", "json", :*}, :to_json}]
      {provided, req, state}
    end

  end

end