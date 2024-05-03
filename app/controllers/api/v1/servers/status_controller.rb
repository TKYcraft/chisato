class Api::V1::Servers::StatusController < ApplicationController
	def index
		@tld_list = App::Application.config.tld_list["TLD"]
		@host = params[:host]
		@port = nil
		@port = params[:port].to_i unless params[:port].nil?

		begin

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
		render status: 200, json: convert(@server.status)
	end

	private def convert _status
		raise ArgumentError unless _status.class == Hash

		return {
			name: _status["description"]["extra"][0]["text"],
			max_players: _status["players"]["max"],
			online_players: _status["players"]["online"],
			players: _status["players"]["sample"]
		}
	end
end
