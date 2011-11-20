require 'url'
require 'json'
require 'net/http'
require 'net/https'

class Browshot
	attr_reader :key, :base, :debug

	def initialize(key='', base='https://api.browshot.com/api/v1/', debug=0)
		@key = key || ''
		@base = base || 'http://127.0.0.1:3000/api/v1/'
		@debug = debug || 0
	end

	def api_version()
		return "1.2"
	end

	def instance_list()
		return return_reply('instance/list')
	end

	def instance_info(id=0)
		return return_reply('instance/info', { 'id' => id })
	end

	def instance_create(parameters={})
		return return_reply('instance/create', parameters)
	end


	def browser_list()
		return return_reply('browser/list')
	end

	def browser_info(id=0)
		return return_reply('browser/info', { 'id' => id })
	end

	def browser_create(parameters={})
		return return_reply('browser/create', parameters)
	end


	def screenshot_create(url='', parameters={})
		parameters[:url] = url
		return return_reply('screenshot/create', parameters)
	end

	def screenshot_info(id=0)
		return return_reply('screenshot/info', { 'id' => id })
	end

	def screenshot_list(parameters={})
		return return_reply('screenshot/list', parameters)
	end

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

	def account_info(parameters={})
		return return_reply('account/info', parameters)
	end

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