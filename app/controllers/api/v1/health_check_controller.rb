class Api::V1::HealthCheckController < ApplicationController
  rescue_from(Exception) { render head: 503 }

  def index
    no_store   # disable cache.
    render status: 200, json: {message: "ok", status: 200}
  end
end
