current_dir = File.expand_path(File.dirname(__FILE__))
require "#{current_dir}/helper"

class TestBrowshot < Test::Unit::TestCase
#   def test_new
# 	puts "New client"
# 	client = Browshot.new()
# 	client = Browshot.new(key='',nil,debug=1)
# 	assert_equal(1, 1)
#   end
  context "Browshot client" do
    setup do
      @browshot = Browshot.new('vPTtKKLBtPUNxVwwfEKlVvekuxHyTXyi')
    end

    should "get the API version" do
      assert_equal '1.6', @browshot.api_version()
    end

    should "get a screenshot with the simple method" do
        data = @browshot.simple({'url' => 'http://mobilito.net/', 'cache' => 60 * 60 * 24 * 365})
        assert_equal 200, data[:code].to_i,                     "Screenshot should be succesful"
        assert_equal true, data[:png].length > 0,               "Screenshot should be sent"
    end

     should "get an error with the simple method" do
        data = @browshot.simple({'url' => 'http://', 'cache' => 60 * 60 * 24 * 365})
        assert_equal 400, data[:code].to_i,                     "Screenshot should have failed"
        assert_equal 0, data[:png].length,                      "Screenshot should not be sent"
    end

    should "get the list of instances available" do
#       assert_equal 10, @calculator.product(2, 5)
	  instances = @browshot.instance_list()
	  assert_equal false, instances['free'].nil?,				"List of free instances is missing"
	  assert_equal true,  instances['free'].kind_of?(Array),	"List of free instances is incorrect"
	  assert_equal true,  instances['free'].length > 0,			"There should be at least 1 free instance"

	  assert_equal false, instances['shared'].nil?,				"List of shared instances is missing"
	  assert_equal true,  instances['shared'].kind_of?(Array),	"List of shared instances is incorrect"
	  assert_equal true,  instances['shared'].length > 0,		"There should be at least 1 shared instance"

	  assert_equal false, instances['private'].nil?,			"List of private instances is missing"
	  assert_equal true,  instances['private'].kind_of?(Array),	"List of private instances is incorrect"
	  assert_equal true,  instances['private'].length == 0,		"There should be at least no private instance"

	  free = instances['free'][0]
	  assert_equal false, free['id'].nil?,						"Missing instance ID"
	  assert_equal false, free['width'].nil?,					"Missing instance screen width"
	  assert_equal false, free['height'].nil?,					"Missing instance screen height"
	  assert_equal false, free['load'].nil?,					"Missing instance load"
	  assert_equal false, free['browser'].nil?,					"Missing instance browser"
	  assert_equal false, free['browser']['id'].nil?,			"Missing instance browser ID"
	  assert_equal false, free['browser']['name'].nil?,			"Missing instance browser name"
	  assert_equal false, free['browser']['javascript'].nil?,	"Missing instance browser javascript capability"
	  assert_equal false, free['browser']['flash'].nil?,		"Missing instance browser flash capability"
	  assert_equal false, free['browser']['mobile'].nil?,		"Missing instance browser mobile capability"
	  assert_equal false, free['type'].nil?,					"Missing instance type"
	  assert_equal false, free['active'].nil?,					"Missing instance active"
	  assert_equal 1,     free['active'].to_i,					"Free instance should be active"
	  assert_equal false, free['screenshot_cost'].nil?,			"Missing instance cost"
	  assert_equal 0,     free['screenshot_cost'].to_i,			"Cost should be 0"
    end

    should "get an instance information" do
	  instances = @browshot.instance_list()
	  free = instances['free'][0]

	  instance = @browshot.instance_info(free['id'])
	  assert_equal free['id'], instance['id'],										"Mismatch instance ID"
	  assert_equal free['width'], instance['width'],								"Mismatch instance screen width"
	  assert_equal free['height'], instance['height'],								"Mismatch instance screen height"
	  assert_equal free['load'], instance['load'],									"Mismatch instance load"
	  assert_equal free['browser']['id'], instance['browser']['id'],				"Mismatch instance browser ID"
	  assert_equal free['browser']['name'], instance['browser']['name'],			"Mismatch instance browser name"
	  assert_equal free['browser']['javascript'], instance['browser']['javascript'],"Mismatch instance browser javascript capability"
	  assert_equal free['browser']['flash'], instance['browser']['flash'],			"Mismatch instance browser flash capability"
	  assert_equal free['browser']['mobile'], instance['browser']['mobile'],		"Mismatch instance browser mobile capability"
	  assert_equal free['type'], instance['type'],									"Mismatch instance type"
	  assert_equal free['active'], instance['active'],								"Mismatch instance active"
	  assert_equal free['screenshot_cost'], instance['screenshot_cost'],			"Mismatch instance cost"
    end

    should "send an error for the wrong instance ID" do
	  instance = @browshot.instance_info(-1)

 	  assert_equal false, instance['error'].nil?,					"Instance should not be found"
 	  assert_equal false, instance['status'].nil?,					"Instance should not be found"
    end

    should "send an errror when creating a instanc with ivalid arguments" do
	  instance = @browshot.instance_create({'width' => 3000})
 	  assert_equal false, instance['error'].nil?,					"Instance width should be too large"

	  instance = @browshot.instance_create({'height' => 3000})
 	  assert_equal false, instance['error'].nil?,					"Instance width should be too large"

	  instance = @browshot.instance_create({'browser_id' => -1})
 	  assert_equal false, instance['error'].nil?,					"Instance browser ID should be invalid"
    end

    should "create a new instance (sort of)" do
