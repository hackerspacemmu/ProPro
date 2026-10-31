require 'test_helper'

class GroupRoutesTest < ActionDispatch::IntegrationTest
  test 'group formation page is a singular course resource' do
    assert_routing({ method: 'GET', path: '/courses/1/group_formation' },
                   { controller: 'group_formations', action: 'show', course_id: '1' })
  end

  test 'groups expose the write routes' do
    assert_routing({ method: 'GET', path: '/courses/1/groups' },
                   { controller: 'groups', action: 'index', course_id: '1' })
    assert_routing({ method: 'POST', path: '/courses/1/groups' },
                   { controller: 'groups', action: 'create', course_id: '1' })
    assert_routing({ method: 'GET', path: '/courses/1/groups/2' },
                   { controller: 'groups', action: 'show', course_id: '1', id: '2' })
    assert_routing({ method: 'GET', path: '/courses/1/groups/2/edit' },
                   { controller: 'groups', action: 'edit', course_id: '1', id: '2' })
    assert_routing({ method: 'PATCH', path: '/courses/1/groups/2' },
                   { controller: 'groups', action: 'update', course_id: '1', id: '2' })
    assert_routing({ method: 'DELETE', path: '/courses/1/groups/2' },
                   { controller: 'groups', action: 'destroy', course_id: '1', id: '2' })
  end

  test 'confirmation and leadership routes' do
    assert_routing({ method: 'POST', path: '/courses/1/groups/2/confirmation' },
                   { controller: 'group_confirmations', action: 'create', course_id: '1', group_id: '2' })
    assert_routing({ method: 'DELETE', path: '/courses/1/groups/2/confirmation' },
                   { controller: 'group_confirmations', action: 'destroy', course_id: '1', group_id: '2' })
    assert_routing({ method: 'PATCH', path: '/courses/1/groups/2/leader' },
                   { controller: 'group_leaders', action: 'update', course_id: '1', group_id: '2' })
    assert_routing({ method: 'POST', path: '/courses/1/groups/2/invite_link' },
                   { controller: 'group_invite_links', action: 'create', course_id: '1', group_id: '2' })
  end

  test 'member and invitation routes' do
    assert_routing({ method: 'POST', path: '/courses/1/groups/2/members' },
                   { controller: 'group_members', action: 'create', course_id: '1', group_id: '2' })
    assert_routing({ method: 'DELETE', path: '/courses/1/groups/2/members/3' },
                   { controller: 'group_members', action: 'destroy', course_id: '1', group_id: '2', id: '3' })
    assert_routing({ method: 'POST', path: '/courses/1/groups/2/join_requests' },
                   { controller: 'group_join_requests', action: 'create', course_id: '1', group_id: '2' })
    assert_routing({ method: 'PATCH', path: '/courses/1/groups/2/join_requests/3' },
                   { controller: 'group_join_requests', action: 'update', course_id: '1', group_id: '2', id: '3' })
    assert_routing({ method: 'POST', path: '/courses/1/groups/2/invitations' },
                   { controller: 'group_invitations', action: 'create', course_id: '1', group_id: '2' })
    assert_routing({ method: 'PATCH', path: '/courses/1/groups/2/invitations/3' },
                   { controller: 'group_invitations', action: 'update', course_id: '1', group_id: '2', id: '3' })
  end

  test 'invite link routes' do
    assert_routing({ method: 'GET', path: '/invite_links/token123' },
                   { controller: 'invite_links', action: 'show', token: 'token123' })
    assert_routing({ method: 'POST', path: '/invite_links/token123/redemption' },
                   { controller: 'invite_link_redemptions', action: 'create', invite_link_token: 'token123' })
  end

  test 'join URL redirects to the invite link' do
    assert_equal '/join/token123', Rails.application.routes.url_helpers.join_path('token123')

    get '/join/token123'
    assert_redirected_to '/invite_links/token123'
  end

  test 'legacy group URLs redirect' do
    get '/courses/1/project_groups'
    assert_redirected_to '/courses/1/group_formation'

    get '/project_group_invite_links/token123'
    assert_redirected_to '/invite_links/token123'
  end

  test 'the removed update_settings route no longer recognizes' do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path('/courses/1/project_groups/update_settings', method: :patch)
    end
  end

  test 'legacy helper names are removed' do
    helpers = Rails.application.routes.url_helpers

    assert_not helpers.respond_to?(:course_project_groups_path)
    assert_not helpers.respond_to?(:project_group_invite_link_path)
    assert_not helpers.respond_to?(:redeem_project_group_invite_link_path)
  end
end
