class String
  @@sentihash = {}

  def get_sentiment
    sentiment_total = 0.0

    #tokenize the string
    tokens = self.split
    
    for token in tokens do
      sentiment_value = @@sentihash[token]
      
      if sentiment_value
        
        # for debugging purposes
        #puts "#{token} => #{sentiment_value}"
        
        sentiment_total += sentiment_value
      end
    end

    return sentiment_total

  end
  
  #####################################################################
  # load the specified sentiment file into a hash
  #
  # filename:string -- name of file to load
  # sentihash:hash -- hash to load data into
  # return:hash -- hash with data loaded
  #####################################################################
  def load_senti_file (filename)
    # load the word file
    file = File.new(filename)
    while (line = file.gets)
      parsedline = line.chomp.split("\t")
      sentiscore = parsedline[0]
      text = parsedline[1]
      @@sentihash[text] = sentiscore.to_f
    end
    file.close
  end
  
end	
