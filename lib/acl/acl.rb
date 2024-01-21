module Acl
	class Acl
		require 'ipaddr'
		require 'yaml'

		DENY_IP_ADDRESSES = [
			# IPv4
			"0.0.0.0/8",   # This host on this network
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

		def initialize host=nil, tld_list=[]
			raise ArgumentError unless host.class == String
			raise ArgumentError unless is_tld_array? tld_list
			@host = host
			@tld_list = tld_list
		end

		def filter!
			filter @host
		end

		private def filter _host
			raise ArgumentError unless _host.class == String
			# TODO: fastly return with white list

			is_hostname = _host_name_filter_default _host
			is_ipaddr = _ip_address_filter_default _host

			raise ArgumentError, "given host is not IP address or correct hostname." if !is_ipaddr && !is_hostname
		end

		private def _host_name_filter_default _host
			_match = /^(?:[a-zA-Z0-9][a-zA-Z0-9-]{,63}[a-zA-Z0-9]{,63}\.){,253}([a-zA-Z]{2,})$/.match _host.upcase
			return false if _match.nil?

			unless @tld_list.map{|i| i.to_s.upcase}.include? _match[1]
				raise DeniedHostError, "given TLD of hostname is not correct."
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
				raise DeniedHostError, "given IP Address is not allowed length." if IPAddr.new(addr).include? _host_address
			end
			return true
		end

		private def is_tld_array? _array
			return false unless _array.class == Array
			return false if _array.size < 1
			_array.each do |_tld|
				# TODO: check simple domains or XN== domains or not.
				return false unless _tld.class == String
			end
			return true
		end
	end

	class DeniedHostError < StandardError
		def initialize msg="Request to this host is not allowed."
			super msg
		end
	end
end
