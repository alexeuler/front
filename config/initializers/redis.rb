require 'redis'
params = {:host => ENV["FRONT_DB_HOST"], :port => ENV["FRONT_DB_PORT"],
          :db => ENV["FRONT_DB_NAME"]}
$redis = Redis.new(params)
puts params
puts $redis.nil?
#$redis.auth(ENV["FRONT_DB_PASS"])
