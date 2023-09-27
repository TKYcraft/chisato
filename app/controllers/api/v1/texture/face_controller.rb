class Api::V1::Texture::FaceController < ApplicationController
	def show
		@path = URI.parse(request.fullpath).path
		unless File.extname(@path) == ".png"
			render json: {message: "file extention must be .png"}, status: 400
			return nil
		end

		@size = params_size
		unless @size
			render json: {message: "parameter size must be Integer (8 ~ size ~ 2048) and multiple of 8"}, status: 400
			return nil
		end

		@face = Minetools::FaceTool::Face.new name: params[:id], size: @size
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
		@face = Minetools::FaceTool::Face.new size: @size
		return @face.get_face_image(Rails.root.join('public', "steve.png").to_s)
	end

	private def params_size
		return 512 if params[:size].nil?   # default
		return false if /^[0-9]{1,4}$/.match(params[:size]).nil?
		@s = params[:size].to_i
		return 8 <= @s && @s <= 2048 && @s%8==0 ? @s : false
	end
end
