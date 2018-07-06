defmodule WebServer do
	
	def start(_type, _args) do
	  WebServer.Supervisor.start_link()
	end

end