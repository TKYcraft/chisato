require 'rails_helper'

RSpec.describe "Api::V1::Servers::Statuses", type: :request do
	describe "index action" do
		# it "returns http success" do
		# 	get api_v1_servers_status_index_path params: {host: ""}
		# 	expect(response).to have_http_status(200)
		#	expect(response.headers["Access-Control-Allow-Origin"]).to eq "*"
		# end

		context "parameters" do
			context "port validation" do
				let(:server_status_tool) { instance_spy(Minetools::ServerStatusTool::ServerStatus) }
				let(:acl_tool) { instance_spy(Acl::Acl) }
				let(:server_status) { {
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
				}.deep_stringify_keys.freeze }

				before do
					allow(Minetools::ServerStatusTool::ServerStatus)
						.to receive(:new)
						.and_return(server_status_tool)

					allow(server_status_tool)
						.to receive(:status)
						.and_return(server_status)

					allow(Acl::Acl)
						.to receive(:new)
						.and_return(acl_tool)
				end

				context "MC_PORT_ALLOW_MORE_THAN: 8888" do
					before do
						stub_const("Api::V1::Servers::StatusController::MC_PORT_ALLOW_MORE_THAN", 8888)
					end

					context "request port: 8887" do
						it "deny request" do
							get api_v1_servers_status_index_path params: {host: "192.168.0.1", port: 8887}

							expect(Minetools::ServerStatusTool::ServerStatus).not_to have_received(:new)
							expect(Acl::Acl).not_to have_received(:new)

							expect(response).to have_http_status(400)
						end
					end

					context "request port: 8888" do
						it "deny request" do
							get api_v1_servers_status_index_path params: {host: "192.168.0.1", port: 8888}

							expect(Minetools::ServerStatusTool::ServerStatus).not_to have_received(:new)
							expect(Acl::Acl).not_to have_received(:new)

							expect(response).to have_http_status(400)
						end
					end

					context "request port: 8889" do
						it "allow request" do
							get api_v1_servers_status_index_path params: {host: "192.168.0.1", port: 8889}

							expect(Minetools::ServerStatusTool::ServerStatus).to have_received(:new).once
							expect(Acl::Acl).to have_received(:new).once

							expect(response).to have_http_status(200)
						end
					end
				end
			end

			context "host" do
				context "deny cases by ip address" do
					context "IPv4 addresses" do
						it "will deny with 192.168.0.1" do
							get api_v1_servers_status_index_path params: {host: "192.168.0.1"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "given IP Address is not allowed length."
						end

						it "will deny with 255.255.255.255" do
							get api_v1_servers_status_index_path params: {host: "255.255.255.255"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "given IP Address is not allowed length."
						end

						it "will deny with 127.0.0.1" do
							get api_v1_servers_status_index_path params: {host: "127.0.0.1"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "given IP Address is not allowed length."
						end
					end

					context "IPv6 addresses" do
						it "will deny with ::1" do
							get api_v1_servers_status_index_path params: {host: "::1"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "given IP Address is not allowed length."
						end

						it "will deny with fd00:cafe:cafe:cafe:cafe:cafe:cafe:cafe" do
							get api_v1_servers_status_index_path params: {host: "fd00:cafe:cafe:cafe:cafe:cafe:cafe:cafe"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "given IP Address is not allowed length."
						end

						it "will deny with febf:beef:beef:beef:beef:beef:beef:beef" do
							get api_v1_servers_status_index_path params: {host: "febf:beef:beef:beef:beef:beef:beef:beef"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "given IP Address is not allowed length."
						end
					end
				end
			end
		end
	end
end
