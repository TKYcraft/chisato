class Api::V1::TeapotController < ApplicationController
  rescue_from(Exception) { render head: 503 }

  def index
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    render status: 418, json: {message: "I m a teapot.", status: 418}
  end
end
