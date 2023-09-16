require 'rails_helper'

RSpec.describe "Api::V1::Texture::Faces", type: :request do
	describe "show action" do
		context "give name of exist user to params" do
			it "success 200" do
				# Act
				get api_v1_texture_face_path("KrisJelbring.png")

				# Assert
				expect(response).to have_http_status 200
			end
		end

		context "give name of none-exist user to params" do
			it "success 200" do
				# Act
				get api_v1_texture_face_path("0.png")

				# Assert
				expect(response).to have_http_status 200
			end
		end

		context "request with INCORRECT file extention" do
			it "returns bad request 400" do
				# Act
				get api_v1_texture_face_path("KrisJelbring.PNG")

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				
				expect(json["status"]).to eq 400
				expect(json["status_message"]).to eq "Bad Request"
				expect(json["data"]).to eq({})
				expect(json["messages"]).to eq ["file extention must be '.png'"]
			end
		end

		context "request without file extention" do
			it "returns bad request 400" do
				# Act
				get api_v1_texture_face_path("KrisJelbring")

				# Assert
				json = JSON.parse(response.body)
				expect(response).to have_http_status 400
				
				expect(json["status"]).to eq 400
				expect(json["status_message"]).to eq "Bad Request"
				expect(json["data"]).to eq({})
				expect(json["messages"]).to eq ["file extention must be '.png'"]
			end
		end

		context "response headers" do
			it "have correct cache-control" do
				# Act
				get api_v1_texture_face_path("KrisJelbring.png")

				# Assert
				expect(response.headers).to be_present
				expect(response.headers["Cache-Control"]).to include("public")
				expect(response.headers["Cache-Control"]).to include("max-age=3600")
			end
		end
	end
end
