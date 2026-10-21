class GithubRepoTracking
    token = Rails.application.credentials.dig(:github, :access_token)

    client = Octokit::Client.new(access_token: token)
end
