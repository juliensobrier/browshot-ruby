require_relative 'helper'
require 'tmpdir'

class TestBrowshotArtifactsLive < Test::Unit::TestCase
  context 'API 1.32 with an account' do
    setup do
      @browshot = live_browshot
    end

    {
      'pdf' => ['%PDF-'.b, 0],
      'webm' => ["\x1a\x45\xdf\xa3".b, 0],
      'mp4' => ['ftyp'.b, 4],
      'gif' => ['GIF8'.b, 0]
    }.each do |format, (signature, offset)|
      should "download and save a live #{format.upcase} artifact" do
        id = fixture_id(format)
        kind = format == 'pdf' ? 'pdf' : 'video'
        method = 'screenshot_' + kind
        info = @browshot.screenshot_info(id, :details => 1)
        assert_equal 'finished', info['status']
        assert_equal 1, info[kind].to_i
        assert !info[kind + '_url'].empty?

        content = @browshot.public_send(method, id)
        assert_equal signature, content.byteslice(offset, signature.bytesize)
        Dir.mktmpdir do |directory|
          path = File.join(directory, "capture.#{format}")
          assert_equal path, @browshot.public_send(method + '_file', id, path)
          assert_equal content, File.binread(path)
        end
      end
    end

    should 'list all sixteen native country instances at one credit' do
      instances = @browshot.instance_list['shared'].each_with_object({}) { |instance, ids| ids[instance['id']] = instance }
      countries = ['France', 'India', 'Finland', 'United Kingdom']
      (373..388).each do |id|
        assert instances.key?(id), "Missing instance #{id}"
        assert_equal countries[(id - 373) / 4], instances[id]['country']
        assert_equal 1, instances[id]['screenshot_cost'].to_i
      end
    end

    should 'return retina and ad blocking metadata' do
      info = @browshot.screenshot_info(fixture_id('retina'), :details => 1)
      assert_equal 'finished', info['status']
      assert_equal 2, info['device_scale'].to_i
      assert_equal 1, info['hide_ads'].to_i
    end

    should 'return empty strings for unavailable or unauthorized artifacts' do
      [@browshot, Browshot.new('invalid-test-key')].each do |client|
        assert_equal '', client.screenshot_pdf(1)
        assert_equal '', client.screenshot_video(1)
      end
    end
  end
end
