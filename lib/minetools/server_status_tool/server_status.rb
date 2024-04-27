module Minetools
	module ServerStatusTool
		require 'socket'
		require "json"
		require "logger"

		class ServerStatus
			attr_reader :host, :port, :status
			def initialize options={host: nil, port: nil, logger: nil}
				@host = options[:host]
				@port = options[:port] || 25565
				@logger = options[:logger] || Logger.new($stdout)
				@status = nil
				@socket = nil

				check_instance_variables! e=ArgumentError
			end

			def socket
				@socket ||= TCPSocket.new(@host, @port, connect_timeout: 1)
			end

			def fetch_status
				check_instance_variables!
				socket

				handshake_packet = generate_handshake_packet()
				socket.write([handshake_packet.length].pack('C') + handshake_packet)

				status_request_packet = "\x00"
				socket.write([status_request_packet.length].pack('C') + status_request_packet)

				payload = ""
				header = ""
				# packet_length = nil
				# packet_id = nil

				# # split header to length and packet id
				# for num in 0...header.length do   
				# 	if header[num] == "\x00"
				# 		packet_length = header[0...num].bytes.map { |byte| "%02X" % byte }.join("").to_i(16)
				# 		packet_id = header[num...header.length].bytes.map { |byte| "%02X" % byte }.join("").to_i(16)
				# 	end
				# end

				loop{   # drop head of packet.
					char = socket.readchar
					header += char
					break if char == "{"
				}
				payload << "{"


				depth = 1
				loop{   # get payload of packet.
					char = socket.readchar
					depth += 1 if char == "{"
					depth -= 1 if char == "}"
					payload << char
					break if depth == 0
				}
				socket.close

				data = payload.force_encoding('UTF-8').encode
				json = JSON.parse(data)
				return json

			rescue SocketError => e
				@logger.error("ServerStatus at #{__LINE__}, #{e.to_s}: #{e.message}")
				raise ServiceUnavailableError, e.message
			rescue Errno::EADDRNOTAVAIL => e
				@logger.error("ServerStatus at #{__LINE__}, #{e.to_s}: #{e.message}")
				raise ServiceUnavailableError, e.message
			rescue Errno::ECONNREFUSED => e
				@logger.error("ServerStatus at #{__LINE__}, #{e.to_s}: #{e.message}")
				raise ConnectionError, e.message
			rescue EOFError => e
				msg = "Minecraft server returns unexpected EOF."
				@logger.error("ServerStatus at #{__LINE__}, EOFError: #{msg}")
				raise ConnectionError, msg
			rescue JSON::ParserError
				msg = "Minecraft server returns unexpected tokens as JSON."
				@logger.error("ServerStatus at #{__LINE__}, JSON::ParserError: #{msg}")
				raise ConnectionError, msg
			rescue => e
				@logger.error("ServerStatus at #{__LINE__}, #{e.to_s}: #{e.message}")
				raise ConnectionError
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
				raise e, "parameter host must be present." if @host.nil?
				raise e, "parameter host must be String." unless @host.class == String

				raise e, "parameter port must be Integer." unless @port.class == Integer
				raise e, "parameter port must be in length 1~65535." unless 1 <= @port && @port <= 65535
			end
		end

		class InstanceVariableError < StandardError
			def initialize msg="is not correct value."
				super msg
			end
		end

		class ConnectionError < StandardError
			def initialize msg="Connection error, something is wrong."
				super msg
			end
		end

		class ServiceUnavailableError < StandardError
			def initialize msg="Service is unavailable."
				super msg
			end
		end
	end
end
