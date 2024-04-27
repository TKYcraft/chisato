require 'rails_helper'
require './lib/minetools/server_status_tool/server_status.rb'

RSpec.describe Minetools::ServerStatusTool::ServerStatus do
	let(:logger_mock){ instance_spy Logger }
	let(:server) { described_class.new host: "minecraft.example.com", logger: logger_mock }
	let(:socket_mock){ instance_spy TCPSocket }

	before do
		allow(logger_mock).to receive(:error).and_raise RuntimeError
	end

	it "is object of Minetools::ServerStatusTool::ServerStatus class" do
		server
		expect(server.class).to eq(described_class)
	end

	describe "methods" do
		describe "initialize()" do
			context "giving correct only hostname" do
				it "set instance variables" do
					_h = "minecraft.example.com"
					server = described_class.new host: _h
					expect(server.host).to eq _h
					expect(server.port).to eq 25565
					expect(server.instance_variable_get(:@logger).class).to eq Logger
					expect(server.instance_variable_get(:@status)).to eq nil
					expect(server.instance_variable_get(:@socket)).to eq nil
				end
			end

			context "giving correct hostname and port" do
				it "set instance variables" do
					_h = "minecraft.example.com"
					_p = 25567

					server = described_class.new host: _h, port: _p

					expect(server.host).to eq _h
					expect(server.port).to eq _p
				end
			end

			context "giving bad parameter to host name" do
				it "raise ArgumentError with non-string" do
					_h = true
					expect{
						described_class.new host: _h
					}.to raise_error ArgumentError
				end
			end

			context "giving bad parameter to port" do
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

			context "giving custom logger instance" do
				it "set custom logger instance" do
					class CustomLogger < Logger; end
					_l = CustomLogger.new($stdout)
					_h = "minecraft.example.com"

					server = described_class.new host: _h, logger: _l
					expect(server.instance_variable_get(:@logger).class).to eq CustomLogger
					expect(server.instance_variable_get(:@logger)).to be _l
				end
			end
		end

		describe "fetch_status()" do
			before do
				allow(server).to receive(:socket)
			end

			context "correct case" do
				let(:expected_payload){
					{
						version: {
							name: "Spigot 1.20.1",
							protocol: 763
						},
						players: {
							max: 15,
							online: 1,
							sample: [{
								name: "example",
								id: "cafecafe-cafe1234"
							}]
						},
						description: {
							extra: [
								{text: "Example Server Message."}
							],
							text: ""
						},
						favicon: "data: image/png;base64,SampleBase64Characters",
						modinfo: {
							type: "FML",
							modList: []
						}
					}.freeze
				}

				let(:characters){
					("??" + expected_payload.to_json())
						.gsub("\t", "").gsub("\n", "").split("")
				}

				before do
					allow(server).to receive(:socket).and_return socket_mock
					allow(socket_mock).to receive(:write).and_return nil
					allow(socket_mock).to receive(:readchar).and_return *characters
				end

				it "returns hash object" do
					res = server.fetch_status
					expect(res.class).to eq Hash

					# version
					expect(res["version"]).to be_present
					expect(res["version"]["name"]).to eq expected_payload[:version][:name]
					expect(res["version"]["protocol"]).to eq expected_payload[:version][:protocol]

					# players
					expect(res["players"]).to be_present
					expect(res["players"]["max"]).to eq expected_payload[:players][:max]
					expect(res["players"]["online"]).to eq expected_payload[:players][:online]

					# player sample
					expect(res["players"]["sample"]).to be_present
					res_p_sample = res["players"]["sample"]
					exp_p_sample = expected_payload[:players][:sample]

					expect(res_p_sample.first["name"]).to eq exp_p_sample.first[:name]
					expect(res_p_sample.first["id"]).to eq exp_p_sample.first[:id]

					# description
					expect(res["description"]).to be_present
					expect(res["description"]["extra"].first["text"]).to eq expected_payload[:description][:extra].first[:text]
					expect(res["description"]["text"]).to eq expected_payload[:description][:text]

					# favicon
					expect(res["favicon"]).to eq expected_payload[:favicon]

					# modinfo
					expect(res["modinfo"]).to be_present
					expect(res["modinfo"]["type"]).to eq expected_payload[:modinfo][:type]
					expect(res["modinfo"]["modList"]).to eq expected_payload[:modinfo][:modList]
				end
			end

			context "create socket instance and get connection" do
				context "when TCPSocket raises SocketError" do
					before do
						allow(server).to receive(:socket).and_raise SocketError
						allow(logger_mock).to receive(:error).and_return nil
					end

					it "raise ServiceUnavailableError" do
						expect{
							server.fetch_status()
						}.to raise_error Minetools::ServerStatusTool::ServiceUnavailableError

						expect(logger_mock).to have_received(:error).once
					end
				end

				context "when TCPSocket raises Errno::EADDRNOTAVAIL" do
					before do
						allow(server).to receive(:socket).and_raise Errno::EADDRNOTAVAIL
						allow(logger_mock).to receive(:error).and_return nil
					end

					it "raise ServiceUnavailableError" do
						expect{
							server.fetch_status()
						}.to raise_error Minetools::ServerStatusTool::ServiceUnavailableError

						expect(logger_mock).to have_received(:error).once
					end
				end

				context "when TCPSocket raises Errno::ECONNREFUSED" do
					before do
						allow(server).to receive(:socket).and_raise Errno::ECONNREFUSED
						allow(logger_mock).to receive(:error).and_return nil
					end

					it "raise ServiceUnavailableError" do
						expect{
							server.fetch_status()
						}.to raise_error Minetools::ServerStatusTool::ConnectionError

						expect(logger_mock).to have_received(:error).once
					end
				end

				context "when TCPSocket raises another Error" do
					before do
						allow(server).to receive(:socket).and_raise RuntimeError
						allow(logger_mock).to receive(:error).and_return nil
					end

					it "raise ServiceUnavailableError" do
						expect{
							server.fetch_status()
						}.to raise_error Minetools::ServerStatusTool::ConnectionError

						expect(logger_mock).to have_received(:error).once
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
							allow(logger_mock).to receive(:error).and_return nil
						end

						it "raise Minetools::ServerStatusTool::ConnectionError" do
							expect{
								server.fetch_status()
							}.to raise_error Minetools::ServerStatusTool::ConnectionError

							expect(logger_mock).to have_received(:error).once
						end
					end
				end

				context "socket raises EOFError when reading packet." do
					before do
						allow(socket_mock).to receive(:write).and_return nil
						allow(socket_mock).to receive(:readchar).and_raise EOFError
						allow(logger_mock).to receive(:error).and_return nil
					end

					it "raise Minetools::ServerStatusTool::ConnectionError" do
						expect{
							server.fetch_status()
						}.to raise_error Minetools::ServerStatusTool::ConnectionError

						expect(logger_mock).to have_received(:error).once
					end
				end

				context "JSON parser raises JSON::ParserError" do
					before do
						allow(socket_mock).to receive(:write).and_return nil
						allow(socket_mock).to receive(:readchar).and_return "{", "}"
						allow(socket_mock).to receive(:close).and_return nil
						allow(JSON).to receive(:parse).and_raise JSON::ParserError
						allow(logger_mock).to receive(:error).and_return nil
					end

					it "raise Minetools::ServerStatusTool::ConnectionError" do
						expect{
							server.fetch_status()
						}.to raise_error Minetools::ServerStatusTool::ConnectionError

						expect(logger_mock).to have_received(:error).once
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
