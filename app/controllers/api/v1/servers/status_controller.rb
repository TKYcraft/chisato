class Api::V1::Servers::StatusController < ApplicationController
	def index
		@host = params[:host]
		@port = nil
		@port = params[:port].to_i unless params[:port].nil?

		begin
			@server = Minetools::ServerStatusTool::ServerStatus.new host: @host, port: @port
		rescue ArgumentError => e
			render status: 400, json: {message: e.message}
			return
		rescue => e
			render status: 500, json: {message: e.message}
		end

		begin
			@server.fetch_status!
		rescue Minetools::ServerStatusTool::ServiceUnavailableError => e
			render status: 404, json: {message: e.message}
			return
		rescue Minetools::ServerStatusTool::ConnectionError => e
			render status: 500, json: {message: e.message}
			return
		rescue => e
			render status: 500, json: {message: e.message}
			return
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
