require 'test_helper'

class ProjectGroupTest < ActiveSupport::TestCase
  test 'defaults to formation origin' do
    group = create(:project_group)

    assert group.origin_formation?
  end

  test 'accepts imported origin' do
    group = create(:project_group, :imported)

    assert group.origin_import?
    assert group.confirmed?
  end

  test 'rejects an unknown origin' do
    group = build(:project_group, origin: 'unknown')

    assert_not group.valid?
    assert group.errors.added?(:origin, :inclusion, value: 'unknown')
  end
end
