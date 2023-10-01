require 'rails_helper'

RSpec.describe "GET static contents", type: :request do
	describe "./public/favicon.ico" do
		it "returns status success" do
			get "/favicon.ico"
			expect(response).to have_http_status 200
		end		
	end
end