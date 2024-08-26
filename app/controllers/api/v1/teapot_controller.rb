class Api::V1::TeapotController < ApplicationController
  rescue_from(Exception) { render head: 503 }

  def index
    expires_in 1.hours, public: true
    render status: 418, json: {message: "I m a teapot.", status: 418}
  end
end
