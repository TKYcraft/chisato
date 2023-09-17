module Minetools
	module ServerStatusTool
		require 'socket'
		require "json"

		class ServerStatus

			INIT_DEFAULT_ARGUMENTS = {host: nil, port: 25565}.freeze

			attr_reader :host, :port, :status
			def initialize options={host: nil, port: nil}
				_opt = INIT_DEFAULT_ARGUMENTS.merge(options)
				@host = _opt[:host]
				@port = _opt[:port]
				@status = nil

				check_instance_variables! e=ArgumentError
			end

			def fetch_status
				check_instance_variables!

				socket = TCPSocket.new(@host, @port)

				handshake_packet = generate_handshake_packet()
				socket.write([handshake_packet.length].pack('C') + handshake_packet)

				status_request_packet = "\x00"
				socket.write([status_request_packet.length].pack('C') + status_request_packet)

				response_length = socket.read(2).unpack('C')[0]
				response = socket.read(response_length)

				data = response.force_encoding('UTF-8').encode
				data = data.slice(3, data.length)
				json = JSON.parse(data)

				socket.close
				return json
			end

			def fetch_status!
				@status = self.fetch_status
			end

			private def generate_handshake_packet
				check_instance_variables!
				handshake_packet = ""

				handshake_packet << packet_id = "\x00"
				handshake_packet << protocol_version = "\x2F"   # 47 in HEX
				handshake_packet << host_length = [@host.length].pack('c')   # That means this is a VarInt.
				handshake_packet << @host   # name or IP address
				handshake_packet << [@port].pack('n')   # as a short, Big-endian
				handshake_packet << next_state = "\x01"

				return handshake_packet
			end

			private def check_instance_variables! e=InstanceVariableError
				raise e, "host must be String." unless @host.class == String

				raise e, "port must be Integer." unless @port.class == Integer
				raise e, "port must be in length 1~65535." unless 1 <= @port && @port <= 65535
			end
		end

		class InstanceVariableError < StandardError
			def initialize msg="is not correct value."
				super msg
			end
		end
	end
end
