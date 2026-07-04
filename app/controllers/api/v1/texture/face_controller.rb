class Api::V1::Texture::FaceController < ApplicationController
	before_action :set_cache_control_header

	def show
		@status = 200
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

		begin
			@image_bin = request_face_image_of(params[:id], @size).to_blob
		rescue => e
			@image_bin = steve_face_image.to_blob
			@status = 404
		end

		send_data @image_bin, type: "image/png", disposition: 'inline', status: @status
	end

	private def request_face_image_of _name, _size
		face = Minetools::FaceTool::Face.new name: _name, size: _size
		face.request!
		return face.image
	end

	private def steve_face_image
		@face = Minetools::FaceTool::Face.new size: @size
		return @face.get_face_image(Rails.root.join("app", "assets", "images", "steve.png").to_s)
	end

	private def params_size
		return 512 if params[:size].nil?   # default
		return false if /^[0-9]{1,4}$/.match(params[:size]).nil?
		@s = params[:size].to_i
		return 8 <= @s && @s <= 2048 && @s%8==0 ? @s : false
	end

	private def use_cache?
		param = params[:cache]
		return true if param.nil?
		return false if param.downcase == "no"
		return true
	end

	private def set_cache_control_header
		if use_cache?
			response.headers['Cache-Control'] = 'public, max-age=10, s-max-age=3600'
		else
			expires_now
		end
	end
end
