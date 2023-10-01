class Api::V1::Texture::FaceController < ApplicationController
	def show
		@status = 200
		unless File.extname(request.fullpath) == ".png"
			render json: {message: "file extention must be .png"}, status: 400
			return nil
		end

		@face = Minetools::FaceTool::Face.new name: params[:id]
		begin
			@face.request!
			@image_bin = @face.image.to_blob
		rescue => e
			warn "[WARNING]: #{e.message}"
			@image_bin = steve_face_image.to_blob
			@status = 404
		end

		expires_in 1.hours, public: true   # cache-control header.
		send_data @image_bin, type: "image/png", disposition: 'inline', status: @status
	end

	private def steve_face_image
		@face = Minetools::FaceTool::Face.new
		return @face.get_face_image(Rails.root.join("app", "assets", "images", "steve.png").to_s)
	end
end
