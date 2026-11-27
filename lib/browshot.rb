# The library requires an API key from Browshot.
# Sign up for a free account a http://browshot.com/
# 
# See README.rdoc for more information abouth Browshot
# and this library.
#
# @author    Julien Sobrier  (mailto:jsobrier@browshot.com)
# Copyright:: Copyright (c) 2016 Browshot
# License::   Distributes under the same terms as Ruby

require 'rubygems'
require 'url'
require 'json'
require 'net/http'
require 'net/https'
require "cgi"

class Browshot
	VERSION = '2.0.0'

	# @!attribute [r]
	# API key
	attr_reader :key
	# @!attribute [r]
	# Base URL for all API requests. You should use the default base provided by the library. Be careful if you decide to use HTTP instead of HTTPS as your API key could be sniffed and your account could be used without your consent.
	attr_reader :base
	# @!attribute [r]
	# print debug output to the standard output
	attr_reader :debug

	# New client
	#
	# @param key [String] API key
	# @param debug [Boolean] Set to true to print debug output to the standard output. false (disabled) by default.
	# @param base [String] Base URL for all API requests. You should use the default base provided by the library. Be careful if you decide to use HTTP instead of HTTPS as your API key could be sniffed and your account could be used without your consent.
	def initialize(key='', debug=false, base=nil)
		@key = key || ''
		@auto_api = base.nil?
		@base = base || 'https://api.browshot.com/api/v2/'
		@debug = debug || false
	end

	# Return the API version handled by the library. Note that this library can usually handle new arguments in requests without requiring an update.
	def api_version()
		return VERSION.split('.')[0, 2].join('.')
	end

    # Retrieve a screenshot with one call. See {https://browshot.com/api/documentation#simple} for the full list of possible arguments.
    #
    # @return [Array<Symbol, Symbol>] !{:code => 200, :png => <content>} in case of success
    def simple(parameters={})
        begin
            response = request('simple', parameters) { |url| fetch(url) }
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

    # Save a screenshot to a file with one call, and save it to a file. See {https://browshot.com/api/documentation#simple} for the full list of possible arguments.
    #
    # @param file [String] Local file name to write to.
    # @param parameters  [Array<Symbol, Symbol>] Additional options
    # @return [Array<Symbol, Symbol>] !{:code => 200, :file => <file_name>} in case of success
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
	# @param id [Integer] Instance ID
	def instance_info(id=0)
		return return_reply('instance/info', { 'id' => id })
	end


	# Return the list of browsers. See http://browshot.com/api/documentation#browser_list for the response format.
	def browser_list()
		return return_reply('browser/list')
	end

	# Return the details of a browser. See http://browshot.com/api/documentation#browser_info for the response format.
	#
	# @param id [Integer]  Browser ID
	def browser_info(id=0, parameters={})
		if ['chrome', 'firefox'].include?(id.to_s)
			parameters = parameters.merge(:browser => id)
		elsif id != 0 || !parameters.keys.any? { |key| key.to_s == 'browser' }
			parameters = parameters.merge(:id => id)
		end
		return return_reply('browser/info', parameters)
	end


	# Request a screenshot. See http://browshot.com/api/documentation#screenshot_create for the response format.
	#
	# @param url [String] URL of the website to create a screenshot of.
	def screenshot_create(url='', parameters={})
		parameters[:url] = url
		return return_reply('screenshot/create', parameters)
	end

	# Get information about a screenshot requested previously. See http://browshot.com/api/documentation#screenshot_info for the response format.
	#
	# @param id [Integer] screenshot ID
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
	# @eturn an empty string if the image could not be retrieved.
	# @param id [Integer] screenshot ID
	def screenshot_thumbnail(id=0, parameters={})
		parameters[:id] = id

		begin
            response = request('screenshot/thumbnail', parameters) { |url| fetch(url) }
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
	# @param id [Integer] screenshot ID
	# @param hosting ['s3', 'browshot'] hosting option: s3 or browshot
	def screenshot_host(id=0, hosting='browshot', parameters={})
		parameters[:id] = id
		parameters[:hosting] = hosting
		return return_reply('screenshot/host', parameters)
	end

	# Share a screenshot. See http://browshot.com/api/documentation#screenshot_share for the response format.
	#
	# @param id [Integer] screenshot ID
	def screenshot_share(id=0, parameters={})
		parameters[:id] = id
		return return_reply('screenshot/share', parameters)
	end

	# Delete details of a screenshot. See http://browshot.com/api/documentation#screenshot_delete for the response format.
	#
	# @param id [Integer] screenshot ID
	def screenshot_delete(id=0, parameters={})
		parameters[:id] = id
		return return_reply('screenshot/delete', parameters)
	end
	
	# Get details about screenshots requested. See http://browshot.com/api/documentation#screenshot_search for the response format.
	#
	# @param url [String] URL string to match
	def screenshot_search(url='', parameters={})
		parameters[:url] = url
		return return_reply('screenshot/search', parameters)
	end


	# Retrieve the screenshot, or a thumbnail, and save it to a file. See http://browshot.com/api/documentation#screenshot_thumbnails for the response format.
	#
	# See http://browshot.com/api/documentation#screenshot_thumbnails for the full list of possible arguments.
	# 
	# @param id [Integer] screenshot ID
	# @param file [String]  Local file name to write to.
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
	# @param id [Integer] screenshot ID
	def screenshot_html(id=0, parameters={})
		parameters[:id] = id

		return return_string('screenshot/html', parameters)
	end
	
	
	# Download the PDF generated by a finished screenshot requested with pdf=1.
	#
	# @param id [Integer, String] Screenshot ID
	# @return [String] PDF bytes, or an empty string on failure
	def screenshot_pdf(id=0, parameters={})
		return screenshot_artifact('pdf', id, parameters, ['application/pdf'])
	end

	# Download the WebM, MP4, or GIF generated by a finished screenshot requested with video=1.
	#
	# @param id [Integer, String] Screenshot ID
	# @return [String] Recording bytes, or an empty string on failure
	def screenshot_video(id=0, parameters={})
		return screenshot_artifact('video', id, parameters, ['video/webm', 'video/mp4', 'image/gif'])
	end

	# Save a PDF to a local file and return its name, or an empty string on failure.
	def screenshot_pdf_file(id=0, file='', parameters={})
		return save_artifact(:screenshot_pdf, id, file, parameters)
	end

	# Save a video to a local file and return its name, or an empty string on failure.
	# MP4 requests can produce WebM. The file name stays as supplied.
	def screenshot_video_file(id=0, file='', parameters={})
		return save_artifact(:screenshot_video, id, file, parameters)
	end


	# Request multiple screenshots. See http://browshot.com/api/documentation#screenshot_multiple for the response format.
	#
	# See http://browshot.com/api/documentation#screenshot_multiple for the full list of possible arguments.
	def screenshot_multiple(parameters={})
		return return_reply('screenshot/multiple', parameters)
	end
	
	# Request multiple screenshots from a text file. See http://browshot.com/api/documentation#batch_create for the response format.
	#
	# See http://browshot.com/api/documentation#batch_create for the full list of possible arguments.
	# 
	# @param id [Integer] Instance ID
	# @param file [String] Path to the text file which contains the list of URLs
	def batch_create(id=nil, file='', parameters={})
		if id.is_a?(String) && id !~ /\A\d+\z/
			parameters = file if file.is_a?(Hash)
			file, id = id, nil
		end
		parameters = parameters.merge(:file => file)
		parameters[:instance_id] = id unless id.nil?

		return return_post_reply('batch/create', parameters)
	end
	
	# Get information about a screenshot batch requested previously. See {https://browshot.com/api/documentation#batch_info} for the response format.
	#
	# See http://browshot.com/api/documentation#batch_info for the full list of possible arguments.
	# 
	# @param id [Integer] Batch ID
	def batch_info(id=0,  parameters={})
		parameters[:id] = id

		return return_reply('batch/info', parameters)
	end
	
	# Crawl a domain. See https://browshot.com/api/documentation#crawl_create.
	#
	# @param id [Integer] Instance ID
	# @param domain [String] Domain to crawl
	# @param parameters [Hash] Capture options, including an optional :url to start with
	def crawl_create(id=nil, domain='', parameters={})
		if id.is_a?(String) && id !~ /\A\d+\z/
			parameters = domain if domain.is_a?(Hash)
			domain, id = id, nil
		end
		parameters = parameters.dup
		parameters[:instance_id] = id unless id.nil?
		unless domain.empty?
			parameters.delete('domain')
			parameters[:domain] = domain
		end

		return return_reply('crawl/create', parameters)
	end

	# Get information about a screenshot crawl requested previously. See {https://browshot.com/api/documentation#crawl_info} for the response format.
	#
	# See http://browshot.com/api/documentation#crawl_info for the full list of possible arguments.
	# 
	# @param id [Integer] Crawl ID
	def crawl_info(id=0,  parameters={})
		parameters[:id] = id

		return return_reply('crawl/info', parameters)
	end


	#  Return information about the user account. See {https://browshot.com/api/documentation#account_info} for the response format.
	def account_info(parameters={})
		return return_reply('account/info', parameters)
	end

	def device_list(parameters={})
		return return_reply('device/list', parameters)
	end

	def app_list(parameters={})
		return return_reply('app/list', parameters)
	end

	def app_info(id, parameters={})
		return return_reply('app/info', parameters.merge(:id => id))
	end

	def app_create(parameters)
		return app_request('app/create', parameters)
	end

	def app_update(id, parameters)
		return app_request('app/update', parameters.merge(:id => id))
	end

	def app_delete(id, parameters={})
		return app_request('app/delete', parameters.merge(:id => id))
	end

	def app_test(id, parameters={})
		return app_request('app/test', parameters.merge(:id => id))
	end

	def app_run(id, apps, parameters={})
		return app_request('app/run', parameters.merge(:screenshot_id => id, :apps => apps))
	end

	private

	def screenshot_artifact(kind, id, parameters, content_types)
		return ''.b unless id.to_s =~ /\A[1-9][0-9]{0,18}\z/

		query = parameters.reject { |key, _| key.to_s == 'id' }
		query[:id] = id
		response = request('screenshot/' + kind, query) do |address|
			url = URI(address)
			get = Net::HTTP::Get.new(url.request_uri, {
				'Accept-Encoding' => 'identity', 'User-Agent' => "Browshot Ruby #{VERSION}"
			})
			Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') do |http|
				http.request(get)
			end
		end
		return ''.b unless response.code == '200'

		type = response['content-type'].to_s.partition(';').first.strip.downcase
		return ''.b unless content_types.include?(type)

		body = response.body.to_s.b
		length = response['content-length']
		return ''.b if length && length.to_i != body.bytesize

		return body
	rescue IOError, SystemCallError, SocketError, Timeout::Error, OpenSSL::SSL::SSLError,
		Net::HTTPBadResponse, Net::ProtocolError
		return ''.b
	end

	def save_artifact(method, id, file, parameters)
		return '' unless file.is_a?(String) || file.respond_to?(:to_path)
		return '' if file == ''

		content = public_send(method, id, parameters)
		return '' if content.empty?

		File.binwrite(file, content)
		return file
	rescue IOError, SystemCallError, ArgumentError
		return ''
	end

	def app_request(action, parameters)
		body = {}
		parameters.each_pair { |key, value| body[key.to_s] = value }
		query = { :api_version => body.delete('api_version') }
		['id', 'screenshot_id'].each do |field|
			body[field] = body[field].to_i if body[field].to_s =~ /\A\d+\z/
		end
		if ['0', '1'].include?(body['isActive'].to_s)
			body['isActive'] = body['isActive'].to_s == '1'
		end
		body['apps'] = body['apps'].map(&:to_s) if body['apps'].is_a?(Array)
		return JSON.parse(post(make_url(action, query), '', body).body)
	end

	def version_for(action, parameters)
		version = (parameters[:api_version] || parameters['api_version']).to_s
		return version if ['1', '2'].include?(version)
		return nil unless @auto_api
		return '1' if action =~ %r{\A(?:instance/|browser/create\z|screenshot/host\z)}

		id = parameters[:id] || parameters['id']
		return '1' if action == 'browser/info' && id && !['40', '42'].include?(id.to_s)

		legacy = /\A(?:instance_id|instance_ids|instances|screen|details|ids|hook(?:_.+)?|hosting(?:_.+)?|device_name|device_touch|device_mobile|device_landscape|user_agent)\z/
		return '1' if parameters.any? { |key, value| !value.nil? && value != [] && legacy.match(key.to_s) }
		return '2'
	end

	def make_url(action='', parameters={})
		version = version_for(action, parameters)
		base = @base.sub(%r{/\z}, '')
		base = base.sub(%r{/api/v[12]\z}, '/api/v' + version) if version
		url = "#{base}/#{action}?key=#{CGI.escape(@key.to_s)}"
		encode = lambda { |key, value| "&#{CGI.escape(key)}=#{CGI.escape(value.to_s)}" }

		parameters.each_pair do |key, value|
			key = key.to_s
			next if key == 'api_version' || value.nil?
			key = { 'urls' => 'url', 'instances' => 'instance_id' }.fetch(key, key)
			value = JSON.generate(value) if key == 'profiles' && value.is_a?(Array)
			if key == 'apps' && value.is_a?(Hash)
				value.each_pair { |app, template| url += encode.call("apps[#{app}]", template) unless template.nil? }
			else
				values = ['url', 'instance_id', 'apps'].include?(key) && value.is_a?(Array) ? value : [value]
				values.each { |item| url += encode.call(key, item) unless item.nil? }
			end
		end
		puts "#{base}/#{action}" if @debug
		return url
	end

	def request(action, parameters)
		url = make_url(action, parameters)
		response = yield url
		return response unless @auto_api && (parameters[:api_version] || parameters['api_version']).nil?
		return response unless version_for(action, parameters) == '2' && response.code == '404'
		return response if response.uri && response.uri.path != URI(url).path
		return response if action =~ %r{\A(?:app/|device/|wait\z|batch/download\z|ping\z|simple/)}
		v2_only = /\A(?:browser|country|screen_width|screen_height|mobile|device|profiles|apps(?:\[.*\])?)\z/
		return response if parameters.any? { |key, value| !value.nil? && v2_only.match(key.to_s) }
		return response unless response['content-type'].to_s =~ %r{\Aapplication/json(?:;|\z)}i

		error = JSON.parse(response.body)
		if error.is_a?(Hash) && error['success'] == false && error['error'] == 'NOT_FOUND' && error['message'] == 'Page not found'
			return yield make_url(action, parameters.merge(:api_version => 1))
		end
		return response
	rescue JSON::ParserError
		return response
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
		response = request(action, parameters) { |url| Net::HTTP.get_response(URI(url)) }
		return response.body
	end

	def return_post_string(action='', parameters={})
		query = parameters.dup
		file = query.delete(:file)
		response = request(action, query) { |url| post(url, file) }
		return response.body
	end

	def fetch(url, limit=32)
	    raise ArgumentError, 'HTTP redirect too deep' if (limit == 0)

	    uri = URI.parse(url)
	    http = Net::HTTP.new(uri.host, uri.port)
	    http.open_timeout = 240
	    http.read_timeout = 240

	    request = Net::HTTP::Get.new(uri, {'User-Agent' => "Browshot Ruby #{VERSION}"})
	    if (uri.scheme == 'https')
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	    end
	    response = http.request(request)

	    case response
		when Net::HTTPRedirection then 
		    path = response['location']
		    url = URI.join(uri, path)
		    return fetch(url.to_s, limit - 1)
		else
		    return response
	    end
	end
	
	def post(url, file='', json=nil)
	    raise ArgumentError, 'Missing file to upload' if (file == '' && json.nil?)
	  
	    uri = URI.parse(url)
	    http = Net::HTTP.new(uri.host, uri.port)
	    http.open_timeout = 240
	    http.read_timeout = 240
	    
	    request = Net::HTTP::Post.new(uri.request_uri, {'User-Agent' => "Browshot Ruby #{VERSION}"})
	    if json
		request.body = JSON.generate(json)
		request['Content-Type'] = 'application/json'
	    else
		boundary = "AaB03x"
		post_body = []
		post_body << "--#{boundary}\r\n"
		post_body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{File.basename(file)}\"\r\n"
		post_body << "Content-Type: text/plain\r\n"
		post_body << "\r\n"
		post_body << File.read(file)
		post_body << "\r\n--#{boundary}--\r\n"
		request.body = post_body.join
		request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
	    end

	    if (uri.scheme == 'https')
		http.use_ssl = true
		http.verify_mode = json ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
	    end

	    return http.request(request)
	end
end