class Api::V1::Servers::StatusController < ApplicationController
	def index
		@host = params[:host]
		raise ArgumentError if @host.nil?

		@port = 25565
		@server = Minetools::ServerStatusTool::ServerStatus.new host: @host
		@server.fetch_status!
		begin
			
		rescue StandardError => e
			
		end
		render status: 200, json: filter(@server.status)
	end

	private def filter _status
		raise ArgumentError unless _status.class == Hash

		return {
			name: _status["description"]["extra"][0]["text"],
			max_players: _status["players"]["max"],
			online_players: _status["players"]["online"],
			players: _status["players"]["sample"]
		}
	end
end
