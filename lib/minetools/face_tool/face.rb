module Minetools
	module FaceTool
		require 'net/http'
		require 'uri'
		require "json"
		require 'base64'
		require "logger"

		class Face
			attr_reader :name, :uuid, :skin_image_url, :size, :image
			def initialize options={name: nil, size: nil, logger: nil}
				@name = options[:name]
				@size = options[:size]
				@size = 512 if @size.nil?   # set default
				@logger = options[:logger] || Logger.new($stdout)
				@skin_image_url = nil
				@uuid = nil
				@image = nil
			end

			def request!
				if @name.nil?
					msg = "Face at #{__LINE__}, Not given name."
					@logger.error(msg)
					raise FaceRequestError, msg
				end

				@uuid = get_minecraft_uuid(@name)
				@skin_image_url = get_skin_image_url(@uuid)
				@image = get_face_image(@skin_image_url, @size)
				return
			end

			def get_minecraft_uuid name=""
				raise ArgumentError unless name.kind_of? String
				raise ArgumentError if name == ""

				_json = request_json("https://api.mojang.com/users/profiles/minecraft/#{name}")

				unless _json["errorMessage"].nil?
					msg = "Face at #{__LINE__}, This User name is not exist. #{_json["errorMessage"]}."
					@logger.error(msg)
					raise GetUUIDError, msg
				end

				return _json["id"]
			end

			def get_minecraft_profile uuid=""
				raise ArgumentError unless uuid.kind_of? String
				raise ArgumentError if uuid == ""
				
				_json = request_json("https://sessionserver.mojang.com/session/minecraft/profile/#{uuid}")

				unless _json["errorMessage"].nil?
					msg = "Face at #{__LINE__}, This uuid is invalid. #{_json["errorMessage"]}."
					@logger.error(msg)
					raise GetProfileError, msg
				end

				_json_str = Base64.decode64(_json["properties"].first["value"])
				begin
					_json["properties"].first["value"] = JSON.parse(_json_str)
					# TODO: check case of including element"s" on _json["properties"] .
				rescue JSON::ParserError => e
					msg = "Face at #{__LINE__}, JSON::ParserError: #{e.message}."
					@logger.error(msg)
					raise GetProfileError, msg
				rescue => e
					msg = "Face at #{__LINE__}, Unexpected #{e.to_s}: #{e.message}."
					@logger.error(msg)
					raise GetProfileError, msg
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

				if _url.nil?
					msg = "Face at #{__LINE__}, There is no skin url."
					@logger.error(msg)
					raise GetSkinUrlError, msg
				end
				return _url
			end

			def get_face_image skin_image_url="", size=512
				raise ArgumentError unless skin_image_url.kind_of? String
				raise ArgumentError if skin_image_url == ""
				raise ArgumentError unless size.kind_of? Integer
				raise ArgumentError unless size%8==0
				raise ArgumentError unless 8 <= size

				image = get_image_from(skin_image_url)

				_face = image.crop(8,8,8,8)   # crop face area.
				_face.sample!(size,size)   # resize image.
				_ornaments = image.crop(40,8,8,8)   # crop ornaments area.
				_ornaments.sample!(size,size)
				_face.composite!(_ornaments, 0, 0, Magick::OverCompositeOp)

				return _face   # => Magick::Image
			end

			def get_image_from(_url)
				Magick::Image.read(_url).first
			end

			def request_json _url=""
				raise ArgumentError unless _url.kind_of? String
				raise ArgumentError if _url == ""

				parsed_uri = URI.parse(_url)

				begin
					data = http_get(parsed_uri)
				rescue SocketError=> e
					msg = "Face at #{__LINE__}, SocketError: #{e.message}"
					@logger.error(msg)
					raise APIRequestError, msg
				rescue => e
					msg = "Face at #{__LINE__}, Unexpected #{e.to_s}: #{e.message}"
					@logger.error(msg)
					raise APIRequestError, msg
				end

				begin
					json = JSON.parse(data)
				rescue JSON::ParserError => e
					msg = "Face at #{__LINE__}, JSON::ParserError: #{e.message}"
					@logger.error(msg)
					raise APIRequestError, msg
				rescue => e
					msg = "Face at #{__LINE__}, Unexpected #{e.to_s}: #{e.message}"
					@logger.error(msg)
					raise APIRequestError, msg
				end

				return json
			end

			def http_get(_parsed_uri)
				Net::HTTP.get(_parsed_uri)
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
end