# 	  Instance is not actually created for test account, so the reply may not match our parameters
	  instance = @browshot.instance_create()

	  assert_equal false, instance['id'].nil?,						"Instance ID should be present"
	  assert_equal false, instance['width'].nil?,					"Instance screen width should be present"
	  assert_equal false, instance['height'].nil?,					"Instance screen height should be present"
	  assert_equal false, instance['active'].nil?,					"Instance active should be present"
	  assert_equal 1, 	  instance['active'].to_i,					"Instance should be active"
	  assert_equal false, instance['browser'].nil?,					"Instance browser should be present"
	  assert_equal false, instance['browser']['id'].nil?,			"Instance browser ID should be present"
    end

    should "get the list of browsers" do
	  browsers = @browshot.browser_list()
	  assert_equal true, browsers.length > 0,						"There should be multiple browsers"

	  browser_id = 0
	  browsers.each do |key, browser|
		browser_id = key
		break
	  end

	  assert_equal true, browser_id.to_i > 0,							"Browser ID should be positive"
      browser = browsers[browser_id]

	  assert_equal false, browser['name'].nil?,						"Browser name should be present"
	  assert_equal false, browser['user_agent'].nil?,				"Browser user_agent should be present"
	  assert_equal false, browser['appname'].nil?,					"Browser appname should be present"
	  assert_equal false, browser['vendorsub'].nil?,				"Browser vendorsub should be present"
	  assert_equal false, browser['appcodename'].nil?,				"Browser appcodename should be present"
	  assert_equal false, browser['platform'].nil?,					"Browser platform should be present"
	  assert_equal false, browser['vendor'].nil?,					"Browser vendor should be present"
	  assert_equal false, browser['appversion'].nil?,				"Browser appversion should be present"
	  assert_equal false, browser['javascript'].nil?,				"Browser javascript capability should be present"
	  assert_equal false, browser['mobile'].nil?,					"Browser mobile capability should be present"
	  assert_equal false, browser['flash'].nil?,					"Browser flash capability should be present"
    end

    should "create a browser" do
	  # browser is not actually created for test account, so the reply may not match our parameters
	  browser = @browshot.browser_create({'mobile' => 1, 'flash' => 1, 'user_agent' => 'test'})

	  assert_equal false, browser['name'].nil?,						"Browser name should be present"
	  assert_equal false, browser['user_agent'].nil?,				"Browser user_agent should be present"
	  assert_equal false, browser['appname'].nil?,					"Browser appname should be present"
	  assert_equal false, browser['vendorsub'].nil?,				"Browser vendorsub should be present"
	  assert_equal false, browser['appcodename'].nil?,				"Browser appcodename should be present"
	  assert_equal false, browser['platform'].nil?,					"Browser platform should be present"
	  assert_equal false, browser['vendor'].nil?,					"Browser vendor should be present"
	  assert_equal false, browser['appversion'].nil?,				"Browser appversion should be present"
	  assert_equal false, browser['javascript'].nil?,				"Browser javascript capability should be present"
	  assert_equal false, browser['mobile'].nil?,					"Browser mobile capability should be present"
	  assert_equal false, browser['flash'].nil?,					"Browser flash capability should be present"
    end

    should "fail to create screenshot" do
	  screenshot = @browshot.screenshot_create()
	  assert_equal false, screenshot['error'].nil?,					"Screenshot should have failed"

	  screenshot = @browshot.screenshot_create('-')
	  assert_equal false, screenshot['error'].nil?,					"Screenshot should have failed"
    end


    should "create screenshot" do
	  # screenshot is not actually created for test account, so the reply may not match our parameters
	  screenshot = @browshot.screenshot_create('http://browshot.com/')

	  assert_equal false, screenshot['id'].nil?, 					"Screenshot ID should be present"
	  assert_equal false, screenshot['status'].nil?, 				"Screenshot status should be present"
	  assert_equal false, screenshot['priority'].nil?, 				"Screenshot priority should be present"

	  if (screenshot['status'] == 'finished')
	  	assert_equal false, screenshot['screenshot_url'].nil?, 		"Screenshot screenshot_url should be present"
	  	assert_equal false, screenshot['url'].nil?, 				"Screenshot url should be present"
	  	assert_equal false, screenshot['size'].nil?, 				"Screenshot size should be present"
	  	assert_equal false, screenshot['width'].nil?, 				"Screenshot width should be present"
	  	assert_equal false, screenshot['height'].nil?, 				"Screenshot height should be present"
	  	assert_equal false, screenshot['request_time'].nil?, 		"Screenshot request_time should be present"
	  	assert_equal false, screenshot['started'].nil?, 			"Screenshot started should be present"
	  	assert_equal false, screenshot['load'].nil?, 				"Screenshot load should be present"
	  	assert_equal false, screenshot['content'].nil?, 			"Screenshot content should be present"
	  	assert_equal false, screenshot['finished'].nil?, 			"Screenshot finished should be present"
	  	assert_equal false, screenshot['instance_id'].nil?, 		"Screenshot instance_id should be present"
	  	assert_equal false, screenshot['response_code'].nil?, 		"Screenshot response_code should be present"
	  	assert_equal false, screenshot['final_url'].nil?, 			"Screenshot final_url should be present"
	  	assert_equal false, screenshot['content_type'].nil?, 		"Screenshot content_type should be present"
	  	assert_equal false, screenshot['scale'].nil?, 				"Screenshot scale should be present"
		assert_equal false, screenshot['cost'].nil?, 				"Screenshot cost should be present"
	  end
    end

    should "not be able to retrieve a screenshot" do
	  screenshot = @browshot.screenshot_info()
	  assert_equal false, screenshot['error'].nil?,					"Screenshot should have failed"
    end

    should "to retrieve a screenshot" do
	  screenshot = @browshot.screenshot_create('http://browshot.com/')
      info  = @browshot.screenshot_info(screenshot['id'])

	  assert_equal false, info['id'].nil?,							"Screenshot ID should be present"
	  assert_equal false, info['status'].nil?,						"Screenshot status should be present"
	  assert_equal false, info['priority'].nil?,					"Screenshot priority should be present"
	  assert_equal false, info['cost'].nil?,						"Screenshot cost should be present"

	  if (info['status'] == 'finished')
	  	assert_equal false, info['screenshot_url'].nil?, 			"Screenshot screenshot_url should be present"
	  	assert_equal false, info['url'].nil?, 						"Screenshot url should be present"
	  	assert_equal false, info['size'].nil?, 						"Screenshot size should be present"
	  	assert_equal false, info['width'].nil?, 					"Screenshot width should be present"
	  	assert_equal false, info['height'].nil?, 					"Screenshot height should be present"
	  	assert_equal false, info['request_time'].nil?, 				"Screenshot request_time should be present"
	  	assert_equal false, info['started'].nil?, 					"Screenshot started should be present"
	  	assert_equal false, info['load'].nil?, 						"Screenshot load should be present"
	  	assert_equal false, info['content'].nil?, 					"Screenshot content should be present"
	  	assert_equal false, info['finished'].nil?, 					"Screenshot finished should be present"
	  	assert_equal false, info['instance_id'].nil?, 				"Screenshot instance_id should be present"
	  	assert_equal false, info['response_code'].nil?, 			"Screenshot response_code should be present"
	  	assert_equal false, info['final_url'].nil?, 				"Screenshot final_url should be present"
	  	assert_equal false, info['content_type'].nil?, 				"Screenshot content_type should be present"
	  	assert_equal false, info['scale'].nil?, 					"Screenshot scale should be present"
	  end
    end

    should "retrieve the list of screenshots" do
	  screenshots = @browshot.screenshot_list()
	  assert_equal true, screenshots.length > 0,					"There should be multiple screenshots"

      screenshot_id = 0
	  screenshots.each do |key, screenshot|
		screenshot_id = key
		break
	  end

	  assert_equal true, screenshot_id.to_i > 0,					"Screenshot ID should be positive"
      screenshot = screenshots[screenshot_id]

	  assert_equal false, screenshot['id'].nil?,					"Screenshot ID should be present"
	  assert_equal false, screenshot['status'].nil?,				"Screenshot status should be present"
	  assert_equal false, screenshot['priority'].nil?,				"Screenshot priority should be present"
	  assert_equal false, screenshot['cost'].nil?,					"Screenshot cost should be present"

	  if (screenshot['status'] == 'finished')
	  	assert_equal false, screenshot['screenshot_url'].nil?, 		"Screenshot screenshot_url should be present"
	  	assert_equal false, screenshot['url'].nil?, 				"Screenshot url should be present"
	  	assert_equal false, screenshot['size'].nil?, 				"Screenshot size should be present"
	  	assert_equal false, screenshot['width'].nil?, 				"Screenshot width should be present"
	  	assert_equal false, screenshot['height'].nil?, 				"Screenshot height should be present"
	  	assert_equal false, screenshot['request_time'].nil?, 		"Screenshot request_time should be present"
	  	assert_equal false, screenshot['started'].nil?, 			"Screenshot started should be present"
	  	assert_equal false, screenshot['load'].nil?, 				"Screenshot load should be present"
	  	assert_equal false, screenshot['content'].nil?, 			"Screenshot content should be present"
	  	assert_equal false, screenshot['finished'].nil?, 			"Screenshot finished should be present"
	  	assert_equal false, screenshot['instance_id'].nil?, 		"Screenshot instance_id should be present"
	  	assert_equal false, screenshot['response_code'].nil?, 		"Screenshot response_code should be present"
	  	assert_equal false, screenshot['final_url'].nil?, 			"Screenshot final_url should be present"
	  	assert_equal false, screenshot['content_type'].nil?, 		"Screenshot content_type should be present"
	  	assert_equal false, screenshot['scale'].nil?, 				"Screenshot scale should be present"
	  end
	end

    should "retrieve a thumbnail" do
	  # TODO
	end

    should "retrieve account information" do
	  account = @browshot.account_info()
	  assert_equal false, account['balance'].nil?, 					"Account balance should be present"
	  assert_equal 0,     account['balance'].to_i, 					"Balance should be empty"
	  assert_equal false, account['active'].nil?, 					"Account active should be present"
	  assert_equal 1,     account['active'].to_i, 					"Accountshould be active"
	  assert_equal false, account['instances'].nil?, 				"Account instances should be present"
	end

    should "refuse invalid key" do
	  bad = Browshot.new()
	  account = bad.account_info()
	  assert_equal false, account['error'].nil?, 					"Request should be invalid"
	end
  end
end
