require 'rails_helper'

RSpec.describe "Api::V1::Servers::Statuses", type: :request do
	describe "index action" do
		# it "returns http success" do
		# 	get api_v1_servers_status_index_path params: {host: ""}
		# 	expect(response).to have_http_status(200)
		#	expect(response.headers["Access-Control-Allow-Origin"]).to eq "*"
		# end

		context "parameters" do
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
