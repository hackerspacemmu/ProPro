# PostHog configuration and Rails auto-instrumentation.
#
# Keep configuration optional so deployments without analytics credentials can
# boot normally. In non-production environments, make a missing setting clear.
posthog_environment_variables = %w[POSTHOG_PROJECT_TOKEN POSTHOG_HOST]

if posthog_environment_variables.all? { |variable| ENV[variable].present? }
  PostHog.init do |config|
    config.api_key = ENV.fetch('POSTHOG_PROJECT_TOKEN', nil)
    config.host = ENV.fetch('POSTHOG_HOST', nil)
  end

  PostHog::Rails.configure do |config|
    config.auto_capture_exceptions = true
    config.report_rescued_exceptions = true
    config.auto_instrument_active_job = true
    config.capture_user_context = true
    config.current_user_method = :current_user
    config.user_id_method = :posthog_distinct_id
  end
elsif !Rails.env.production?
  posthog_environment_variables.each do |variable|
    next if ENV[variable].present?

    Rails.logger.warn(
      "#{variable} variable required by PostHog is missing or un-configured, " \
      'this causes events to be silently missed. This error stops appearing once ' \
      "#{variable} is configured"
    )
  end
end
