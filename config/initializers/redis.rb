require 'redis'
$redis = Redis.new(:host => ENV["FRONT_DB_HOST"], :port => ENV["FRONT_DB_PORT"],
                   :db => ENV["FRONT_DB_NAME"])
$redis.auth(ENV["FRONT_DB_PASS"])