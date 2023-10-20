require 'rails_helper'

RSpec.describe "Api::V1::Texture::Faces", type: :request do
	describe "show action" do
		context "give name of exist user to params" do
			it "success 200" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png"

				# Assert
				expect(response).to have_http_status 200
				expect(response.headers["Content-Type"]).to eq "image/png"
				expect(response.headers["Access-Control-Allow-Origin"]).to eq "*"
			end

			it "success 200 with correct size params" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 256}

				# Assert
				expect(response).to have_http_status 200
				expect(response.headers["Content-Type"]).to eq "image/png"
			end
		end

		context "give name of none-exist user to params" do
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
			it "returns success with size: 8" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 8}

				# Assert
				expect(response).to have_http_status 200
			end

			it "returns bad request 400 with size: 512" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 512}

				# Assert
				expect(response).to have_http_status 200
			end

			it "returns bad request 400 with size: 2048" do
				# Act
				get api_v1_texture_face_path "KrisJelbring.png", {size: 2048}

				# Assert
				expect(response).to have_http_status 200
			end

			it "returns bad request 400 with size: nil" do
				# Act on this pattern will get `/api/v1/texture/face/KrisJelbring.png.png?size`
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
