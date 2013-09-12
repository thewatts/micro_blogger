###
# MicroBlogger
# by Brian Winterling and Nathaniel Watts
# Completed 9/12/13
###

require 'jumpstart_auth'
require 'certified'
require 'bitly'
require 'klout'

class MicroBlogger
  attr_reader :client

  def initialize
    puts "Initializing"
    @client = JumpstartAuth.twitter
    Bitly.use_api_version_3
    Klout.api_key = 'xu9ztgnacmjx3bu82warbr3h'
  end

  def run
    puts "Welcome to the JSL Twitter Client!"
    
    input = ""
    while input != "q"
      puts ""
      printf "enter command: "
      input = gets.chomp
      parts = input.split(" ")
      command = parts[0]
      process_command(command, parts)
    end
  end

  def process_command(command, parts)    
    case command
      when "q" then puts "Goodbye!"
      when "s" then puts shorten_url(parts[1])
      when "t" then tweet(parts[1..-1].join(" "))
      when "klout" then klout_score
      when "turl" then tweet_with_url(parts[1..-1])
      when "dm" then dm(parts[1], parts[2..-1].join(" "))
      when "spam" then spam_my_followers(parts[1..-1].join(" "))
      when "elt" then everyones_last_tweet
      when "help" then puts help
    else
      puts "Sorry, I don't know to #{command}"
    end
  end

  def help
    """
    == DESCRIPTION

    MicroBlogger is a terminal Twitter Client,
    built by Brian Winterling and Nathaniel Watts  

    == COMMAND SYNTAX
    command content_1 content_2 (no special characters required)

    == COMMANDS
    t message          :: Tweet out a message, using your Twitter Account!
    dm user message    :: Tweet out a direct message to a specific user
    turl message       :: Tweet out a message and shorten any url with Bit.ly 
    spam message       :: Tweet a direct message to all of your friends
    elt                :: Return a list of your friends' last tweets
    s url              :: Shorten a URL with Bit.ly
    q                  :: Quit this application
    klout              :: Get the Klout scores for all of your friends
    help               :: View help information
    """
  end

  def tweet(message)
    unless message.length > 140 || message.empty?
      @client.update(message)
    else 
      puts message.empty? ? "Error: you need to add a message." : "ERROR: your message is over 140 chars"
    end
  end

  def uri?(string)
    uri = URI.parse(string)
    %w( http https ).include?(uri.scheme)
    rescue URI::BadURIError
      false
    rescue URI::InvalidURIError
      false
  end

  def tweet_with_url(parts)
    parts.collect! { |word| uri?(word) ? shorten_url(word) : word}
    tweet(parts.join(" ")) 
  end

  def dm(target, message)
    puts "Trying to send #{target} this direct message:"
    puts message

    unless target.nil? || message.empty?  
      if get_followers.include?(target)
        direct_message = "d #{target} #{message}"
        tweet(direct_message)
      else
        puts "#{target} hates you... stalker."
      end
    else
      puts "ERROR: Missing user name or message." 
    end 
  end

  def spam_my_followers(message)
    get_followers.each do |follower|
      dm(follower, message)
    end
  end

  def get_followers
    screen_names = @client.followers.collect do |follower| 
      follower.screen_name
    end
  end

  def everyones_last_tweet
    friends = @client.friends
    friends.sort_by! { |friend| friend.screen_name.downcase }
    friends.each do |friend|
      last_tweet = friend.status.text
      timestamp = friend.status.created_at
      print "#{friend.screen_name} just said... "
      print last_tweet
      print " published #{timestamp.strftime('%A, %b %d')}"
      puts "" #Just print a blank line to separate people
    end
  end

  def shorten_url(original_url)
    unless original_url.nil?
      puts "Shortening this URL: #{original_url}"
      @bitly ||= bitly_auth
      @bitly.shorten(original_url).short_url
    else
      puts "ERROR: Need to provide a URL."
    end
  end

  def bitly_auth
    Bitly.new('hungryacademy', 'R_430e9f62250186d2612cca76eee2dbc6')
  end

  def klout_score
    friends = @client.friends.collect { |f| f.screen_name }
    friends.each do |friend|
      begin
        identity = Klout::Identity.find_by_screen_name(friend)
        user = Klout::User.new(identity.id)
        score = user.score.score.to_s
        print "#{friend}'s score: #{score[0..2]}"
      rescue
        print "Sorry, #{friend} doesn't have a Klout account"
      end
      puts "" # Print a blank line to separate each friend
    end
  end

end

blogger = MicroBlogger.new
blogger.run
# blogger.klout_score

