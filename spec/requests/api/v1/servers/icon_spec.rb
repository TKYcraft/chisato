require 'rails_helper'

RSpec.describe "Api::V1::Servers::Icons", type: :request do
	describe "index action" do
		let(:server_status_tool) { instance_spy(Minetools::ServerStatusTool::ServerStatus) }
		let(:acl_tool) { instance_spy(Acl::Acl) }
		let(:favicon_bytes) { "fake png bytes" }
		let(:favicon) { "data:image/png;base64,#{Base64.strict_encode64(favicon_bytes)}" }
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
			favicon: favicon,
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
		end

		context "with stubbed Acl" do
			before do
				allow(Acl::Acl)
					.to receive(:new)
					.and_return(acl_tool)
			end

			context "server has a valid favicon" do
				it "returns decoded png with 200" do
					# Act
					get api_v1_servers_icon_index_path, params: {host: "example.com"}

					# Assert
					expect(response).to have_http_status 200
					expect(response.headers["Content-Type"]).to eq "image/png"
					expect(response.body).to eq favicon_bytes

					expect(response.headers["Access-Control-Allow-Origin"]).to eq "*"
					expect(response.headers["Cache-Control"]).to include "public"
					expect(response.headers["Cache-Control"]).to include "max-age=3600"
				end
			end

			context "favicon has a space after `data:` (existing fixture form)" do
				let(:favicon) { "data: image/png;base64,#{Base64.strict_encode64(favicon_bytes)}" }

				it "returns decoded png with 200" do
					# Act
					get api_v1_servers_icon_index_path, params: {host: "example.com"}

					# Assert
					expect(response).to have_http_status 200
					expect(response.headers["Content-Type"]).to eq "image/png"
					expect(response.body).to eq favicon_bytes
				end
			end

			context "give cache parameter" do
				it "returns 200 with no-cache when giving cache=no" do
					# Act
					get api_v1_servers_icon_index_path, params: {host: "example.com", cache: "no"}

					# Assert
					expect(response).to have_http_status 200
					expect(response.headers["Cache-Control"]).to include "no-cache"
				end
			end

			context "status has no favicon key" do
				let(:server_status) { {
					version: {
						name: "Spigot 1.20.1",
						protocol: 763
					},
					players: {
						max: 15,
						online: 1,
						sample: []
					},
					description: {
						extra: [
							{text: "Example Server Message."}
						],
						text: ""
					}
				}.deep_stringify_keys.freeze }

				it "returns 404 with empty body" do
					# Act
					get api_v1_servers_icon_index_path, params: {host: "example.com"}

					# Assert
					expect(response).to have_http_status 404
					expect(response.body).to be_empty

					expect(response.headers["Cache-Control"]).to include "no-cache"
					expect(response.headers["Cache-Control"]).not_to include "max-age=3600"
				end
			end

			context "favicon has non-png MIME prefix" do
				let(:favicon) { "data:image/jpeg;base64,#{Base64.strict_encode64(favicon_bytes)}" }

				it "returns 404 with empty body" do
					# Act
					get api_v1_servers_icon_index_path, params: {host: "example.com"}

					# Assert
					expect(response).to have_http_status 404
					expect(response.body).to be_empty
				end
			end

			context "favicon has invalid base64 payload" do
				let(:favicon) { "data:image/png;base64,%%%" }

				it "returns 404 with empty body" do
					# Act
					get api_v1_servers_icon_index_path, params: {host: "example.com"}

					# Assert
					expect(response).to have_http_status 404
					expect(response.body).to be_empty
				end
			end

			context "port validation" do
				context "MC_PORT_ALLOW_MORE_THAN: 8888" do
					before do
						stub_const("Api::V1::Servers::IconController::MC_PORT_ALLOW_MORE_THAN", 8888)
					end

					context "request port: 8887" do
						it "deny request" do
							get api_v1_servers_icon_index_path, params: {host: "192.168.0.1", port: 8887}

							expect(Minetools::ServerStatusTool::ServerStatus).not_to have_received(:new)
							expect(Acl::Acl).not_to have_received(:new)

							expect(response).to have_http_status(400)
						end
					end

					context "request port: 8888" do
						it "deny request" do
							get api_v1_servers_icon_index_path, params: {host: "192.168.0.1", port: 8888}

							expect(Minetools::ServerStatusTool::ServerStatus).not_to have_received(:new)
							expect(Acl::Acl).not_to have_received(:new)

							expect(response).to have_http_status(400)
						end
					end

					context "request port: 8889" do
						it "allow request" do
							get api_v1_servers_icon_index_path, params: {host: "192.168.0.1", port: 8889}

							expect(Minetools::ServerStatusTool::ServerStatus).to have_received(:new).once
							expect(Acl::Acl).to have_received(:new).once

							expect(response).to have_http_status(200)
						end
					end
				end
			end

			context "fetch_status! raises ServiceUnavailableError" do
				before do
					allow(server_status_tool)
						.to receive(:fetch_status!)
						.and_raise Minetools::ServerStatusTool::ServiceUnavailableError, "service unavailable."
				end

				it "returns 404 with json message" do
					# Act
					get api_v1_servers_icon_index_path, params: {host: "example.com"}

					# Assert
					json = JSON.parse response.body
					expect(response).to have_http_status 404
					expect(json["message"]).to eq "service unavailable."
				end
			end

			context "fetch_status! raises ConnectionError" do
				before do
					allow(server_status_tool)
						.to receive(:fetch_status!)
						.and_raise Minetools::ServerStatusTool::ConnectionError, "connection failed."
				end

				it "returns 500 with json message" do
					# Act
					get api_v1_servers_icon_index_path, params: {host: "example.com"}

					# Assert
					json = JSON.parse response.body
					expect(response).to have_http_status 500
					expect(json["message"]).to eq "connection failed."

					expect(response.headers["Cache-Control"]).to include "no-cache"
					expect(response.headers["Cache-Control"]).not_to include "max-age=3600"
				end
			end
		end

		context "with real Acl" do
			context "deny case by private ip address" do
				it "will deny with 192.168.0.1" do
					# Act
					get api_v1_servers_icon_index_path, params: {host: "192.168.0.1"}

					# Assert
					json = JSON.parse response.body
					expect(response).to have_http_status 400
					expect(json["message"]).to eq "given IP Address is not allowed length."
				end
			end
		end
	end
end
