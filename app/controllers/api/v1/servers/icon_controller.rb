class Api::V1::Servers::IconController < ApplicationController
	MC_PORT_ALLOW_MORE_THAN = App::Application.config.mc_port_allow_more_than
	FAVICON_PREFIX = /\Adata:\s*image\/png;base64,/

	before_action :set_cache_control_header

	def index
		@tld_list = App::Application.config.tld_list["TLD"]
		@host = params[:host]
		@port = nil
		@port = params[:port].to_i unless params[:port].nil?

		begin
			if @port.present?
				raise ArgumentError unless MC_PORT_ALLOW_MORE_THAN < @port
			end

			@acl = Acl::Acl.new @host, @tld_list
			@acl.filter!
			@server = Minetools::ServerStatusTool::ServerStatus.new host: @host, port: @port
			@server.fetch_status!

		rescue ArgumentError => e
			render status: 400, json: {message: e.message}
			return
		rescue Acl::DeniedHostError => e
			render status: 400, json: {message: e.message}
			return
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

		@icon_bin = decode_favicon @server.status["favicon"]
		if @icon_bin.nil?
			head :not_found
			return
		end
		send_data @icon_bin, type: "image/png", disposition: 'inline', status: 200
	end

	private def decode_favicon _favicon
		return nil unless _favicon.class == String
		return nil unless FAVICON_PREFIX.match? _favicon
		encoded = _favicon.sub(FAVICON_PREFIX, "").gsub(/\s+/, "")
		return Base64.strict_decode64(encoded)
	rescue ArgumentError
		return nil
	end

	private def use_cache?
		param = params[:cache]
		return true if param.nil?
		return false if param.downcase == "no"
		return true
	end

	private def set_cache_control_header
		if use_cache?
			expires_in 1.hours, public: true
		else
			expires_now
		end
	end
end
