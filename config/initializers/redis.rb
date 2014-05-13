require 'redis'
params = {:host => ENV["FRONT_DB_HOST"], :port => ENV["FRONT_DB_PORT"],
          :db => ENV["FRONT_DB_NAME"]}
begin
$redis = Redis.new(params)
$redis.auth(ENV["FRONT_DB_PASS"])
rescue Exception=>e
  puts "Unable to connect to Redis: #{e.message}"
end

