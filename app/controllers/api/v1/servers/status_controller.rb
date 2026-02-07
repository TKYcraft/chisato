class Api::V1::Servers::StatusController < ApplicationController
	MC_PORT_ALLOW_MORE_THAN = App::Application.config.mc_port_allow_more_than

	def index
		@tld_list = App::Application.config.tld_list["TLD"]
		@host = params[:host]
		@port = nil
		@port = params[:port].to_i unless params[:port].nil?
		@order = params[:order].to_s

		begin
			if @port.present?
				raise ArgumentError unless MC_PORT_ALLOW_MORE_THAN < @port
			end

			@acl = Acl::Acl.new @host, @tld_list
			@acl.filter!
			@server = Minetools::ServerStatusTool::ServerStatus.new host: @host, port: @port, logger: logger
			@server.fetch_status!

		rescue ArgumentError => e
			logger.error e
			render status: 400, json: {message: e.message}
			return
		rescue Acl::DeniedHostError => e
			logger.error e
			render status: 400, json: {message: e.message}
			return
		rescue Minetools::ServerStatusTool::ServiceUnavailableError => e
			logger.error e
			render status: 404, json: {message: e.message}
			return
		rescue Minetools::ServerStatusTool::ConnectionError => e
			logger.error e
			render status: 500, json: {message: e.message}
			return
		rescue => e
			logger.error e
			render status: 500, json: {message: e.message}
			return
		end
		render status: 200, json: convert(@server.status, @order)
	end

	private def convert _status, _order
		raise ArgumentError unless _status.class == Hash

		players = _status["players"]["sample"]
		players = [] if players.nil?
		players = sort players, _order

		return {
			version: _status["version"]["name"],
			protocol: _status["version"]["protocol"],
			name: _status["description"]["extra"][0]["text"],
			max_players: _status["players"]["max"],
			online_players: _status["players"]["online"],
			players: players
		}
	end

	private def sort _players, _order
		raise ArgumentError unless _players.class == Array
		players = _players

		if _order.downcase == "asc"
			players = players.sort do |a, b|
				a["name"] <=> b["name"]
			end
		end
		if _order.downcase == "desc"
			players = players.sort do |a, b|
				b["name"] <=> a["name"]
			end
		end
		return players
	end
end
