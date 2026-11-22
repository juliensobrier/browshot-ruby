require_relative 'helper'
require 'tmpdir'
require 'webrick'

class TestBrowshotArtifacts < Test::Unit::TestCase
  FIXTURE_ID = '9007199254740991'
  TEST_KEY = 'test key & value'
  ARTIFACTS = {
    'pdf' => ['application/pdf', "%PDF-1.7\n\x00\x80\xff".b],
    'webm' => ['video/webm', "\x1a\x45\xdf\xa3\x00\x80\xff".b],
    'mp4' => ['video/mp4', "\x00\x00\x00\x10ftyp\x00\x80\xff".b],
    'gif' => ['image/gif', "GIF89a\x00\x80\xff".b]
  }.freeze

  context 'API 1.32 against a local server' do
    setup do
      ready = Queue.new
      @server = WEBrick::HTTPServer.new(
        :BindAddress => '127.0.0.1', :Port => 0,
        :Logger => WEBrick::Log.new(File::NULL), :AccessLog => [],
        :StartCallback => proc { ready << true }
      )
      @server.mount_proc('/') { |request, response| fixture_response(request, response) }
      @server_thread = Thread.new { @server.start }
      Timeout.timeout(5) { ready.pop }
      @browshot = Browshot.new(TEST_KEY, false, "http://127.0.0.1:#{@server.config[:Port]}/api/v1/")
    end

    teardown do
      @server.shutdown
      @server_thread.join
    end

    should 'download and save all four artifact formats without changing their bytes' do
      ARTIFACTS.each do |format, (_, content)|
        download = format == 'pdf' ? :screenshot_pdf : :screenshot_video
        save = format == 'pdf' ? :screenshot_pdf_file : :screenshot_video_file
        options = { :stub_format => format, 'id' => '1' }

        data = @browshot.public_send(download, FIXTURE_ID, options)
        assert_equal content, data
        assert_equal Encoding::BINARY, data.encoding
        assert_equal '1', options['id']

        Dir.mktmpdir do |directory|
          path = File.join(directory, "capture.#{format}")
          assert_equal path, @browshot.public_send(save, FIXTURE_ID, path, options)
          assert_equal content, File.binread(path)
        end
      end
    end

    should 'accept WebM when an MP4 request falls back' do
      assert_equal ARTIFACTS['webm'][1], @browshot.screenshot_video(FIXTURE_ID, :video_format => 'mp4')
    end

    should 'reject erroneous empty or truncated responses and incorrect content types' do
      [:screenshot_pdf, :screenshot_video].each do |method|
        [400, 401, 404, 503].each do |status|
          assert_equal '', @browshot.public_send(method, FIXTURE_ID, :stub_status => status)
        end
        [:stub_bad_type, :stub_empty, :stub_truncated].each do |flag|
          assert_equal '', @browshot.public_send(method, FIXTURE_ID, flag => 1)
        end
      end
      assert_equal '', @browshot.screenshot_pdf(FIXTURE_ID, :stub_format => 'gif')
      assert_equal '', @browshot.screenshot_video(FIXTURE_ID, :stub_format => 'pdf')
    end

    should 'reject invalid screenshot IDs and local paths' do
      [0, -1, nil, '1.5', 'test', '9' * 20, "1\n"].each do |id|
        assert_equal '', @browshot.screenshot_pdf(id)
        assert_equal '', @browshot.screenshot_video(id)
      end
      assert_equal '', @browshot.screenshot_pdf_file(FIXTURE_ID, '')
      assert_equal '', @browshot.screenshot_video_file(FIXTURE_ID, 1)
      assert_equal '', @browshot.screenshot_video_file(FIXTURE_ID, "bad\0path")
    end

    should 'leave an existing file intact on a download failure and handle write errors' do
      Dir.mktmpdir do |directory|
        path = File.join(directory, 'existing.pdf')
        File.binwrite(path, 'original')
        assert_equal '', @browshot.screenshot_pdf_file(FIXTURE_ID, path, :stub_status => 404)
        assert_equal 'original', File.binread(path)
        assert_equal '', @browshot.screenshot_video_file(FIXTURE_ID, File.join(path, 'capture.gif'))
      end
    end

    should 'forward all capture options through single multiple batch and crawl requests' do
      options = {
        :pdf => 1, :pdf_format => 'a4', :pdf_background => 1, :pdf_landscape => 0,
        :pdf_one_page => 1, :pdf_margin => '10mm', :pdf_margin_top => '1cm',
        :pdf_margin_bottom => '0.5in', :pdf_margin_left => '2px', :pdf_margin_right => '3px',
        :video => 1, :video_format => 'mp4', :video_duration => 5, :video_quality => 24,
        :video_fps => 20, :video_scale => 0.5, :device_scale => 1, :hide_ads => true
      }
      url = 'https://example.com/?a=hello+world&b=1'
      single = @browshot.screenshot_create(url, options.merge(:instance_id => 373))
      assert_capture_options single, 'screenshot/create', options
      assert_equal ['373'], single['query']['instance_id']
      assert_equal [url], single['query']['url']

      multiple = @browshot.screenshot_multiple(options.merge(:urls => [url, 'https://example.net/'], 'instances' => [373, 377]))
      assert_capture_options multiple, 'screenshot/multiple', options
      assert_equal [url, 'https://example.net/'], multiple['query']['url']
      assert_equal ['373', '377'], multiple['query']['instance_id']

      crawl = @browshot.crawl_create(381, 'example.com', options.merge(:url => url))
      assert_capture_options crawl, 'crawl/create', options
      assert_equal ['381'], crawl['query']['instance_id']
      assert_equal ['example.com'], crawl['query']['domain']
      assert_equal [url], crawl['query']['url']

      Dir.mktmpdir do |directory|
        path = File.join(directory, 'urls.csv')
        File.write(path, url + "\n")
        batch = @browshot.batch_create(385, path, options.dup)
        assert_capture_options batch, 'batch/create', options
        assert_equal ['385'], batch['query']['instance_id']
        assert_equal 'POST', batch['method']
        assert_equal url + "\n", batch['file']
      end
    end
  end

  private

  def fixture_response(request, response)
    query = URI.decode_www_form(request.query_string.to_s).group_by(&:first)
    query = query.transform_values { |pairs| pairs.map(&:last) }
    if query['stub_status']
      response.status = query['stub_status'].first.to_i
      response['Content-Type'] = 'application/json'
      response.body = '{"error":"test"}'
      return
    end

    if ['/api/v1/screenshot/pdf', '/api/v1/screenshot/video'].include?(request.path)
      unless query['id'] == [FIXTURE_ID] && query['key'] == [TEST_KEY] && request.request_method == 'GET'
        response.status = 404
        return
      end

      default_format = request.path.end_with?('/pdf') ? 'pdf' : 'webm'
      format = query.fetch('stub_format', [default_format]).first
      media_type, body = ARTIFACTS.fetch(format)
      media_type = 'text/html' if query.key?('stub_bad_type')
      body = ''.b if query.key?('stub_empty')
      response['Content-Type'] = media_type.upcase + '; charset=binary'
      if query.key?('stub_truncated')
        response['Content-Length'] = (body.bytesize + 1).to_s
        response['Connection'] = 'close'
      end
      response.body = body
    else
      response['Content-Type'] = 'application/json'
      response.body = JSON.generate(
        'path' => request.path, 'query' => query,
        'method' => request.request_method, 'file' => request.query['file']
      )
    end
  end

  def assert_capture_options(result, path, options)
    assert_equal '/api/v1/' + path, result['path']
    assert_equal [TEST_KEY], result['query']['key']
    options.each { |key, value| assert_equal [value.to_s], result['query'][key.to_s], key.to_s }
  end
end
