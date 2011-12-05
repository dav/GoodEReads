$: << './goodreads/lib'

require 'goodreads'
require 'pp'

config = YAML.load_file( "config.yml" )
Goodreads.configure(config['goodreads']['key'])

client = Goodreads::Client.new

def puts_attrs(mash, *attrs)
  attrs.each do |attr|
    val = mash.send(attr)
    puts "  #{attr}: #{val}" unless val.nil?
  end
end

begin
  response = client.shelf_reviews(config['goodreads']['user_id'], 'to-read', :sort => 'date_added', :order => 'd', :per_page => 100)
  review_arr = response["review"]
  rating_accumulator = 0
  review_arr.each do |review|
    book = review.book
    
    title = book.title.strip
    rating = book.average_rating
    rating_accumulator += rating.to_f
    
    puts "-- #{title}"
    puts_attrs book, :isbn, :isbn13, :average_rating
  end
  puts "\nAverage rating: #{rating_accumulator / review_arr.size}"
rescue Goodreads::NotFound => nf
  puts "404 bitch"
end

__END__

shelf request API:

# Get the books on a members shelf. Customize the feed with the below variables. Viewing members with profiles who have set them as visible to members only or just their friends requires using OAuth. 
# URL: http://www.goodreads.com/review/list.xml?v=2    (sample url) 
# HTTP method: GET 
# Parameters: 
# v: 2
# page: 1-N (optional)
# shelf: read, currently-reading, to-read, etc. (optional)
# sort: available_for_swap, position, num_pages, votes, recommender, rating, shelves, format, avg_rating, date_pub, isbn, comments, author, title, notes, cover, isbn13, review, date_pub_edition, condition, asin, date_started, owned, random, date_read, year_pub, read_count, date_added, date_purchased, num_ratings, purchase_location, date_updated (optional)
# per_page: 1-200 (optional)
# order: a, d (optional)
# id: Goodreads id of the user
# key: Developer key (required).
# search[query]: query text to match against member's books (optional)


Example review response:

{"id"=>"28636500",
 "book"=>
  {"id"=>2177768,
   "isbn"=>"1557502196",
   "isbn13"=>"9781557502193",
   "text_reviews_count"=>1,
   "title"=>
    "\n    The Will to Win: The Life of General James A. Van Fleet\n  ",
   "image_url"=>"http://www.goodreads.com/images/nocover-111x148.jpg",
   "small_image_url"=>"http://www.goodreads.com/images/nocover-60x80.jpg",
   "link"=>"http://www.goodreads.com/book/show/2177768.The_Will_to_Win",
   "num_pages"=>"419",
   "average_rating"=>"4.50",
   "ratings_count"=>"2",
   "description"=>
    "\n    Called the Army's &quot;greatest combat general&quot; by President Truman, James Van Fleet led American and allied forces to battlefield victory during a career that spanned World War I and the Cold War. In this biography, a military historian who once commanded a rifle company under Van Fleet in Korea tells the legendary leader's unique story and draws parallels to the U.S. Army's history of diverse challenges met in the twentieth century.   <p>Defining the root of Van Fleet's success as devotion to his men and dedication to rigorous field training and mental conditioning, Paul Braim describes Van Fleet's ability to inspire his men with the will to win through two world wars and in the limited wars that followed. He chronicles Van Fleet's command of III Corps in its drive into the heart of Nazi Germany in World War II and his training of allied soldiers in the Cold Wars, including his development of the Greek National Army into a fighting force capable of driving off a strong communist insurgency. He tells how as commander of the Eighth Army in Korea Van Fleet applied his winning tactics so successfully within the constraints of the limited war that the South Korean Army was able to assume a major fighting role. Finally, he explains that Van Fleet was one of few senior military leaders to argue for training the Vietnamese instead of committing U.S. combat forces in Vietnam. This tribute to an outstanding American--a poor boy from rural Florida who rose to the rank of four-star general--will fascinate everyone who enjoys reading biographies and those who like military history. It is presented in cooperation with the Association of the U.S. Army.</p>\n  ",
   "authors"=>
    {"author"=>
      {"id"=>"988216",
       "name"=>"Paul F. Braim",
       "image_url"=>
        "http://www.goodreads.com/images/nophoto/nophoto-U-200x266.jpg",
       "small_image_url"=>
        "http://www.goodreads.com/images/nophoto/nophoto-U-50x66.jpg",
       "link"=>"http://www.goodreads.com/author/show/988216.Paul_F_Braim",
       "average_rating"=>"4.00",
       "ratings_count"=>"5",
       "text_reviews_count"=>"1"}},
   "published"=>"2001"},
 "rating"=>"0",
 "votes"=>"0",
 "spoiler_flag"=>"false",
 "spoilers_state"=>"none",
 "shelves"=>{"shelf"=>{"name"=>"to-read"}},
 "recommended_for"=>"",
 "recommended_by"=>"",
 "started_at"=>nil,
 "read_at"=>nil,
 "date_added"=>"Tue Jul 29 12:06:21 -0700 2008",
 "date_updated"=>"Tue Jul 29 12:06:21 -0700 2008",
 "read_count"=>nil,
 "body"=>"\n          \n      ",
 "comments_count"=>"0",
 "url"=>"http://www.goodreads.com/review/show/28636500",
 "link"=>"http://www.goodreads.com/review/show/28636500",
 "owned"=>"0"}
