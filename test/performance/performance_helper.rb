require 'test_helper'
require 'rails/performance_test_help'

# require 'performance_test_helper'
Rails.env = "performance"
ActiveRecord::Base.establish_connection
