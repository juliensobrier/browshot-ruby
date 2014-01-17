# The library requires an API key from Browshot.
# Sign up for a free account a http://browshot.com/
# 
# See README.rdoc for more information abouth Browshot
# and this library.
#
# Author::    Julien Sobrier  (mailto:jsobrier@browshot.com)
# Copyright:: Copyright (c) 2013 Browshot
# License::   Distributes under the same terms as Ruby

require 'rubygems'
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
		return "1.14"
	end

    # Retrieve a screenshot with one call. See http://browshot.com/api/documentation#simple for the full list of possible arguments.
    #
    # Return {:code => 200, :png => <content>} in case of success
    def simple(parameters={})
        begin
            url = make_url('simple', parameters)
            response = fetch(url.to_s)
            case response
                when Net::HTTPSuccess     then 
                    return {:code => response.code, :png => response.response.body}
                else
                    return {:code => response.code, :png => ''}
            end
        rescue Exception => e
            puts "{e.message}" if (@debug)
            raise e
        end
    end

    # Save a screenshot to a file with one call, and save it to a file. See http://browshot.com/api/documentation#simple for the full list of possible arguments.
    #
    # Return {:code => 200, :file => <file_name>} in case of success
    #
    # +file+::  Local file name to write to.
    def simple_file(file='', parameters={})
        data = self.simple(parameters)
        if (data[:png].length > 0)
            File.open(file, 'w') {|f| f.write(data[:png]) }
            return {:code => data[:code], :file => file}
        else
            return {:code => data[:code], :file => ''}
        end
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
	def screenshot_info(id=0, parameters={})
		parameters[:id] = id
		return return_reply('screenshot/info', parameters)
	end

	# Get details about screenshots requested. See http://browshot.com/api/documentation#screenshot_list for the response format.
	def screenshot_list(parameters={})
		return return_reply('screenshot/list', parameters)
	end

	# Retrieve the screenshot, or a thumbnail. See http://browshot.com/api/documentation#screenshot_thumbnails for the response format.
	#
	# Return an empty string if the image could not be retrieved.
	# +id+:: screenshot ID
	def screenshot_thumbnail(id=0, parameters={})
		parameters[:id] = id

		begin
            url = make_url('screenshot/thumbnail', parameters)
            response = fetch(url.to_s)
            case response
                when Net::HTTPSuccess     then 
                    return response.response.body
                else
                    return ''
            end
        rescue Exception => e
            puts "{e.message}" if (@debug)
            raise e
        end
	end

	# Hot a screenshot or thumbnail. See http://browshot.com/api/documentation#screenshot_host for the response format.
	#
	# +id+:: screenshot ID
	# +hosting+:: hosting option: s3, cdn or browshot
	def screenshot_host(id=0, hosting='browshot', parameters={})
		parameters[:id] = id
		parameters[:hosting] = hosting
		return return_reply('screenshot/host', parameters)
	end

	# Share a screenshot. See http://browshot.com/api/documentation#screenshot_share for the response format.
	#
	# +id+:: screenshot ID
	def screenshot_share(id=0, parameters={})
		parameters[:id] = id
		return return_reply('screenshot/share', parameters)
	end

	# Delete details of a screenshot. See http://browshot.com/api/documentation#screenshot_delete for the response format.
	#
	# +id+:: screenshot ID
	def screenshot_delete(id=0, parameters={})
		parameters[:id] = id
		return return_reply('screenshot/delete', parameters)
	end
	
	# Get details about screenshots requested. See http://browshot.com/api/documentation#screenshot_search for the response format.
	#
	# +url+:: URL string to match
	def screenshot_search(url='', parameters={})
		parameters[:url] = url
		return return_reply('screenshot/search', parameters)
	end


	# Retrieve the screenshot, or a thumbnail, and save it to a file. See http://browshot.com/api/documentation#screenshot_thumbnails for the response format.
	#
	# See http://browshot.com/api/documentation#screenshot_thumbnails for the full list of possible arguments.
	# 
	# +id+:: screenshot ID
	# +file+::  Local file name to write to.
	def screenshot_thumbnail_file(id=0, file='', parameters={})
		content = screenshot_thumbnail(id, parameters);

		if (content != '')
			File.open(file, 'w') {|f| f.write(content) }
			return file
		else
			puts "No thumbnail retrieved\n" if (@debug)
			return ''
		end
	end
	
	
	# Get the HTML code of the rendered page. See http://browshot.com/api/documentation#screenshot_html for the response format.
	#
	# See http://browshot.com/api/documentation#screenshot_html for the full list of possible arguments.
	# 
	# +id+:: screenshot ID
	def screenshot_html(id=0, parameters={})
		parameters[:id] = id

		return return_string('screenshot/html', parameters)
	end
	
	
	# Request multiple screenshots. See http://browshot.com/api/documentation#screenshot_multiple for the response format.
	#
	# See http://browshot.com/api/documentation#screenshot_multiple for the full list of possible arguments.
	# 
	# +url+:: URL of the website to create a screenshot of
	def screenshot_multiple(url='', parameters={})
		parameters[:url] = url

		return return_reply('screenshot/multiple', parameters)
	end
	
	# Request multiple screenshots from a text file. See http://browshot.com/api/documentation#batch_create for the response format.
	#
	# See http://browshot.com/api/documentation#batch_create for the full list of possible arguments.
	# 
	# +id+:: Instance ID
	# +file+:: Path to the text file which contains the list of URLs
	def batch_create(id=0, file='', parameters={})
		parameters[:id] = id
		parameters[:file] = file

		return return_post_reply('batch/create', parameters)
	end
	
	# Get information about a screenshot batch requested previously. See http://browshot.com/api/documentation#batch_info for the response format.
	#
	# See http://browshot.com/api/documentation#batch_info for the full list of possible arguments.
	# 
	# +id+:: Batch ID
	def batch_info(id=0,  parameters={})
		parameters[:id] = id

		return return_reply('batch/info', parameters)
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
			content = return_string(action, parameters)

			json_decode = JSON.parse(content)
			return json_decode
		rescue Exception => e
			puts "{e.message}" if (@debug)
			raise e
		end
	end
	
	def return_post_reply(action='', parameters={})
		begin
			content = return_post_string(action, parameters)

			json_decode = JSON.parse(content)
			return json_decode
		rescue Exception => e
			puts "{e.message}" if (@debug)
			raise e
		end
	end
	    
	def return_string(action='', parameters={})
		begin
			url = make_url(action, parameters)
			
			response = url.get

			if (response.success? == false)
				puts "Error from #{url}: #{response.code}" if (@debug)
			end
			return response.response.body
		rescue Exception => e
			puts "{e.message}" if (@debug)
			raise e
		end
	end
	
	def return_post_string(action='', parameters={})
		begin
			file = parameters[:file]
			parameters.delete(:file)
			url = make_url(action, parameters)
			
			response = post(url.to_s,file)

			case response
			  when Net::HTTPSuccess     then 
			      return response.response.body
			  else
			      puts "Error from #{url}: #{response.code}" if (@debug)
			      return response.response.body
			end
		rescue Exception => e
			puts "{e.message}" if (@debug)
			raise e
		end
	end

	def fetch(url, limit=32)
	    raise ArgumentError, 'HTTP redirect too deep' if (limit == 0)

	    uri = URI.parse(url)
	    http = Net::HTTP.new(uri.host, uri.port)
	    http.open_timeout = 240
	    http.read_timeout = 240

	    request = Net::HTTP::Get.new(uri.request_uri, {'User-Agent' => 'Browshot Ruby 1.14'})
	    if (uri.scheme == 'https')
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	    end
	    response = http.request(request)

	    case response
		when Net::HTTPRedirection then 
		    path = response['location']
		    url = URL.new( URI.join(@base, path).to_s )
		    return fetch(url.to_s, limit - 1)
		else
		    return response
	    end
	end
	
	def post(url, file='')
	    raise ArgumentError, 'Missing file to upload' if (file == '')
	  
	    uri = URI.parse(url)
	    http = Net::HTTP.new(uri.host, uri.port)
	    http.open_timeout = 240
	    http.read_timeout = 240
	    
	    boundary = "AaB03x"
	    
	    post_body = []
	    post_body << "--#{boundary}\r\n"
	    post_body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{File.basename(file)}\"\r\n"
	    post_body << "Content-Type: text/plain\r\n"
	    post_body << "\r\n"
	    post_body << File.read(file)
	    post_body << "\r\n--#{boundary}--\r\n"

	    request = Net::HTTP::Post.new(uri.request_uri, {'User-Agent' => 'Browshot Ruby 1.14'})
	    request.body = post_body.join
	    request["Content-Type"] = "multipart/form-data, boundary=#{boundary}"
	    
	    if (uri.scheme == 'https')
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	    end

	    return http.request(request)
	end
end