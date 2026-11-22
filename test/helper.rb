require 'test/unit'
require 'shoulda/context'

require_relative '../lib/browshot'

class Test::Unit::TestCase
  def live_browshot
    key = ENV['BROWSHOT_API_KEY']
    omit('Set BROWSHOT_API_KEY for live tests') if key.nil? || key.empty?
    Browshot.new(key)
  end

  def fixture_id(name)
    variable = "BROWSHOT_#{name.upcase}_ID"
    id = ENV[variable]
    omit("Set #{variable} to an owned test capture ID") if id.nil? || id.empty?
    id
  end
end
