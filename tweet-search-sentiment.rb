#############################################################################
# Filename: tweet-search-sentiment.rb
# Copyright: Christopher MacLellan 2010
# Description: This program will ask for a search term, search twitter for it,
#              then perform sentiment analysis of the tweets.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################


require 'rubygems'
require 'json'
require 'net/http'
require 'uri'

#########################################################################
# Function takes a search term and uses the twitter search url to access
# tweets with the given search term. It then converts these tweets from
# JSON into a ruby hash, which is returned.
#
# search_term:string -- term to search twitter for.
# return:hash -- discovered tweets in a hash.
#########################################################################
def get_tweet_hash( search_term, max_results = 2000)

  results_per_page = 2000
  results_per_page = max_results if max_results < 100

  done = false
  page = 1
  num_results = 0

  output = []

  # Encode search term for URL
  search_term = URI.escape(search_term)

  while (not done)

    # Construct the search URL
    search_url = "http://search.twitter.com/search.json?q=#{search_term}&rpp=#{results_per_page}&page=#{page}"
    
    # prints out the url being used... useful for debugging.
    puts search_url
    
    # Request the tweets from twitter search. I got the url for this here: http://dev.twitter.com/pages/using_search
    resp = Net::HTTP.get_response(URI.parse(search_url))
    
    # Parse the data into from JSON into ruby hash.
    data = resp.body
    result = JSON.parse(data)
    
    # Raise exception if there is an error getting data from twitter
    if result.has_key? 'Error'
      raise "Error assessing tweet data"
    end

    if result['results']
      # trims off any amount over the max_results
      if max_results < (output.size + result['results'].size)
        cutpoint = max_results - output.size
        puts cutpoint
        puts result['results'][0,cutpoint]
        for tweet in result['results'][0,cutpoint]
          output.push(tweet)
        end
      else
        for tweet in result['results']
          output.push(tweet)
        end
      end
    end

    page += 1

    if output.size >= max_results or result['results'].size == 0
      done = true
    end    
  end
  return output
end


#####################################################################
# load the specified sentiment file into a hash
#
# filename:string -- name of file to load
# sentihash:hash -- hash to load data into
# return:hash -- hash with data loaded
#####################################################################
def load_senti_file (filename)
  sentihash = {}
  # load the word file
  file = File.new(filename)
  while (line = file.gets)
    parsedline = line.chomp.split("\t")
    sentiscore = parsedline[0]
    text = parsedline[1]
    sentihash[text] = sentiscore.to_f
  end
  file.close

  return sentihash
end


#####################################################################
# Function analyzes the sentiment of a tweet. Very basic. This just
# imports a list of words with sentiment scores from file and uses
# these to perform the analysis.
#
# tweet: string -- string to analyze the sentiment of
# return: int -- 0 negative, 1 means neutral, and 2 means positive
#####################################################################
def analyze_sentiment ( text )
  
  # load the word file (words -> sentiment score)
  sentihash = load_senti_file ('sentiwords.txt')

  # load the symbol file (smiles and ascii symbols -> sentiment score)  
  sentihash.merge!(load_senti_file ('sentislang.txt'))
  
  # tokenize the text
  tokens = text.split

  # Check the sentiment value of each token against the sentihash.
  # Since each word has a positive or negative numeric sentiment value
  # we can just sum the values of all the sentimental words. If it is
  # positive then we say the tweet is positive. If it is negative we 
  # say the tweet is negative.
  sentiment_total = 0.0

  for token in tokens do

    sentiment_value = sentihash[token]

    if sentiment_value

      # for debugging purposes
      #puts "#{token} => #{sentiment_value}"

      sentiment_total += sentiment_value

    end
  end
  
  # threshold for classification
  threshold = 0.0

  # if less then the negative threshold classify negative
  if sentiment_total < (-1 * threshold)
    return 0
  # if greater then the positive threshold classify positive
  elsif sentiment_total > threshold
    return 2
  # otherwise classify as neutral
  else
    puts '---------------------------------------------------------------'
    puts text
    puts '---------------------------------------------------------------'  
  return 1
  end
end


def get_search_term_and_analyze

  # Get search term from user
  print "Enter search term: "
  search_term = gets.chomp
  
  # Get the hash from twitter using the specified search term
  puts "Accessing tweets using search term: #{search_term}..."
  result = get_tweet_hash( search_term, 100)
  
  negative = 0
  neutral = 0
  positive = 0
  
  for tweet in result do
    #  puts "From #{tweet['from_user']}: #{tweet['text']}"
    sentiment = analyze_sentiment( tweet['text'] )
    if sentiment == 0
      negative += 1
    elsif sentiment == 1
      neutral += 1
    elsif sentiment == 2
      positive += 1
    end
  end
  puts "Number of tweets analyzed: #{result.size}"
  puts "Negative tweets: #{negative}"
  puts "Neutral tweets: #{neutral}"
  puts "Positive tweets: #{positive}"
  
  if positive >= negative
    puts "Search term \"#{search_term}\" had a #{((100.0 * positive) / (positive+negative)).round(0)}\% positive sentiment."
  else
    puts "Search term \"#{search_term}\" had a #{((100.0 * negative) / (positive+negative)).round(0)}\% negative sentiment."
  end
  
end

def display_license

puts "Copyright (C) 2010 Christopher MacLellan"
puts "This program comes with ABSOLUTELY NO WARRANTY."
puts "This is free software, and you are welcome to redistribute it"
puts "under certain conditions; outlined in the GNU GPL v3."

end

# Functions to call when program is loaded
display_license
get_search_term_and_analyze
