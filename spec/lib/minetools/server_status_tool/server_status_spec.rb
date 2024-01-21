require 'rails_helper'
require './lib/minetools/server_status_tool/server_status.rb'

RSpec.describe Minetools::ServerStatusTool::ServerStatus do
	let(:socket_mock){ instance_spy TCPSocket }

	it "is object of Minetools::ServerStatusTool::ServerStatus class" do
		status = Minetools::ServerStatusTool::ServerStatus.new host: "minecraft.example.com"
		expect(status.class).to eq(Minetools::ServerStatusTool::ServerStatus)
	end

	describe "methods" do
		describe "initialize()" do
			context "give correct only hostname" do
				it "set instance variables" do
					_h = "minecraft.example.com"
					server = Minetools::ServerStatusTool::ServerStatus.new host: _h
					expect(server.host).to eq _h
				end
			end

			context "give correct hostname and port" do
				it "set instance variables" do
					_h = "minecraft.example.com"
					_p = 25567

					server = Minetools::ServerStatusTool::ServerStatus.new host: _h, port: _p

					expect(server.host).to eq _h
					expect(server.port).to eq _p
				end
			end

			context "give bad parameter to host name" do
				it "raise ArgumentError with non-string" do
					_h = true
					expect{
						server = Minetools::ServerStatusTool::ServerStatus.new host: _h
					}.to raise_error ArgumentError
				end
			end

			context "give bad parameter to port" do
				it "raise ArgumentError with -1" do
					_h = "minecraft.example.com"
					_p = -1
					expect{
						server = Minetools::ServerStatusTool::ServerStatus.new host: _h, port: _p
					}.to raise_error ArgumentError
				end

				it "raise ArgumentError with 65536" do
					_h = "minecraft.example.com"
					_p = 65536
					expect{
						server = Minetools::ServerStatusTool::ServerStatus.new host: _h, port: _p
					}.to raise_error ArgumentError
				end

				it "raise ArgumentError with string" do
					_h = "minecraft.example.com"
					_p = "25565"
					expect{
						server = Minetools::ServerStatusTool::ServerStatus.new host: _h, port: _p
					}.to raise_error ArgumentError
				end
			end
		end

		describe "fetch_status()"
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
