defmodule WebServer.Server do
  use GenServer

  require Logger

  @port 80
  @sensor_data_table_name :sensor_data

  # @game_tables %{table_1: [:sensor_1]}

  defstruct tables: %{}

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
    :ets.new(@sensor_data_table_name, [:duplicate_bag , :named_table, :public])

    Logger.info("Web server started. Listening on port #{inspect @port}")
    dispatch = :cowboy_router.compile([
      {:_, [
        {"/health", __MODULE__.Health, %{}},
        {"/tables/:table_id", __MODULE__.TablesEndpoint, %{}},
        {"/tables", __MODULE__.TablesEndpoint, %{}},
        {"/tables/:table_id/sensors", __MODULE__.SensorsEndpoint, %{}},
        {"/", :cowboy_static, {:priv_file, :volleysim, "assets/index.html"}},
        {"/[...]", :cowboy_static, {:priv_dir, :volleysim, "assets"}}
      ]},
    ])

    {:ok, _} = :cowboy.start_clear(:volleysim, [port: @port], %{:env => %{:dispatch => dispatch}})  # TODO: pass in port?
    {:ok, %__MODULE__{}}
  end

  defmodule Health do
    def init(req, state) do
      Logger.info("Got request: #{inspect req}")
      req = :cowboy_req.reply(200, %{"content-type" => "application/json"}, "{\"status\": \"up\"}", req)
          # req = :cowboy_req.reply(204, %{}, "", req)
      {:ok, req, state}
    end
  end

  defmodule TablesEndpoint do
    alias GameoverServer.Server

    @tables [{"t1", "Small pool table"}]

    def init(req, state) do
      table_id = :cowboy_req.binding(:table_id, req)

      req = if table_id == :undefined do

        tables = Enum.reduce @tables, [], fn({id, name}, acc) ->
          status = Server.get_table_status(id)
          %{id: id, name: name, status: %{latest_activity: status.latest_activity}}
        end

        response = Poison.encode!(tables)
        :cowboy_req.reply(200, %{"content-type" => "application/json", "Access-Control-Allow-Origin" => "*"}, response, req)
      else
        if req.method != "GET" do
          :cowboy_req.reply(405, %{"content-type" => "text/plain", "Access-Control-Allow-Origin" => "*"}, "Only GET supported", req)
        else

          Logger.info("Got request: #{inspect req}, binding: #{inspect(table_id)}")

          table_status = Server.get_table_status(table_id)
          if table_status == nil do
            :cowboy_req.reply(404, %{"content-type" => "text/plain", "Access-Control-Allow-Origin" => "*"}, "table #{inspect(table_id)} does not exist", req)
          else
            response = Poison.encode!(%{id: table_id, latest_activity: table_status.latest_activity})
            :cowboy_req.reply(200, %{"content-type" => "application/json", "Access-Control-Allow-Origin" => "*"}, response, req)
          end
        end
      end
      req = 
      {:ok, req, state}
    end
  end

  defmodule SensorsEndpoint do
    alias GameoverServer.Server

    @tables ["t1"]
    # @auth_secret Application.get_env(:gameover_server, :sensor_auth_secret)

    def init(req, state) do
      table_id = req.bindings[:table_id]

      # Logger.debug("sensors post request: #{inspect req}")

      # auth_token = req.headers["authorization"]
      req = cond do
        # not req.header
        # auth_token != "auth_token #{@auth_secret}" ->
        #   :cowboy_req.reply(401, %{"content-type" => "text/plain"}, "this endpoint requires authentication", req)
        not table_id in @tables ->
          :cowboy_req.reply(404, %{"content-type" => "text/plain", "Access-Control-Allow-Origin" => "*"}, "table #{inspect(table_id)} does not exist", req)

        req.method == "GET" ->
          data = Server.sensor_data_fetch_all(table_id)
          response = Poison.encode!(data)
          :cowboy_req.reply(200, %{"content-type" => "application/json", "Access-Control-Allow-Origin" => "*"}, response, req)

        req.method != "POST" ->
          :cowboy_req.reply(405, %{"content-type" => "text/plain", "Access-Control-Allow-Origin" => "*"}, "only POST supported", req)

        req.host != "localhost" ->
          :cowboy_req.reply(403, %{"content-type" => "text/plain", "Access-Control-Allow-Origin" => "*"}, "must be called from localhost", req)
        
        req.has_body == false ->
          :cowboy_req.reply(400, %{"content-type" => "text/plain", "Access-Control-Allow-Origin" => "*"}, "body missing", req)

        true ->
          {:ok, data, req} = :cowboy_req.read_body(req)
          case Poison.decode(data) do
            {:error, {:invalid, _, _}} ->
              :cowboy_req.reply(400, %{"content-type" => "text/plain", "Access-Control-Allow-Origin" => "*"}, "invalid JSON body", req)
            
            {:ok, data} ->
              if not Map.has_key?(data, "data") or not is_list(data["data"]) do
                :cowboy_req.reply(400, %{"content-type" => "text/plain", "Access-Control-Allow-Origin" => "*"}, "invalid body, missing data property with array value", req)
              else
                Server.post_sensor_data(table_id, data["timestamp"], data["data"])
                Logger.info("putting sensor for data: #{inspect(data)}")
                :cowboy_req.reply(204, req)
              end
          end
      end
      {:ok, req, state}
    end
  end


  def post_sensor_data(table_id, timestamp \\ nil, data) do
    timestamp = timestamp || :erlang.monotonic_time(1)
    GenServer.cast(__MODULE__, {:post_sensor_data, table_id, timestamp, data})
  end

  def get_table_status(table_id) do
    GenServer.call(__MODULE__, {:get_table_status, table_id})
  end

  def handle_call({:get_table_status, table_id}, _from, state) do
    sensor_data = sensor_data_fetch_latest(table_id)
    # available = sensor_data.timestamp < :erlang.monotonic_time(1) - 60 * 3
    latest_activity = sensor_data.timestamp

    table_status = %TableStatus{latest_activity: latest_activity}

    {:reply, table_status, state}
  end

  def handle_cast({:post_sensor_data, table_id, timestamp, data}, state) do
    Logger.info("post_sensor_data, #{inspect(data)}")
    sensor_data_insert(table_id, timestamp, data)
    {:noreply, state}
  end

  # Sensor data table functions

  defp sensor_data_insert(table_id, timestamp, data) when is_list(data) do
    Enum.reduce data, 0, fn(val, id) ->
      if val > 0 do
        data = %SensorData{id: id, timestamp: timestamp, value: val}
        :ets.insert(@sensor_data_table_name, {{table_id, :all}, data})
        :ets.delete(@sensor_data_table_name, {table_id, :latest})
        :ets.insert(@sensor_data_table_name, {{table_id, :latest}, data})
      end
      id + 1
    end
  end

  defp sensor_data_fetch_latest(table_id) do
    case :ets.lookup(@sensor_data_table_name, {table_id, :latest}) do
      [] -> %SensorData{}
      [{_, %SensorData{} = data}] -> data
    end
  end

  def sensor_data_fetch_all(table_id) do
    max_data_items = 1000
    {new, _} = Enum.reduce_while :ets.lookup(@sensor_data_table_name, {table_id, :all}), {[], max_data_items}, fn({_, data}, {new, count}) ->
      if count > 0 do
        {:cont, {[data | new], count - 1}}
      else
        {:halt, {new, count}}
      end
    end
    new
  end
end