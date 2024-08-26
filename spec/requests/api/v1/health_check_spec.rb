require 'rails_helper'

RSpec.describe "Api::V1::HealthCheck", type: :request do
	describe 'index' do
		it "returns http success" do
			get api_v1_health_check_index_path
			expect(response).to have_http_status(200)
			expect(response.headers["Access-Control-Allow-Origin"]).to eq "*"
		end

		it "returns Cache-Control header including no-store" do
			get api_v1_health_check_index_path
			expect(response.headers["Cache-Control"]).to include "no-store"
		end
	end
end
