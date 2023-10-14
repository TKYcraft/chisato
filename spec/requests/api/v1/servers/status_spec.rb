require 'rails_helper'

RSpec.describe "Api::V1::Servers::Statuses", type: :request do
	describe "index action" do
		# it "returns http success" do
		# 	get api_v1_servers_status_index_path params: {host: ""}
		# 	expect(response).to have_http_status(200)
		# end

		context "parameters" do
			context "host" do
				context "deny cases by ip address" do
					context "IPv4 local addresses" do
						context "192.168.x.x" do
							it "will deny with 192.168.0.0" do
								get api_v1_servers_status_index_path params: {host: "192.168.0.0"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end

							it "will deny with 192.168.0.1" do
								get api_v1_servers_status_index_path params: {host: "192.168.0.1"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end

							it "will deny with 192.168.255.254" do
								get api_v1_servers_status_index_path params: {host: "192.168.255.254"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end

							it "will deny with 192.168.255.255" do
								get api_v1_servers_status_index_path params: {host: "192.168.255.255"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end

							it "will deny with 192.168.24.10 (No reason)" do
								get api_v1_servers_status_index_path params: {host: "192.168.24.10"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end
						end

						context "172.16.x.x ~ 172.31.x.x" do
							it "will deny with 172.16.0.0" do
								get api_v1_servers_status_index_path params: {host: "172.16.0.0"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end

							it "will deny with 172.16.0.1" do
								get api_v1_servers_status_index_path params: {host: "172.16.0.1"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end

							it "will deny with 172.31.255.254" do
								get api_v1_servers_status_index_path params: {host: "172.31.255.254"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end

							it "will deny with 172.31.255.255" do
								get api_v1_servers_status_index_path params: {host: "172.31.255.255"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end

							it "will deny with 172.24.1.24 (No reason)" do
								get api_v1_servers_status_index_path params: {host: "172.24.1.24"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end
						end

						context "10.x.x.x" do
							it "will deny with 10.0.0.0" do
								get api_v1_servers_status_index_path params: {host: "10.0.0.0"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end

							it "will deny with 10.0.0.1" do
								get api_v1_servers_status_index_path params: {host: "10.0.0.1"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end

							it "will deny with 10.255.255.254" do
								get api_v1_servers_status_index_path params: {host: "10.255.255.254"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end

							it "will deny with 10.255.255.255" do
								get api_v1_servers_status_index_path params: {host: "10.255.255.255"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end

							it "will deny with 10.10.192.31 (No reason)" do
								get api_v1_servers_status_index_path params: {host: "10.10.192.31"}

								json = JSON.parse response.body
								expect(response).to have_http_status 400
								expect(json["message"]).to eq "Request to this host is not allowed."
							end
						end
					end

					context "IPv4 broadcast address" do
						it "will deny with 255.255.255.255" do
							get api_v1_servers_status_index_path params: {host: "255.255.255.255"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end
					end

					context "IPv4 loop-back addresses" do
						it "will deny with 127.0.0.0" do
							get api_v1_servers_status_index_path params: {host: "127.0.0.0"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with 127.0.0.1" do
							get api_v1_servers_status_index_path params: {host: "127.0.0.1"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with 127.255.255.254" do
							get api_v1_servers_status_index_path params: {host: "127.255.255.254"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with 127.255.255.255" do
							get api_v1_servers_status_index_path params: {host: "127.255.255.255"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with 127.0.0.53 (No reason)" do
							get api_v1_servers_status_index_path params: {host: "127.0.0.53"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end
					end

					context "IPv4 link-local address" do
						it "will deny with 169.254.0.0" do
							get api_v1_servers_status_index_path params: {host: "169.254.0.0"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with 169.254.0.1" do
							get api_v1_servers_status_index_path params: {host: "169.254.0.1"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with 169.254.255.254" do
							get api_v1_servers_status_index_path params: {host: "169.254.255.254"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with 169.254.255.255" do
							get api_v1_servers_status_index_path params: {host: "169.254.255.255"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with 169.254.1.10 (No reason)" do
							get api_v1_servers_status_index_path params: {host: "169.254.1.10"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end
					end

					context "IPv4 shared address space" do
						it "will deny with 100.64.0.0" do
							get api_v1_servers_status_index_path params: {host: "100.64.0.0"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with 100.64.0.1" do
							get api_v1_servers_status_index_path params: {host: "100.64.0.1"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with 100.127.255.254" do
							get api_v1_servers_status_index_path params: {host: "100.127.255.254"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with 100.127.255.255" do
							get api_v1_servers_status_index_path params: {host: "100.127.255.255"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with 100.96.64.32" do
							get api_v1_servers_status_index_path params: {host: "100.96.64.32"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end
					end

					context "IPv6 loop-back" do
						it "will deny with ::1" do
							get api_v1_servers_status_index_path params: {host: "::1"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end
					end

					context "IPv6 unique local addresses" do
						it "will deny with fc00:0000:0000:0000:0000:0000:0000:0000" do
							get api_v1_servers_status_index_path params: {host: "fc00:0000:0000:0000:0000:0000:0000:0000"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with fc00:0000:0000:0000:0000:0000:0000:0001" do
							get api_v1_servers_status_index_path params: {host: "fc00:0000:0000:0000:0000:0000:0000:0001"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with fdff:ffff:ffff:ffff:ffff:ffff:ffff:fffe" do
							get api_v1_servers_status_index_path params: {host: "fdff:ffff:ffff:ffff:ffff:ffff:ffff:fffe"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff" do
							get api_v1_servers_status_index_path params: {host: "fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with fd00:cafe:cafe:cafe:cafe:cafe:cafe:cafe (No reason)" do
							get api_v1_servers_status_index_path params: {host: "fd00:cafe:cafe:cafe:cafe:cafe:cafe:cafe"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end
					end

					context "IPv6 link local addresses" do
						it "will deny with fe80:0000:0000:0000:0000:0000:0000:0000" do
							get api_v1_servers_status_index_path params: {host: "fe80:0000:0000:0000:0000:0000:0000:0000"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with fe80:0000:0000:0000:0000:0000:0000:0001" do
							get api_v1_servers_status_index_path params: {host: "fe80:0000:0000:0000:0000:0000:0000:0001"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with febf:ffff:ffff:ffff:ffff:ffff:ffff:fffe" do
							get api_v1_servers_status_index_path params: {host: "febf:ffff:ffff:ffff:ffff:ffff:ffff:fffe"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff" do
							get api_v1_servers_status_index_path params: {host: "febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with febf:beef:beef:beef:beef:beef:beef:beef (No reason)" do
							get api_v1_servers_status_index_path params: {host: "febf:beef:beef:beef:beef:beef:beef:beef"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end
					end

					context "IPv6 multicast address on interface local" do
						it "will deny with ff01::1" do
							get api_v1_servers_status_index_path params: {host: "ff01::1"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with ff01:0000:0000:0000:0000:0000:0000:0001" do
							get api_v1_servers_status_index_path params: {host: "ff01:0000:0000:0000:0000:0000:0000:0001"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end
					end

					context "IPv6 multicast address on link local" do
						it "will deny with ff02::1" do
							get api_v1_servers_status_index_path params: {host: "ff01::1"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end

						it "will deny with ff02:0000:0000:0000:0000:0000:0000:0001" do
							get api_v1_servers_status_index_path params: {host: "ff01:0000:0000:0000:0000:0000:0000:0001"}

							json = JSON.parse response.body
							expect(response).to have_http_status 400
							expect(json["message"]).to eq "Request to this host is not allowed."
						end
					end
				end

				context "deny cases by domains" do
					it "will deny with not exsits top level domain" do
						get api_v1_servers_status_index_path params: {host: "minecraft.example.com.hogehoge"}

						json = JSON.parse response.body
						expect(response).to have_http_status 400
						expect(json["message"]).to eq "given TLD of hostname is not correct."
					end

					it "will deny with .local domain" do
						get api_v1_servers_status_index_path params: {host: "example.local"}

						json = JSON.parse response.body
						expect(response).to have_http_status 400
						expect(json["message"]).to eq "given TLD of hostname is not correct."
					end

					it "will deny with localhost domain" do
						get api_v1_servers_status_index_path params: {host: "localhost"}

						json = JSON.parse response.body
						expect(response).to have_http_status 400
						expect(json["message"]).to eq "given TLD of hostname is not correct."
					end

					it "will deny with hogehoge-pc domain" do
						get api_v1_servers_status_index_path params: {host: "hogehoge-pc"}

						json = JSON.parse response.body
						expect(response).to have_http_status 400
						expect(json["message"]).to eq "given host is not IP address or correct hostname."
					end
				end
			end
		end
	end
end
