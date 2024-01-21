require 'rails_helper'
require './lib/minetools/server_status_tool/server_status.rb'

RSpec.describe Minetools::ServerStatusTool::ServerStatus do
	let(:server) { described_class.new host: "minecraft.example.com" }
	let(:socket_mock){ instance_spy TCPSocket }

	it "is object of Minetools::ServerStatusTool::ServerStatus class" do
		server
		expect(server.class).to eq(described_class)
	end

	describe "methods" do
		describe "initialize()" do
			context "give correct only hostname" do
				it "set instance variables" do
					_h = "minecraft.example.com"
					server = described_class.new host: _h
					expect(server.host).to eq _h
				end
			end

			context "give correct hostname and port" do
				it "set instance variables" do
					_h = "minecraft.example.com"
					_p = 25567

					server = described_class.new host: _h, port: _p

					expect(server.host).to eq _h
					expect(server.port).to eq _p
				end
			end

			context "give bad parameter to host name" do
				it "raise ArgumentError with non-string" do
					_h = true
					expect{
						described_class.new host: _h
					}.to raise_error ArgumentError
				end
			end

			context "give bad parameter to port" do
				it "raise ArgumentError with -1" do
					_h = "minecraft.example.com"
					_p = -1
					expect{
						described_class.new host: _h, port: _p
					}.to raise_error ArgumentError
				end

				it "raise ArgumentError with 65536" do
					_h = "minecraft.example.com"
					_p = 65536
					expect{
						described_class.new host: _h, port: _p
					}.to raise_error ArgumentError
				end

				it "raise ArgumentError with string" do
					_h = "minecraft.example.com"
					_p = "25565"
					expect{
						described_class.new host: _h, port: _p
					}.to raise_error ArgumentError
				end
			end
		end

		describe "fetch_status()" do
			before do
				allow(server).to receive(:socket)
			end

			context "create socket instance and get connection" do
				context "when TCPSocket raises SocketError" do
					before do
						allow(server).to receive(:socket).and_raise SocketError
					end

					it "raise ServiceUnavailableError" do
						expect{
							server.fetch_status()
						}.to raise_error Minetools::ServerStatusTool::ServiceUnavailableError
					end
				end

				context "when TCPSocket raises Errno::EADDRNOTAVAIL" do
					before do
						allow(server).to receive(:socket).and_raise Errno::EADDRNOTAVAIL
					end

					it "raise ServiceUnavailableError" do
						expect{
							server.fetch_status()
						}.to raise_error Minetools::ServerStatusTool::ServiceUnavailableError
					end
				end

				context "when TCPSocket raises Errno::ECONNREFUSED" do
					before do
						allow(server).to receive(:socket).and_raise Errno::ECONNREFUSED
					end

					it "raise ServiceUnavailableError" do
						expect{
							server.fetch_status()
						}.to raise_error Minetools::ServerStatusTool::ConnectionError
					end
				end

				context "when TCPSocket raises another Error" do
					before do
						allow(server).to receive(:socket).and_raise RuntimeError
					end

					it "raise ServiceUnavailableError" do
						expect{
							server.fetch_status()
						}.to raise_error Minetools::ServerStatusTool::ConnectionError
					end
				end
			end

			context "get characters" do
				before do
					allow(server).to receive(:socket).and_return socket_mock
					allow(socket_mock).to receive(:write).and_raise RuntimeError
					allow(socket_mock).to receive(:readchar).and_raise RuntimeError
				end

				context "socket raises Error when sending packet." do
					context "Errno::ECONNREFUSED" do
						before do
							allow(socket_mock).to receive(:write).and_raise Errno::ECONNREFUSED
						end

						it "raise Minetools::ServerStatusTool::ConnectionError" do
							expect{
								server.fetch_status()
							}.to raise_error Minetools::ServerStatusTool::ConnectionError
						end
					end
				end

				context "socket raises EOFError when reading packet." do
					before do
						allow(socket_mock).to receive(:write).and_return nil
						allow(socket_mock).to receive(:readchar).and_raise EOFError
					end

					it "raise Minetools::ServerStatusTool::ConnectionError" do
						expect{
							server.fetch_status()
						}.to raise_error Minetools::ServerStatusTool::ConnectionError
					end
				end

				context "JSON parser raises JSON::ParserError" do
					before do
						allow(socket_mock).to receive(:write).and_return nil
						allow(socket_mock).to receive(:readchar).and_return "{", "}"
						allow(socket_mock).to receive(:close).and_return nil
						allow(JSON).to receive(:parse).and_raise JSON::ParserError
					end

					it "raise Minetools::ServerStatusTool::ConnectionError" do
						expect{
							server.fetch_status()
						}.to raise_error Minetools::ServerStatusTool::ConnectionError
					end
				end
			end
		end
	end
end

RSpec.describe Minetools::ServerStatusTool::InstanceVariableError do
	it "raise Minetools::ServerStatusTool::InstanceVariableError" do
		expect{
			raise described_class
		}.to raise_error described_class
	end
end

RSpec.describe Minetools::ServerStatusTool::ConnectionError do
	it "raise Minetools::ServerStatusTool::ConnectionError" do
		expect{
			raise described_class
		}.to raise_error described_class
	end
end

RSpec.describe Minetools::ServerStatusTool::ServiceUnavailableError do
	it "raise Minetools::ServerStatusTool::ServiceUnavailableError" do
		expect{
			raise described_class
		}.to raise_error described_class
	end
end
