require 'rails_helper'

RSpec.describe "GET static contents", type: :request do
	describe "./public/favicon.ico" do
		it "returns status success" do
			get "/favicon.ico"
			expect(response).to have_http_status 200
		end		
	end

	describe "./public/index.html" do
		it "returns status success with /" do
			get "/"
			expect(response).to have_http_status 200
		end

		it "returns status success with /index.html" do
			get "/index.html"
			expect(response).to have_http_status 200
		end
	end

	describe "./public/robots.txt" do
		it "returns status success" do
			get "/robots.txt"
			expect(response).to have_http_status 200
		end
	end
end