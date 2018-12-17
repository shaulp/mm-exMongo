require_relative 'my_mongo'
require_relative 'concordance_builder'

begin
	puts "========= EX3 Starting ========"

	dirname = ARGV[0]
	MyMongo.init_db
	ConcordanceBuilder.bulid dirname

	puts "========= EX3 ended ==========="

rescue => e
	puts e.message
end