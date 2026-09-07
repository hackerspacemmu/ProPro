module HomescreenHelper
  COURSE_THEMES = [
    { color: '#37474F', illustration: 'illustrations/scene_8.svg' },
    { color: '#1A73E8', illustration: 'illustrations/scene_5.svg' },
    { color: '#5F6368', illustration: 'illustrations/scene_6.svg' }
  ].freeze

  def course_theme(index)
    COURSE_THEMES[index % COURSE_THEMES.size]
  end
end
