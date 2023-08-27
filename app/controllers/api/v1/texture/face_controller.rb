class Api::V1::Texture::FaceController < ApplicationController
	def show
		@face = Mineface::Face.new name: params[:id]
		begin
			@face.request!
			@image_bin = @face.image.to_blob
		rescue => e
			warn "[WARNING]: #{e.message}"
			@image_bin = steve_face_image.to_blob
		end
		send_data @image_bin, type: "image/png", disposition: 'inline'
	end

	private def steve_face_image
		@face = Mineface::Face.new
		return @face.get_face_image(Rails.root.join('public', "steve.png").to_s)
	end
end
