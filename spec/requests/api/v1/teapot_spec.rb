require 'rails_helper'

RSpec.describe "Api::V1::Teapot", type: :request do
	describe 'index' do
		it "returns http success" do
			get api_v1_teapot_index_path
			expect(response).to have_http_status(418)
			expect(response.headers["Access-Control-Allow-Origin"]).to eq "*"
		end

		it "returns Cache-Control header including public, s-max-age, max-age" do
			get api_v1_teapot_index_path
			expect(response.headers["Cache-Control"]).to include("public")
			expect(response.headers["Cache-Control"]).to include("s-max-age=3600")
			expect(response.headers["Cache-Control"]).to include("max-age=10")
		end

		it "returns response body" do
			get api_v1_teapot_index_path
			json = JSON.parse(response.body)
			expect(json["message"]).to eq "I m a teapot."
			expect(json["status"]).to eq 418
		end
	end
end
