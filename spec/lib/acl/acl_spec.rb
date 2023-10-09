require 'rails_helper'
require './lib/acl/acl.rb'

RSpec.describe Acl::Acl do
	it "is object of Acl::Acl class" do
		acl = Acl::Acl.new "", App::Application.config.tld_list["TLD"]
		expect(acl.class).to eq(Acl::Acl)
	end

	describe "methods" do
		describe "initialize()" do
			
		end

		describe "filter!" do
			context "deny cases" do
				context "deny cases by ip address" do
					context "IPv4 local addresses" do
						context "192.168.x.x" do
							it "will deny with 192.168.0.0" do
								acl = Acl::Acl.new "192.168.0.0", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end

							it "will deny with 192.168.0.1" do
								acl = Acl::Acl.new "192.168.0.1", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end

							it "will deny with 192.168.255.254" do
								acl = Acl::Acl.new "192.168.255.254", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end

							it "will deny with 192.168.255.255" do
								acl = Acl::Acl.new "192.168.255.255", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end

							it "will deny with 192.168.24.10 (No reason)" do
								acl = Acl::Acl.new "192.168.24.10", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end
						end

						context "172.16.x.x ~ 172.31.x.x" do
							it "will deny with 172.16.0.0" do
								acl = Acl::Acl.new "172.16.0.0", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end

							it "will deny with 172.16.0.1" do
								acl = Acl::Acl.new "172.16.0.1", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end

							it "will deny with 172.31.255.254" do
								acl = Acl::Acl.new "172.31.255.254", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end

							it "will deny with 172.31.255.255" do
								acl = Acl::Acl.new "172.31.255.255", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end

							it "will deny with 172.24.1.24 (No reason)" do
								acl = Acl::Acl.new "172.24.1.24", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end
						end

						context "10.x.x.x" do
							it "will deny with 10.0.0.0" do
								acl = Acl::Acl.new "10.0.0.0", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end

							it "will deny with 10.0.0.1" do
								acl = Acl::Acl.new "10.0.0.1", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end

							it "will deny with 10.255.255.254" do
								acl = Acl::Acl.new "10.255.255.254", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end

							it "will deny with 10.255.255.255" do
								acl = Acl::Acl.new "10.255.255.255", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end

							it "will deny with 10.10.192.31 (No reason)" do
								acl = Acl::Acl.new "10.10.192.31", ["COM"]
								expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
							end
						end
					end

					context "IPv4 broadcast address" do
						it "will deny with 255.255.255.255" do
							acl = Acl::Acl.new "255.255.255.255", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end
					end

					context "IPv4 loop-back addresses" do
						it "will deny with 127.0.0.0" do
							acl = Acl::Acl.new "127.0.0.0", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with 127.0.0.1" do
							acl = Acl::Acl.new "127.0.0.1", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with 127.255.255.254" do
							acl = Acl::Acl.new "127.255.255.254", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with 127.255.255.255" do
							acl = Acl::Acl.new "127.255.255.255", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with 127.0.0.53 (No reason)" do
							acl = Acl::Acl.new "127.0.0.53", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end
					end

					context "IPv4 link-local address" do
						it "will deny with 169.254.0.0" do
							acl = Acl::Acl.new "169.254.0.0", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with 169.254.0.1" do
							acl = Acl::Acl.new "169.254.0.1", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with 169.254.255.254" do
							acl = Acl::Acl.new "169.254.255.254", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with 169.254.255.255" do
							acl = Acl::Acl.new "169.254.255.255", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with 169.254.1.10 (No reason)" do
							acl = Acl::Acl.new "169.254.1.10", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end
					end

					context "IPv4 shared address space" do
						it "will deny with 100.64.0.0" do
							acl = Acl::Acl.new "100.64.0.0", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with 100.64.0.1" do
							acl = Acl::Acl.new "100.64.0.1", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with 100.127.255.254" do
							acl = Acl::Acl.new "100.127.255.254", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with 100.127.255.255" do
							acl = Acl::Acl.new "100.127.255.255", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with 100.96.64.32" do
							acl = Acl::Acl.new "100.96.64.32", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end
					end

					context "IPv6 loop-back" do
						it "will deny with ::1" do
							acl = Acl::Acl.new "::1", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end
					end

					context "IPv6 unique local addresses" do
						it "will deny with fc00:0000:0000:0000:0000:0000:0000:0000" do
							acl = Acl::Acl.new "fc00:0000:0000:0000:0000:0000:0000:0000", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with fc00:0000:0000:0000:0000:0000:0000:0001" do
							acl = Acl::Acl.new "fc00:0000:0000:0000:0000:0000:0000:0001", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with fdff:ffff:ffff:ffff:ffff:ffff:ffff:fffe" do
							acl = Acl::Acl.new "fdff:ffff:ffff:ffff:ffff:ffff:ffff:fffe", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff" do
							acl = Acl::Acl.new "fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with fd00:cafe:cafe:cafe:cafe:cafe:cafe:cafe (No reason)" do
							acl = Acl::Acl.new "fd00:cafe:cafe:cafe:cafe:cafe:cafe:cafe", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end
					end

					context "IPv6 link local addresses" do
						it "will deny with fe80:0000:0000:0000:0000:0000:0000:0000" do
							acl = Acl::Acl.new "fe80:0000:0000:0000:0000:0000:0000:0000", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with fe80:0000:0000:0000:0000:0000:0000:0001" do
							acl = Acl::Acl.new "fe80:0000:0000:0000:0000:0000:0000:0001", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with febf:ffff:ffff:ffff:ffff:ffff:ffff:fffe" do
							acl = Acl::Acl.new "febf:ffff:ffff:ffff:ffff:ffff:ffff:fffe", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff" do
							acl = Acl::Acl.new "febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with febf:beef:beef:beef:beef:beef:beef:beef (No reason)" do
							acl = Acl::Acl.new "febf:beef:beef:beef:beef:beef:beef:beef", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end
					end

					context "IPv6 multicast address on interface local" do
						it "will deny with ff01::1" do
							acl = Acl::Acl.new "ff01::1", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with ff01:0000:0000:0000:0000:0000:0000:0001" do
							acl = Acl::Acl.new "ff01:0000:0000:0000:0000:0000:0000:0001", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end
					end

					context "IPv6 multicast address on link local" do
						it "will deny with ff02::1" do
							acl = Acl::Acl.new "ff01::1", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end

						it "will deny with ff02:0000:0000:0000:0000:0000:0000:0001" do
							acl = Acl::Acl.new "ff01:0000:0000:0000:0000:0000:0000:0001", ["COM"]
							expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given IP Address is not allowed length."
						end
					end
				end

				context "deny cases by correct domains" do
					it "will deny with not exsits top level domain" do
						acl = Acl::Acl.new "minecraft.example.com.hogehoge", ["COM"]
						expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given TLD of hostname is not correct."
					end

					it "will deny with .local domain" do
						acl = Acl::Acl.new "example.local", ["COM"]
						expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given TLD of hostname is not correct."
					end

					it "will deny with localhost domain" do
						acl = Acl::Acl.new "localhost", ["COM"]
						expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given TLD of hostname is not correct."
					end
				end

				context "deny cases by bad domain names" do
					it "will deny with hogehoge-pc domain" do
						# Can not parse as hostname and IPaddress.
						acl = Acl::Acl.new "hogehoge-pc", ["COM"]
						expect{acl.filter!}.to raise_error ArgumentError
					end
				end

				context "deny cases by domain which is not include TLD list." do
					it "will deny with example.com with excluding com domain list" do
						acl = Acl::Acl.new "example.com", ["ORG", "NET"]
						expect{acl.filter!}.to raise_error Acl::DeniedHostError, "given TLD of hostname is not correct."
					end
				end
			end

			context "allow cases" do
				context "allow hostname" do
					it "will allow example.com" do
						acl = Acl::Acl.new "example.com", ["COM"]
						expect{acl.filter!}.not_to raise_error
					end
				end

				context "allow IP addresses" do
					it "will allow 203.0.113.1" do
						# This address is length of RFC6890 TEST-NET-2 203.0.113.0/24
						acl = Acl::Acl.new "203.0.113.1", ["COM"]
						expect{acl.filter!}.not_to raise_error
					end
				end
			end
		end
	end
end
