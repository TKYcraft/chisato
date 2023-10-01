class Api::V1::Servers::StatusController < ApplicationController
	require 'ipaddr'
	require 'yaml'

	class DeniedHostError < StandardError
		def initialize msg="Request to this host is not allowed."
			super msg
		end
	end

	DENY_IP_ADDRESSES = [
		# IPv4
		"192.168.0.0/16",
		"172.16.0.0/12",
		"10.0.0.0/8",
		"255.255.255.255",   # broadcast
		"127.0.0.0/8",   # loop back
		"169.254.0.0/16",   # link local
		"100.64.0.0/10",   # shared address space ref: RFC6890

		# IPv6
		"::1/128",   # loop back
		"fc00::/7",   # unique local
		"fe80::/10",   # link local
		"ff01::1",   # multicast on interface local
		"ff02::1",   # multicast on link local
	].freeze

	def index
		@host = params[:host]
		@port = nil
		@port = params[:port].to_i unless params[:port].nil?

		begin
			host_filter @host
			@server = Minetools::ServerStatusTool::ServerStatus.new host: @host, port: @port
		rescue DeniedHostError => e
			render status: 400, json: {message: e.message}
			return
		rescue ArgumentError => e
			render status: 400, json: {message: e.message}
			return
		rescue => e
			render status: 500, json: {message: e.message}
			return
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

	private	def host_filter _host
		raise ArgumentError unless _host.class == String
		# TODO: fastly return with white list

		is_hostname = _host_name_filter_default _host
		is_ipaddr = _ip_address_filter_default _host

		raise ArgumentError, "given host is not IP address or correct hostname." if !is_ipaddr && !is_hostname
	end

	private def _host_name_filter_default _host
		_match = /^(?:[a-zA-Z0-9][a-zA-Z0-9-]{,63}[a-zA-Z0-9]{,63}\.){,253}([a-zA-Z]{2,})$/.match _host.upcase
		return false if _match.nil?

		tld_list = App::Application.config.tld_list["TLD"]
		unless tld_list.map{|i| i.to_s.upcase}.include? _match[1]
			raise ArgumentError, "given TLD of hostname is not correct."
		end
		return true
	end

	private def _ip_address_filter_default _host
		begin
			_host_address = IPAddr.new(_host)
		rescue IPAddr::InvalidAddressError => e
			return false
		end
		DENY_IP_ADDRESSES.each do |addr|
			raise DeniedHostError if IPAddr.new(addr).include? _host_address
		end
		return true
	end
end
