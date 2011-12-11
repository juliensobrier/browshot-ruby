# The library requires an API key from Browshot.
# Sign up fpr a free account a http://browshot.com/
# 
# See README.rdoc for more information abouth Browshot
# and this library.
#
# Author::    Julien Sobrier  (mailto:jsobrier@browshot.com)
# Copyright:: Copyright (c) 2011 Browshot
# License::   Distributes under the same terms as Ruby

require 'url'
require 'json'
require 'net/http'
require 'net/https'

class Browshot
	# API key
	attr_reader :key
	# Base URL for all API requests. You should use the default base provided by the library. Be careful if you decide to use HTTP instead of HTTPS as your API key could be sniffed and your account could be used without your consent.
	attr_reader :base
	# print debug output to the standard output
	attr_reader :debug

	# New client
	# 
	# +key+:: API key
	# +base+:: Base URL for all API requests. You should use the default base provided by the library. Be careful if you decide to use HTTP instead of HTTPS as your API key could be sniffed and your account could be used without your consent.
	# +debug+:: Set to true to print debug output to the standard output. false (disabled) by default.
	def initialize(key='', base='https://api.browshot.com/api/v1/', debug=false)
		@key = key || ''
		@base = base || 'http://127.0.0.1:3000/api/v1/'
		@debug = debug || false
	end

	# Return the API version handled by the library. Note that this library can usually handle new arguments in requests without requiring an update.
	def api_version()
		return "1.3"
	end

	# Return the list of instances. See http://browshot.com/api/documentation#instance_list for the response format.
	def instance_list()
		return return_reply('instance/list')
	end

	# Return the details of an instance. See http://browshot.com/api/documentation#instance_info for the response format.
	#
	# +id+:: Instance ID
	def instance_info(id=0)
		return return_reply('instance/info', { 'id' => id })
	end

	# Create a private instance. See http://browshot.com/api/documentation#instance_create for the response format.
	def instance_create(parameters={})
		return return_reply('instance/create', parameters)
	end

	# Return the list of browsers. See http://browshot.com/api/documentation#browser_list for the response format.
	def browser_list()
		return return_reply('browser/list')
	end

	# Return the details of a browser. See http://browshot.com/api/documentation#browser_info for the response format.
	#
	# +id+:: Browser ID
	def browser_info(id=0)
		return return_reply('browser/info', { 'id' => id })
	end

	# Create a custom browser. See http://browshot.com/api/documentation#browser_create for the response format.
	def browser_create(parameters={})
		return return_reply('browser/create', parameters)
	end

	# Request a screenshot. See http://browshot.com/api/documentation#screenshot_create for the response format.
	#
	# +url+:: URL of the website to create a screenshot of.
	def screenshot_create(url='', parameters={})
		parameters[:url] = url
		return return_reply('screenshot/create', parameters)
	end

	# Get information about a screenshot requested previously. See http://browshot.com/api/documentation#screenshot_info for the response format.
	#
	# +id+:: screenshot ID
	def screenshot_info(id=0)
		return return_reply('screenshot/info', { 'id' => id })
	end

	# Get details about screenshots requested. See http://browshot.com/api/documentation#screenshot_list for the response format.
	def screenshot_list(parameters={})
		return return_reply('screenshot/list', parameters)
	end

	# Retrieve the screenshot, or a thumbnail. See http://browshot.com/api/documentation#thumbnails for the response format.
	#
	# Return an empty string if the image could not be retrieved.
	# +id+:: screenshot ID
	def screenshot_thumbnail(url='', parameters={})
		begin
			url =  URL.new(url)

			parameters.each_pair do |key, value|
				url.params[key] = value
			end
			
			puts "#{url}" if (@debug)


			response = url.get

			if (response.success?)
				return response.response.body
			else
				puts "Error from #{url}: #{response.code}" if (@debug)
				return ''
			end
		rescue Exception => e
			puts "{e.message}" if (@debug)
			raise e
		end
	end

	# Retrieve the screenshot, or a thumbnail, and save it to a file. See http://browshot.com/api/documentation#thumbnails for the response format.
	#
	# See http://browshot.com/api/documentation#thumbnails for the full list of possible arguments.
	# 
	# +url+:: URL of the screenshot (screenshot_url value retrieved from screenshot_create() or screenshot_info()). You will get the full image if no other argument is specified.
	# +file+:  Local file name to write to.
	def screenshot_thumbnail_file(url='', file='', parameters={})
		content = screenshot_thumbnail(url, parameters);

		if ($content != '')
			File.open(file, 'w') {|f| f.write(content) }
			return file
		else
			puts "No thumbnail retrieved\n" if (@debug)
			return ''
		end
	end

	#  Return information about the user account. See http://browshot.com/api/documentation#account_info for the response format.
	def account_info(parameters={})
		return return_reply('account/info', parameters)
	end

	private

	def make_url(action='', parameters={})
		url =  URL.new("#{@base}#{action}?key=#{@key}")
		
		
		parameters.each_pair do |key, value|
			url.params[key] = value
		end

		puts "#{url}" if (@debug)

		return url
	end
		
	def return_reply(action='', parameters={})
		begin
			url	= make_url(action, parameters)
			
			response = url.get

			if (response.success?)
				json_decode = JSON.parse(response.response.body)
				return json_decode
			else
				puts "Error from #{url}: #{response.code}" if (@debug)
				return { 'error' => 1, 'message' => response.code }
			end
		rescue Exception => e
			puts "{e.message}" if (@debug)
			raise e
		end
	end
end