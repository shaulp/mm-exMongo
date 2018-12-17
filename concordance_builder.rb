require 'set'
require_relative 'my_mongo'

module ConcordanceBuilder

	class Term
		attr_reader :standard
		attr_reader :count

		def Term.clean word
			return nil unless word && word.is_a?(String)
			
			word = word[0..-3] if word.end_with?("'s")
			word.downcase!
			# ... more cleaning
			return word
		end

		def initialize word
			@standard = word
			@count = 0
			@variations = Set.new
		end

		def add variation = nil
			@count += 1
			@variations << variation if variation && variation != @standard
		end

		def variations
			@variations.to_a
		end

		def <=> other
			return -1 if self.count < other.count
			return 1 if self.count > other.count

			return 1 if self.standard < other.standard
			return -1 if self.standard > other.standard
			return 0
		end

	end # class Term

	class Location
		attr_accessor :filename
		attr_accessor :position
		def initialize filename, line, index
			@filename = filename
			@position = {line:line, index:index}
		end
		def to_h
			{filename:@filename, position:@position}
		end
	end # class Location

	module Concordance
		def self.add_term word, location
			loc = location.to_h
			term = MyMongo.db[:concordance].find({word:word}).first
			if term
				term[:locations] << loc
				term[:count] += 1
				MyMongo.db[:concordance].update_one({_id:term[:_id]},term)
			else
				term = {word: word, locations:[loc], count: 1}
				MyMongo.db[:concordance].insert_one(term)
			end

		end

		def self.is_known_variation word
			# ...
			# ...
			word
		end

		def self.count
			@@terms.count
		end
	end # module Concordance

	def self.read_and_process_file fn
		puts "Processing #{fn}..."
		num_lines = 0
		num_words = 0

		pushover_word = nil
		File.foreach(fn).each do |line|
			num_lines += 1
			terms = line.chomp.split(/[\s,.;\(\)\[\]\{\}\+\\\$\*\?]/).delete_if(&:empty?).map {|w| Term.clean w}.compact
			next if terms.empty?

			num_words += terms.count
			if pushover_word
				num_words -= 1
				terms[0] = pushover_word+terms[0]
				puts " -- and now merged into #{terms[0]}"
			end
			pushover_word = nil

			terms[0..-2].each_with_index do |word,i|
				Concordance.add_term word, Location.new(fn, num_lines, i+1)
			end

			## Special treatment for last word in line
			if terms.last.end_with?('-')
				pushover_word = terms.last[0..-2]
				puts " -- Pushing #{terms.last} over to next line"
			else
				Concordance.add_term terms.last, Location.new(fn, num_lines, terms.count)
			end
			return if num_lines > 3
		end
		puts "... done. #{num_lines} line and #{num_words} words read."
	end

	def self.bulid dirname
		puts "Looking in #{dirname}"
		Dir.glob("#{dirname}/*.txt") do |fn|
		  next if fn == '.' or fn == '..'
		  read_and_process_file fn
		end

		puts "Total of #{MyMongo.db[:concordance].find().count} terms found." 
			
	rescue StandardError => e
		puts "Error in ConcordanceBuilder: #{e.message}"
		puts e.backtrace[0]
		puts e.backtrace[1]
	end
end # module
