require 'rails_helper'
require './lib/acl/acl.rb'

RSpec.describe Acl::Acl do
	it "is object of Acl::Acl class" do
		acl = Acl::Acl.new "example.com", App::Application.config.tld_list["TLD"]
		expect(acl.class).to eq(Acl::Acl)
	end

	describe "methods" do
		describe "initialize()" do
			context "errors" do
				context "host ArgumentError" do
					it "raise error by host is number." do
						expect{Acl::Acl.new 1, ["COM"]}.to raise_error ArgumentError
					end

					it "raise error by host is nil." do
						expect{Acl::Acl.new nil, ["COM"]}.to raise_error ArgumentError
					end

					it "raise error by host is false." do
						expect{Acl::Acl.new false, ["COM"]}.to raise_error ArgumentError
					end

					it "raise error by host is true." do
						expect{Acl::Acl.new true, ["COM"]}.to raise_error ArgumentError
					end
				end

				context "tld_list ArgumentError" do
					it "raise error by tld_list is hash." do
						expect{Acl::Acl.new "example.com", {"COM" => true}}.to raise_error ArgumentError
					end

					it "raise error by tld_list is nil." do
						expect{Acl::Acl.new "example.com", nil}.to raise_error ArgumentError
					end

					it "raise error by tld_list is false." do
						expect{Acl::Acl.new "example.com", false}.to raise_error ArgumentError
					end

					it "raise error by tld_list is true." do
						expect{Acl::Acl.new "example.com", true}.to raise_error ArgumentError
					end

					it "raise error by tld_list is empty Array []." do
						expect{Acl::Acl.new "example.com", []}.to raise_error ArgumentError
					end

					xit "raise error by tld_list is Array of numbers." do
						# Issue #53
						expect{Acl::Acl.new "example.com", [1,2,3]}.to raise_error ArgumentError
					end
				end
			end
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

	describe "CONST_VALUES" do
		describe "DENY_IP_ADDRESSES" do
			context "IPv4" do
				it "contains 192.168.0.0/16" do
					expect(Acl::Acl::DENY_IP_ADDRESSES).to include("192.168.0.0/16")
				end

				it "contains 172.16.0.0/12" do
					expect(Acl::Acl::DENY_IP_ADDRESSES).to include("172.16.0.0/12")
				end

				it "contains 10.0.0.0/8" do
					expect(Acl::Acl::DENY_IP_ADDRESSES).to include("10.0.0.0/8")
				end

				it "contains 255.255.255.255 broadcast" do
					expect(Acl::Acl::DENY_IP_ADDRESSES).to include("255.255.255.255")
				end

				it "contains 127.0.0.0/8 loop back" do
					expect(Acl::Acl::DENY_IP_ADDRESSES).to include("127.0.0.0/8")
				end

				it "contains 169.254.0.0/16 link local" do
					expect(Acl::Acl::DENY_IP_ADDRESSES).to include("169.254.0.0/16")
				end

				it "contains 100.64.0.0/10 shared address space ref: RFC6890" do
					expect(Acl::Acl::DENY_IP_ADDRESSES).to include("100.64.0.0/10")
				end
			end

			context "IPv6" do
				it "contains ::1/128 loop back" do
					expect(Acl::Acl::DENY_IP_ADDRESSES).to include("::1/128")
				end
				it "contains fc00::/7 unique local" do
					expect(Acl::Acl::DENY_IP_ADDRESSES).to include("fc00::/7")
				end
				it "contains fe80::/10 link local" do
					expect(Acl::Acl::DENY_IP_ADDRESSES).to include("fe80::/10")
				end
				it "contains ff01::1 multicast on interface local" do
					expect(Acl::Acl::DENY_IP_ADDRESSES).to include("ff01::1")
				end
				it "contains ff02::1 multicast on link local" do
					expect(Acl::Acl::DENY_IP_ADDRESSES).to include("ff02::1")
				end
			end
		end
	end
end

RSpec.describe Acl::DeniedHostError do
	it "raise error" do
		expect{raise Acl::DeniedHostError}.to raise_error Acl::DeniedHostError
	end

	it "raise error with default message." do
		expect{raise Acl::DeniedHostError}.to raise_error Acl::DeniedHostError, "Request to this host is not allowed."
	end

	it "raise error with custom message." do
		expect{raise Acl::DeniedHostError, "foo"}.to raise_error Acl::DeniedHostError, "foo"
	end
end
