require 'test_helper'

# The server-side read of the comments panel width. No browser needed: the
# helper only reads a cookie, and the JavaScript that writes it is covered by
# the system test in test/system/projects/comments_panel_resize_test.rb.
class ApplicationHelperTest < ActionView::TestCase
  test 'no cookie means the default width' do
    assert_equal 360, comments_panel_width
  end

  test 'a width inside the range is used as is' do
    cookies[:propro_comments_panel_width] = '480'

    assert_equal 480, comments_panel_width
  end

  test 'a width above the range is clamped to the maximum' do
    cookies[:propro_comments_panel_width] = '9999'

    assert_equal 560, comments_panel_width
  end

  test 'a width below the range is clamped to the minimum' do
    cookies[:propro_comments_panel_width] = '100'

    assert_equal 320, comments_panel_width
  end

  test 'a non-numeric width falls back to the default' do
    cookies[:propro_comments_panel_width] = 'abc'

    assert_equal 360, comments_panel_width
  end
end
