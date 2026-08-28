require 'rails_helper'

RSpec.describe "Api::V1::Teapot", type: :request do
	describe 'index' do
		it "returns http success" do
			get api_v1_teapot_index_path
			expect(response).to have_http_status(418)
			expect(response.headers["Access-Control-Allow-Origin"]).to eq "*"
		end

		it "returns Cache-Control header including no-cache, no-store, must-revalidate" do
			get api_v1_teapot_index_path
			expect(response.headers["Cache-Control"]).to include("no-cache")
			expect(response.headers["Cache-Control"]).to include("no-store")
			expect(response.headers["Cache-Control"]).to include("must-revalidate")
		end

		it "returns response body" do
			get api_v1_teapot_index_path
			json = JSON.parse(response.body)
			expect(json["message"]).to eq "I'm a teapot."
			expect(json["status"]).to eq 418
		end
	end
end
