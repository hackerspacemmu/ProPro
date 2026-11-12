module GroupFormationsHelper
  BTN = 'inline-flex items-center justify-center rounded-full font-medium transition-colors cursor-pointer disabled:cursor-not-allowed max-sm:min-h-11'.freeze

  GROUP_FILL_BUTTON = "#{BTN} bg-primary-strong px-5 py-2 text-sm text-white hover:bg-primary-hover".freeze
  GROUP_OUTLINE_BUTTON = "#{BTN} border border-outline px-5 py-2 text-sm text-primary-strong hover:bg-primary-container".freeze
  GROUP_TONAL_BUTTON = "#{BTN} bg-primary-container-alt px-5 py-2 text-sm text-primary-strong hover:bg-primary-container-ring".freeze
  GROUP_SECONDARY_BUTTON = "#{BTN} border border-outline-variant bg-surface px-4 py-1.5 text-[13px] text-on-surface hover:bg-surface-variant".freeze
  GROUP_WARNING_BUTTON = "#{BTN} border border-warning-border bg-surface px-4 py-1.5 text-[13px] text-warning-on-container hover:bg-warning-container-alt".freeze
  GROUP_ROW_BUTTON = "#{BTN} bg-primary-container-alt px-3 py-1.5 text-[13px] whitespace-nowrap text-primary-strong hover:bg-primary-container-ring max-sm:w-full".freeze
  GROUP_ROW_DISABLED_BUTTON = "#{BTN} bg-surface-variant px-3 py-1.5 text-[13px] whitespace-nowrap text-on-surface-disabled max-sm:w-full".freeze
  GROUP_SMALL_BUTTON = "#{BTN} border border-outline px-4 py-1.5 text-[13px] text-primary-strong hover:bg-primary-container".freeze
  GROUP_TEXT_BUTTON = "#{BTN} px-3 py-2 text-sm text-primary-strong hover:bg-primary-container".freeze
  GROUP_TEXT_SMALL_BUTTON = "#{BTN} px-3 py-1.5 text-[13px] text-primary-strong hover:bg-primary-container".freeze
  GROUP_DANGER_TEXT_BUTTON = "#{BTN} px-3 py-2 text-sm text-error hover:bg-error-container".freeze
  GROUP_DANGER_TEXT_SMALL_BUTTON = "#{BTN} px-3 py-1 text-[13px] text-error hover:bg-error-container".freeze
  # Filled red: confirm / dissolve dialog OK only
  GROUP_DANGER_BUTTON = "#{BTN} bg-error px-5 py-2 text-sm text-white hover:bg-error-hover".freeze

  GROUP_DIALOG = 'cursor-auto text-left m-auto w-[calc(100vw-2rem)] max-w-lg overflow-hidden rounded-lg border-0 bg-surface p-0 shadow-xl backdrop:bg-black/30 max-sm:m-0 max-sm:h-dvh max-sm:max-h-none max-sm:w-screen max-sm:max-w-none max-sm:rounded-none'.freeze
  GROUP_DIALOG_PANEL = 'flex max-h-[85vh] min-h-0 flex-col max-sm:h-dvh max-sm:max-h-none'.freeze
  GROUP_DIALOG_HEADER = 'flex shrink-0 items-center justify-between gap-3 px-4 pb-2 pt-3 sm:px-6 sm:pb-3 sm:pt-5'.freeze
  GROUP_DIALOG_TITLE = "min-w-0 break-words font-['DM_Sans'] text-xl font-medium text-on-surface-strong".freeze
  GROUP_DIALOG_CLOSE = 'flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-on-surface-variant hover:bg-surface-variant sm:h-9 sm:w-9'.freeze
  GROUP_DIALOG_BODY = 'min-h-0 flex-1 overflow-y-auto px-4 sm:px-6'.freeze
  GROUP_DIALOG_FOOTER = 'flex shrink-0 flex-col-reverse gap-3 border-t border-outline-variant px-4 pb-[max(0.75rem,env(safe-area-inset-bottom))] pt-3 sm:flex-row sm:items-center sm:justify-between sm:px-6 sm:py-4'.freeze
  GROUP_SECTION = 'border-b border-outline-variant py-4 last:border-0'.freeze
  GROUP_SECTION_TITLE = "mb-2 font-['DM_Sans'] text-[15px] font-medium text-on-surface-strong".freeze
  GROUP_INPUT = 'block w-full rounded-md border border-outline-variant bg-surface-tint px-3 py-2 text-sm text-on-surface outline-none transition-all focus:border-transparent focus:bg-surface focus:ring-2 focus:ring-primary max-sm:min-h-11 max-sm:text-base'.freeze

  def group_size_state(group, course)
    count = group.project_group_members.size
    return :under if count < course.effective_group_min
    return :over if course.group_max.present? && count > course.group_max

    :ok
  end

  def group_full?(group, course)
    course.group_full?(group.project_group_members.size)
  end

  def group_size_summary(course)
    return 'No group size limit' if course.group_min.blank? && course.group_max.blank?
    return "#{course.group_min}–#{course.group_max} members per group" if course.group_min.present? && course.group_max.present?
    return "At least #{pluralize(course.group_min, 'member')} per group" if course.group_min.present?

    "Up to #{pluralize(course.group_max, 'member')} per group"
  end

  def leader_first(members, group)
    leader, others = members.partition { |member| member.user_id == group.leader_id }
    leader + others
  end

  def group_member_names(group)
    group.project_group_members.map { |member| member.user.name }.compact.join(', ')
  end

  def group_size_warning(group, course)
    return if group_size_state(group, course) == :ok

    limits = if course.group_min.present? && course.group_max.present?
               if course.group_min == course.group_max
                 "the required size is #{pluralize(course.group_min, 'member')}"
               else
                 "the allowed size is #{course.group_min}–#{course.group_max} members"
               end
             elsif course.group_min.present?
               "the minimum is #{pluralize(course.group_min, 'member')}"
             else
               "the maximum is #{pluralize(course.group_max, 'member')}"
             end

    "Warning: #{group.group_name.presence || 'This group'} has #{pluralize(group.project_group_members.size, 'member')}; #{limits}."
  end

  # Size warnings apply in both modes, including after a member leaves.
  def group_status_hint(group, course, leader:)
    warning = group_size_warning(group, course)
    return warning if warning.present?

    'Waiting for your leader to confirm.' if !leader && !group.confirmed?
  end

  # Confirm-dialog bodies. Paragraphs are separated by a blank line;
  # confirm_dialog_controller splits on it (§9.3).
  def delete_confirm_body(group)
    names = group.project_group_members.map { |member| member.user.name.presence || member.user.email_address }.to_sentence
    paras = []
    paras << "These students will have no group: #{names}." if names.present?
    paras << 'Its project will be lost.' if group.project.present?
    paras << "This can't be undone."
    paras.join("\n\n")
  end

  def leave_confirm_body(group, leader:, last:)
    return "You're the last member, so the group will be deleted.\n\nThis can't be undone." if last

    paras = []
    paras << 'Another member becomes the leader.' if leader
    paras << 'The group will become Not confirmed.' if group.confirmed?
    paras << 'You can join another group while formation is open.'
    paras.join("\n\n")
  end

  def remove_confirm_body(group, member_name, manager:)
    unless manager
      return "The group will be reopened and renamed to a Tmp number, and you'll need to confirm it again." if group.confirmed?

      return "#{member_name} will have no group."
    end

    size = group.project_group_members.size
    paras = ["#{group.group_name.presence || 'This group'} goes from #{size} to #{size - 1} members."]
    paras << 'It may become Not confirmed.' if group.confirmed?
    paras.join("\n\n")
  end
end
