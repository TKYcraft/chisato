require 'rails_helper'

RSpec.describe "Api::V1::Texture::Faces", type: :request do
	let(:mine_tools_face_mock){ instance_spy(Minetools::FaceTool::Face) }
	let(:skin_image_fixture){ Magick::Image.read('./spec/fixtures/skin_image_fixture.png').first }

	before do
		allow(Minetools::FaceTool::Face).to receive(:new).and_return(mine_tools_face_mock)
		allow(mine_tools_face_mock).to receive(:request!).and_raise RuntimeError
		allow(mine_tools_face_mock).to receive(:image).and_raise RuntimeError
		allow(mine_tools_face_mock).to receive(:get_face_image).and_raise RuntimeError
	end

	describe "show action" do
		context "give name of exist user to params" do
			before do
				allow(mine_tools_face_mock).to receive(:request!).and_return(nil)
				allow(mine_tools_face_mock).to receive(:image).and_return(skin_image_fixture)
			end

			fit "success 200" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png"

				# Assert
				expect(response).to have_http_status 200
				expect(response.headers["Content-Type"]).to eq "image/png"

				expect(response.headers["Access-Control-Allow-Origin"]).to eq "*"
				expect(response.headers["Cache-Control"]).to include "max-age=3600"
				expect(response.headers["Cache-Control"]).to include "public"
			end

			it "success 200 with correct size params" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 256}

				# Assert
				expect(response).to have_http_status 200
				expect(response.headers["Content-Type"]).to eq "image/png"
			end
		end

		context "give cache parameter" do
			before do
				allow(mine_tools_face_mock).to receive(:request!).and_return(nil)
				allow(mine_tools_face_mock).to receive(:image).and_return(skin_image_fixture)
			end

			it "returns 200 with no-cache when giving cache=no" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {cache: "no"}

				# Assert
				expect(response).to have_http_status 200
				expect(response.headers["Cache-Control"]).to include "no-cache"
			end

			it "returns public when giving cache=yes" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {cache: "yes"}

				# Assert
				expect(response).to have_http_status 200
				expect(response.headers["Cache-Control"]).to include "public"
			end

			it "returns public when giving cache=false" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {cache: "false"}

				# Assert
				expect(response).to have_http_status 200
				expect(response.headers["Cache-Control"]).to include "public"
			end

			it "returns public when giving cache=0" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {cache: "0"}

				# Assert
				expect(response).to have_http_status 200
				expect(response.headers["Cache-Control"]).to include "public"
			end
		end

		context "give name of none-exist user to params" do
			before do
				allow(mine_tools_face_mock).to receive(:request!).and_raise Minetools::FaceTool::GetUUIDError
				allow(mine_tools_face_mock).to receive(:get_face_image).and_return skin_image_fixture
			end

			it "not found 404" do
				# Act
				get api_v1_texture_face_path("0.png")

				# Assert
				expect(response).to have_http_status 404
				expect(response.headers["Content-Type"]).to eq "image/png"
			end
		end

		context "request with INCORRECT file extention" do
			it "returns bad request 400" do
				# Act
				get api_v1_texture_face_path("KrisJelbring.PNG")

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				expect(json["message"]).to eq "file extention must be .png"
			end
		end

		context "request without file extention" do
			it "returns bad request 400" do
				# Act
				get api_v1_texture_face_path("KrisJelbring")

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				expect(json["message"]).to eq "file extention must be .png"
			end
		end

		context "request with correct size parameter" do
			before do
				allow(mine_tools_face_mock).to receive(:request!).and_return(nil)
				allow(mine_tools_face_mock).to receive(:image).and_return(skin_image_fixture)
			end

			it "returns success with size: 8" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 8}

				# Assert
				expect(response).to have_http_status 200
			end

			it "returns success with size: 512" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 512}

				# Assert
				expect(response).to have_http_status 200
			end

			it "returns success with size: 2048" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 2048}

				# Assert
				expect(response).to have_http_status 200
			end

			it "returns success with size: nil" do
				# Act on this pattern will get `/api/v1/texture/face/KrisJelbring.png?size`
				get api_v1_texture_face_path "KrisJelbring.png", {size: nil}

				# Assert
				expect(response).to have_http_status 200
			end
		end

		context "request with INCORRECT size parameter" do
			it "returns bad request 400 with size: -8" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: -8}

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				expect(json["message"]).to eq "parameter size must be Integer (8 ~ size ~ 2048) and multiple of 8"
			end

			it "returns bad request 400 with size: -1" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: -1}

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				expect(json["message"]).to eq "parameter size must be Integer (8 ~ size ~ 2048) and multiple of 8"
			end

			it "returns bad request 400 with size: 0" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 0}

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				expect(json["message"]).to eq "parameter size must be Integer (8 ~ size ~ 2048) and multiple of 8"
			end

			it "returns bad request 400 with size: 1" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 1}

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				expect(json["message"]).to eq "parameter size must be Integer (8 ~ size ~ 2048) and multiple of 8"
			end

			it "returns bad request 400 with size: 7" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 7}

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				expect(json["message"]).to eq "parameter size must be Integer (8 ~ size ~ 2048) and multiple of 8"
			end

			it "returns bad request 400 with size: 2049" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 2049}

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				expect(json["message"]).to eq "parameter size must be Integer (8 ~ size ~ 2048) and multiple of 8"
			end

			it "returns bad request 400 with size: 2056" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 2056}

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				expect(json["message"]).to eq "parameter size must be Integer (8 ~ size ~ 2048) and multiple of 8"
			end

			it "returns bad request 400 with size: false" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: false}

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				expect(json["message"]).to eq "parameter size must be Integer (8 ~ size ~ 2048) and multiple of 8"
			end

			it "returns bad request 400 with size: true" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: true}

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				expect(json["message"]).to eq "parameter size must be Integer (8 ~ size ~ 2048) and multiple of 8"
			end

			it "returns bad request 400 with size: 'string'" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 'string'}

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				expect(json["message"]).to eq "parameter size must be Integer (8 ~ size ~ 2048) and multiple of 8"
			end
		end

		context "response headers" do
			before do
				allow(mine_tools_face_mock).to receive(:request!).and_return(nil)
				allow(mine_tools_face_mock).to receive(:image).and_return(skin_image_fixture)
			end

			it "have correct cache-control" do
				# Act
				get api_v1_texture_face_path("KrisJelbring.png")

				# Assert
				expect(response.headers).to be_present
				expect(response.headers["Content-Type"]).to eq "image/png"
				expect(response.headers["Cache-Control"]).to include("public")
				expect(response.headers["Cache-Control"]).to include("max-age=3600")
			end
		end
	end
end
