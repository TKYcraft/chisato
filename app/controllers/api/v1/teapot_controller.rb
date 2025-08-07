class Api::V1::TeapotController < ApplicationController
  rescue_from(Exception) { render head: 503 }

  def index
    expires_now
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.headers["Cache-Control"]).to include("must-revalidate")
    render status: 418, json: {message: "I m a teapot.", status: 418}
  end
end
