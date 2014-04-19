require_relative 'performance_helper'
include Warden::Test::Helpers
Warden.test_mode!


class HomepageTest < ActionDispatch::PerformanceTest
  # Refer to the documentation for all available options
  # self.profile_options = { runs: 5, metrics: [:wall_time, :memory],
  #                          output: 'tmp/performance', formats: [:flat] }

  def setup
    user = User.first
    login_as(user, :scope => :user)
  end

  test "homepage" do
    get '/posts'
  end
end
