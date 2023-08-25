module Mineface
	require 'net/http'
	require 'uri'
	require "json"
	require 'base64'

	class Face
		attr_reader :name, :uuid, :skin_image_url, :size, :image
		def initialize options={name: nil, size: 512}
			@name = options[:name]
			@size = options[:size]
			@skin_image_url = nil
			@uuid = nil
			@image = nil
		end

		def request!
			raise FaceRequestError if @name.nil?
			@uuid = get_minecraft_uuid(@name)
			@skin_image_url = get_skin_image_url(@uuid)
			@image = get_face_image(@skin_image_url)
			return
		end

		def get_minecraft_uuid name=""
			raise ArgumentError unless name.kind_of? String
			raise ArgumentError if name == ""

			_json = request_json("https://api.mojang.com/users/profiles/minecraft/#{name}")
			raise GetUUIDError, "this user name is not exist." unless _json["errorMessage"].nil?
			# TODO: include API errorMessage to Exception message.

			return _json["id"]
		end

		def get_minecraft_profile uuid=""
			raise ArgumentError unless uuid.kind_of? String
			raise ArgumentError if uuid == ""
			
			_json = request_json("https://sessionserver.mojang.com/session/minecraft/profile/#{uuid}")
			raise GetProfileError, "this uuid is invalid. #{_json["errorMessage"]}" unless _json["errorMessage"].nil?

			_json_str = Base64.decode64(_json["properties"].first["value"])
			begin
				_json["properties"].first["value"] = JSON.parse(_json_str)
				# TODO: check case of including element"s" on _json["properties"] .
			rescue JSON::ParserError => e
				raise GetProfileError, e.message
			rescue => e
				warn e.message
				raise GetProfileError, e.message
			end
			return _json
		end

		def get_skin_image_url uuid=""
			raise ArgumentError unless uuid.kind_of? String
			raise ArgumentError if uuid == ""

			_json = get_minecraft_profile uuid
			_url = _json.try(:[], "properties")
				.try(:first)
				.try(:[], "value")
				.try(:[], "textures")
				.try(:[], "SKIN")
				.try(:[], "url")
			raise GetSkinUrlError, "there is no skin url." if _url.nil?
			return _url
		end

		def get_face_image skin_image_url="", size=512
			raise ArgumentError unless skin_image_url.kind_of? String
			raise ArgumentError if skin_image_url == ""
			raise ArgumentError unless size.kind_of? Integer
			raise ArgumentError unless size%8==0

			image = Magick::Image.read(skin_image_url).first

			_face = image.crop(8,8,8,8)   # crop face area.
			_face.sample!(size,size)   # resize image.
			_ornaments = image.crop(40,8,8,8)   # crop ornaments area.
			_ornaments.sample!(size,size)
			_face.composite!(_ornaments, 0, 0, Magick::OverCompositeOp)

			return _face   # => Magick::Image
		end

		def request_json _url=""
			raise ArgumentError unless _url.kind_of? String
			raise ArgumentError if _url == ""

			parsed_uri = URI.parse(_url)

			begin
				data = Net::HTTP.get(parsed_uri)
			rescue SocketError=> e
				raise APIRequestError, e.message
			rescue => e
				warn e.message
				raise APIRequestError, e.message
			end

			begin
				json = JSON.parse(data)
			rescue JSON::ParserError => e
				raise APIRequestError, e.message
			rescue => e
				warn e.message
				raise APIRequestError, e.message
			end

			return json
		end
	end

	class GetUUIDError < StandardError
		def initialize msg="Can't get UUID."
			super msg
		end
	end

	class GetProfileError < StandardError
		def initialize msg="Can't get Profile."
			super msg
		end
	end

	class GetSkinUrlError < StandardError
		def initialize msg="Can't get Profile."
			super msg
		end
	end

	class FaceRequestError < StandardError
		def initialize msg="Can't request face image."
			super msg
		end
	end

	class APIRequestError < StandardError
		def initialize msg="Doesn't success request."
			super msg
		end
	end
end
