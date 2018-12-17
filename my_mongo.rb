require 'mongo'
module MyMongo
	@@db  = nil

	def self.db() @@db; end

	def self.init_db
		@@db = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'ex3')
		throw "No DB" unless @@db
	end
end