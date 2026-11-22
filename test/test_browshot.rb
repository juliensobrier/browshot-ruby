require_relative 'helper'
require 'tmpdir'

class TestBrowshot < Test::Unit::TestCase
  context 'Browshot client' do
    should 'report the API version' do
      assert_equal '1.32', Browshot.new.api_version
      assert_equal '1.32.0', Browshot::VERSION
    end
  end

  context 'Browshot API with an account' do
    setup do
      @browshot = live_browshot
    end

    should 'get a screenshot with the simple method and save it to disk' do
      parameters = { :url => 'https://browshot.com/', :instance_id => 12, :cache => 365 * 86400 }
      response = @browshot.simple(parameters)
      assert_equal 200, response[:code].to_i
      assert response[:png].bytesize > 100
      Dir.mktmpdir do |directory|
        path = File.join(directory, 'capture.png')
        saved = @browshot.simple_file(path, parameters)
        assert_equal 200, saved[:code].to_i
        assert_equal path, saved[:file]
        assert_equal response[:png].bytes, File.binread(path).bytes
      end
    end

    should 'return an error for an invalid Simple API URL' do
      response = @browshot.simple(:url => 'http://', :instance_id => 12)
      assert_equal 400, response[:code].to_i
      assert_equal '', response[:png]
    end

    should 'list free shared and private instances and fetch a free instance' do
      instances = @browshot.instance_list
      %w[free shared private].each { |type| assert_kind_of Array, instances[type] }
      assert !instances['free'].empty?
      assert !instances['shared'].empty?
      free = instances['free'].first
      instance = @browshot.instance_info(free['id'])
      %w[id width height type screenshot_cost].each do |key|
        assert_not_nil free[key]
        assert_equal free[key], instance[key]
      end
      %w[id name javascript mobile].each do |key|
        assert_not_nil free['browser'][key]
        assert_equal free['browser'][key], instance['browser'][key]
      end
      assert_equal 0, instance['screenshot_cost'].to_i
    end

    should 'list browsers and fetch the details of a browser' do
      browsers = @browshot.browser_list
      assert !browsers.empty?
      id, browser = browsers.first
      assert id.to_i > 0
      info = @browshot.browser_info(id)
      %w[name user_agent appname vendorsub appcodename platform vendor appversion javascript mobile].each do |key|
        assert browser.key?(key), "Missing #{key} in browser list"
        assert info.key?(key), "Missing #{key} in browser details"
      end
      assert_equal browser['name'], info['name']
    end

    should 'report validation errors for invalid capture requests' do
      assert @browshot.instance_info(-1)['error']
      assert @browshot.screenshot_create('http://', :instance_id => 12)['error']
      assert @browshot.screenshot_info(0)['error']
      assert @browshot.screenshot_host(0)['error']
      assert @browshot.screenshot_share(0)['error']
    end

    should 'create a screenshot and return its legacy identity fields' do
      screenshot = @browshot.screenshot_create('https://browshot.com/', :instance_id => 12, :cache => 365 * 86400)
      %w[id url instance_id size status priority].each { |key| assert screenshot.key?(key) }
      assert_include %w[in_process in_queue finished], screenshot['status']
    end

    should 'fetch screenshot metadata at all legacy detail levels' do
      id = fixture_id('screenshot')
      [0, 1, 2].each do |level|
        info = @browshot.screenshot_info(id, :details => level)
        assert_equal id, info['id'].to_s
        assert_equal 'finished', info['status']
        assert !info['screenshot_url'].empty?
        assert_equal level >= 1, info.key?('final_url')
        assert_equal level >= 1, info.key?('response_code')
        assert_equal level >= 2, info.key?('started')
        assert_equal level >= 2, info.key?('finished')
        assert !info.key?('images')
      end
    end

    should 'list and search for screenshots and retrieve a PNG thumbnail' do
      id = fixture_id('screenshot')
      info = @browshot.screenshot_info(id)
      screenshots = @browshot.screenshot_list(:limit => 1)
      assert !screenshots.empty?
      assert screenshots.values.first.key?('status')
      assert @browshot.screenshot_search(info['url']).key?(id)
      assert_equal "\x89PNG\r\n\x1a\n".b, @browshot.screenshot_thumbnail(id, :width => 64).byteslice(0, 8)
    end

    should 'get account information and reject an invalid key' do
      account = @browshot.account_info
      assert account.key?('balance')
      assert account['balance'].to_i >= 0
      assert_equal 1, account['active'].to_i
      assert Browshot.new('invalid-test-key').account_info['error']
    end
  end
end
