require 'rails_helper'
require './lib/minetools/face_tool/face.rb'

RSpec.describe Minetools::FaceTool::Face do
	let(:logger_mock){ instance_spy Logger }

	let(:face){ described_class.new logger: logger_mock }
	let(:http_mock){ instance_spy(Net::HTTP) }
	let(:uuid_api_response_sample){{
		id: "7125ba8b1c864508b92bb5c042ccfe2b",
		name: "KrisJelbring",
		test: true
	}.to_json}
	let(:profile_api_response_sample){{
		id: "7125ba8b1c864508b92bb5c042ccfe2b",
		name: "KrisJelbring",
		properties: [{
			name: "textures",
			value: "ewogICJ0aW1lc3RhbXAiIDogMTcwNDIxMjgwMTgxNCwKICAicHJvZmlsZUlkIiA6ICI3MTI1YmE4YjFjODY0NTA4YjkyYmI1YzA0MmNjZmUyYiIsCiAgInByb2ZpbGVOYW1lIiA6ICJLcmlzSmVsYnJpbmciLAogICJ0ZXh0dXJlcyIgOiB7CiAgICAiU0tJTiIgOiB7CiAgICAgICJ1cmwiIDogImh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvYjQ3YjIxYmIzZTdmNzliZGYyYTVlOGUwNDFmN2ZmOWUxNzhkYzE1NjQ1ZjY0NDliOGU1NWY5MDY2MDRjMDdmOSIKICAgIH0sCiAgICAiQ0FQRSIgOiB7CiAgICAgICJ1cmwiIDogImh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvNTc4NmZlOTliZTM3N2RmYjY4NTg4NTlmOTI2YzRkYmM5OTU3NTFlOTFjZWUzNzM0NjhjNWZiZjQ4NjVlNzE1MSIKICAgIH0KICB9Cn0="
		}],
		profileActions: [],
		test: true
	}.to_json}
	let(:skin_image_fixture){ Magick::Image.read('./spec/fixtures/skin_image_fixture.png').first }

	before do
		face
		allow(face).to receive(:http_get).and_raise RuntimeError
		allow(face).to receive(:get_image_from).and_raise RuntimeError
		# TODO: raise RuntimeError
	end

	it "is object of Minetools::FaceTool::Face class" do
		expect(face.class).to eq(described_class)
	end

	describe "methods" do
		describe "initialize()" do
			context "giveing arguments" do
				it "set instance variables" do
					class CustomLogger < Logger; end
					_n = "KrisJelbring"   # KrisJelbring is developer of minecraft
					_s = 1024
					_l = CustomLogger.new($stdout)

					face = described_class.new name: _n, size: _s, logger: _l

					expect(face.name).to eq _n
					expect(face.size).to eq _s
					expect(face.instance_variable_get(:@logger).class).to eq CustomLogger
					expect(face.instance_variable_get(:@logger)).to be _l
				end
			end

			context "not giving logger instance" do
				it "set default logger instance to instance variable" do
					_n = "KrisJelbring"   # KrisJelbring is developer of minecraft
					_s = 1024

					face = described_class.new name: _n, size: _s
					
					expect(face.instance_variable_get(:@logger).class).to eq Logger
				end
			end
		end

		describe "get_minecraft_uuid()" do
			context "give correct name" do
				before do
					allow(face).to receive(:http_get).and_return(uuid_api_response_sample)
				end

				it "returns currect uuid" do
					uuid = face.get_minecraft_uuid 'KrisJelbring'
					expect(uuid).to eq "7125ba8b1c864508b92bb5c042ccfe2b"
				end
			end

			context "give none-existent user name" do
				before do
					result = '{
						"path" : "/users/profiles/minecraft/!!!",
						"errorMessage" : "Couldn\'t find any profile with name !!!"
					}'
					allow(face).to receive(:http_get).and_return(result)
				end

				it "raise GetUUIDError" do
					# Can't get '!!!' as user name of minecraft.
					expect{face.get_minecraft_uuid '!!!'}.to raise_error(Minetools::FaceTool::GetUUIDError)
				end
			end

			context "give nothing" do
				it "raise ArgumentError" do
					expect{face.get_minecraft_uuid}.to raise_error(ArgumentError)
				end
			end

			context "give argument which is not String" do
				it "raise ArgumentError" do
					expect{face.get_minecraft_uuid -1}.to raise_error(ArgumentError)
				end
			end

			context "give empty String" do
				it "raise ArgumentError" do
					expect{face.get_minecraft_uuid ""}.to raise_error(ArgumentError)
				end
			end

			context "give nil" do
				it "raise ArgumentError" do
					expect{face.get_minecraft_uuid nil}.to raise_error(ArgumentError)
				end
			end
		end

		describe "request_json()" do
			context "give correct url" do
				before do
					allow(face).to receive(:http_get).and_return(uuid_api_response_sample)
				end

				it "returns hash object" do
					json = face.request_json "https://correct.api.example.com/users/1"
					expect(json.class).to eq Hash
				end
			end

			context "give nothing" do
				it "raise ArgumentError" do
					expect{face.request_json}.to raise_error(ArgumentError)
				end
			end

			context "give argument which is not String" do
				it "raise ArgumentError" do
					expect{face.request_json -1}.to raise_error(ArgumentError)
				end
			end

			context "give empty String" do
				it "raise ArgumentError" do
					expect{face.request_json ""}.to raise_error(ArgumentError)
				end
			end

			context "give nil" do
				it "raise ArgumentError" do
					expect{face.request_json nil}.to raise_error(ArgumentError)
				end
			end

			context "give url which is non-exists site" do
				before do
					allow(face).to receive(:http_get).and_raise(SocketError)
				end

				it "raise APIRequestError" do
					expect{face.request_json "https://example.example.com/"}.to raise_error(Minetools::FaceTool::APIRequestError)
				end
			end

			context "give url which is not able to parse json" do
				before do
					result = '<h1>Hello World!</h1>'
					allow(face).to receive(:http_get).and_return(result)
				end

				it "raise APIRequestError" do
					expect{face.request_json "https://example.com/"}.to raise_error(Minetools::FaceTool::APIRequestError)
				end
			end
		end

		describe "get_minecraft_profile()" do
			context "give correct uuid" do
				before do
					allow(face).to receive(:http_get).and_return(profile_api_response_sample)
				end

				it "returns correct profile" do
					# This is uuid of KrisJelbring, he is developer of minecraft.
					uuid = "7125ba8b1c864508b92bb5c042ccfe2b"
					profile = face.get_minecraft_profile uuid
					
					expect(profile["id"]).to eq uuid
					expect(profile["name"]).to eq "KrisJelbring"
					expect(profile["properties"]).to be_present

					expect(profile["properties"].first["name"]).to eq "textures"
					expect(profile["properties"].first["value"]).to be_present
					expect(profile["properties"].first["value"]["profileId"]).to eq uuid
					expect(profile["properties"].first["value"]["profileName"]).to eq "KrisJelbring"

					textures = profile["properties"].first["value"]["textures"]
					expect(textures).to be_present
					expect(textures["SKIN"]).to be_present
					expect(textures["SKIN"]["url"]).to be_present
					expect(textures["CAPE"]).to be_present
					expect(textures["CAPE"]["url"]).to be_present
				end
			end

			context "give non-existent uuid" do
				before do
					result = '{
						"path" : "/session/minecraft/profile/foo",
						"errorMessage" : "Not a valid UUID: foo"
					}'
					allow(face).to receive(:http_get).and_return(result)
				end

				it "raise GetProfileError" do
					expect{face.get_minecraft_profile "foo"}.to raise_error(Minetools::FaceTool::GetProfileError)
				end
			end

			context "give nothing" do
				it "raise ArgumentError" do
					expect{face.get_minecraft_profile}.to raise_error(ArgumentError)
				end
			end

			context "give argument which is not String" do
				it "raise ArgumentError" do
					expect{face.get_minecraft_profile -1}.to raise_error(ArgumentError)
				end
			end

			context "give empty String" do
				it "raise ArgumentError" do
					expect{face.get_minecraft_profile ""}.to raise_error(ArgumentError)
				end
			end

			context "give nil" do
				it "raise ArgumentError" do
					expect{face.get_minecraft_profile}.to raise_error(ArgumentError)
				end
			end
		end

		describe "get_skin_image_url()" do
			context "give correct uuid" do
				before do
					allow(face).to receive(:http_get).and_return(profile_api_response_sample)
				end

				it "returns correct url" do
					# This is uuid of KrisJelbring, he is developer of minecraft.
					uuid = "7125ba8b1c864508b92bb5c042ccfe2b"
					image_url = face.get_skin_image_url uuid
					expect(image_url).to eq "http://textures.minecraft.net/texture/b47b21bb3e7f79bdf2a5e8e041f7ff9e178dc15645f6449b8e55f906604c07f9"
				end
			end

			context "give none-existent uuid" do
				before do
					result = '{
						"path" : "/session/minecraft/profile/foo",
						"errorMessage" : "Not a valid UUID: foo"
					}'
					allow(face).to receive(:http_get).and_return(result)
				end

				it "raise GetProfileError" do
					expect{face.get_minecraft_profile "foo"}.to raise_error(Minetools::FaceTool::GetProfileError)
				end
			end

			context "give nothing" do
				it "raise ArgumentError" do
					expect{face.get_minecraft_profile}.to raise_error(ArgumentError)
				end
			end

			context "give argument which is not String" do
				it "raise ArgumentError" do
					expect{face.get_minecraft_profile -1}.to raise_error(ArgumentError)
				end
			end

			context "give empty String" do
				it "raise ArgumentError" do
					expect{face.get_minecraft_profile ""}.to raise_error(ArgumentError)
				end
			end

			context "give nil" do
				it "raise ArgumentError" do
					expect{face.get_minecraft_profile}.to raise_error(ArgumentError)
				end
			end

			# TODO: add case of GetSkinUrlError
		end

		describe "get_face_image()" do
			before do
				allow(face).to receive(:get_image_from).and_return(skin_image_fixture)
			end

			context "give correct arguments" do
				it "returns image" do
					url = "http://textures.minecraft.net/texture/b47b21bb3e7f79bdf2a5e8e041f7ff9e178dc15645f6449b8e55f906604c07f9"
					expect(face.get_face_image(url).class).to eq Magick::Image
				end
			end

			context "give bad value to skin_image_url" do
				context "give nothing" do
					it "raise ArgumentError" do
						expect{face.get_face_image}.to raise_error ArgumentError
					end
				end

				context "give value which is not String" do
					it "raise ArgumentError" do
						expect{face.get_face_image -1}.to raise_error ArgumentError
					end
				end

				context "give empty String" do
					it "raise ArgumentError" do
						expect{face.get_face_image ""}.to raise_error ArgumentError
					end
				end

				context "give nil" do
					it "raise ArgumentError" do
						expect{face.get_face_image nil}.to raise_error ArgumentError
					end
				end
			end

			context "give bad value to size" do
				context "give value which is not Integer" do
					it "raise ArgumentError" do
						url = "http://textures.minecraft.net/texture/b47b21bb3e7f79bdf2a5e8e041f7ff9e178dc15645f6449b8e55f906604c07f9"
						expect{face.get_face_image url, "string"}.to raise_error ArgumentError
					end
				end

				context "give value which is not multiple of 8" do
					it "raise ArgumentError" do
						url = "http://textures.minecraft.net/texture/b47b21bb3e7f79bdf2a5e8e041f7ff9e178dc15645f6449b8e55f906604c07f9"
						expect{face.get_face_image url, 11}.to raise_error ArgumentError
					end
				end

				context "give minus value" do
					it "raise ArgumentError" do
						url = "http://textures.minecraft.net/texture/b47b21bb3e7f79bdf2a5e8e041f7ff9e178dc15645f6449b8e55f906604c07f9"
						expect{face.get_face_image url, -1}.to raise_error ArgumentError
					end
				end

				context "give nil" do
					it "raise ArgumentError" do
						url = "http://textures.minecraft.net/texture/b47b21bb3e7f79bdf2a5e8e041f7ff9e178dc15645f6449b8e55f906604c07f9"
						expect{face.get_face_image url, nil}.to raise_error ArgumentError
					end
				end
			end
		end

		describe "request!()" do
			context "set name to instance correctly" do
				let(:face) { described_class.new name: "KrisJelbring" }
				before do
					allow(face).to receive(:get_image_from).and_return(skin_image_fixture)
					allow(face).to receive(:http_get).and_return(
						uuid_api_response_sample,
						profile_api_response_sample
					)
				end

				it "set some instance variables" do
					face.request!
					expect(face.uuid).to be_present
					expect(face.skin_image_url).to be_present
					expect(face.image).to be_present
				end

				it "not raise errors" do
					expect{face.request!}.not_to raise_error
				end

				it "returns nil" do
					expect(face.request!).to eq nil
				end
			end

			context "not set name to instance" do
				before do
				end

				it "raise FaceRequestError" do
					face = described_class.new logger: logger_mock
					expect{face.request!}.to raise_error Minetools::FaceTool::FaceRequestError
				end
			end
		end
	end

	describe "instance variables" do
		it "default values" do
			expect(face.name).to eq nil
			expect(face.uuid).to eq nil
			expect(face.skin_image_url).to eq nil
			expect(face.image).to eq nil
			expect(face.size).to eq 512
		end
	end

	describe "error class" do
		describe "GetUUIDError" do
			it "raise GetUUIDError" do
				expect{
					raise Minetools::FaceTool::GetUUIDError
				}.to raise_error(Minetools::FaceTool::GetUUIDError)
			end
		end

		describe "GetProfileError" do
			it "raise GetProfileError" do
				expect{
					raise Minetools::FaceTool::GetProfileError
				}.to raise_error(Minetools::FaceTool::GetProfileError)
			end
		end

		describe "GetSkinUrlError" do
			it "raise GetSkinUrlError" do
				expect{
					raise Minetools::FaceTool::GetSkinUrlError
				}.to raise_error(Minetools::FaceTool::GetSkinUrlError)
			end
		end

		describe "FaceRequestError" do
			it "raise FaceRequestError" do
				expect{
					raise Minetools::FaceTool::FaceRequestError
				}.to raise_error(Minetools::FaceTool::FaceRequestError)
			end
		end

		describe "APIRequestError" do
			it "raise APIRequestError" do
				expect{
					raise Minetools::FaceTool::APIRequestError
				}.to raise_error(Minetools::FaceTool::APIRequestError)
			end
		end
		# TODO: check message of Errors
	end
end
