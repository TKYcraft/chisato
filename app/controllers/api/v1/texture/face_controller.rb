class Api::V1::Texture::FaceController < ApplicationController
	def show
		unless File.extname(request.fullpath) == ".png"
			render_status 400, {}, ["file extention must be '.png'"]
			return nil
		end

		@face = Mineface::Face.new name: params[:id]
		begin
			@face.request!
			@image_bin = @face.image.to_blob
		rescue => e
			warn "[WARNING]: #{e.message}"
			@image_bin = steve_face_image.to_blob
		end

		expires_in 1.hours, public: true   # cache-control header.
		send_data @image_bin, type: "image/png", disposition: 'inline'
	end

	private def steve_face_image
		@face = Mineface::Face.new
		return @face.get_face_image(Rails.root.join('public', "steve.png").to_s)
	end
end
