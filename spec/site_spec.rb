
APP_ROOT = File.realpath('..', File.dirname(__FILE__)) # /Users/jim/Coding/jamesferguson.github.com

PROD_DOMAIN = "j-ferguson.com"
TEST_DOMAIN = "localhost:4000"
ALT_DOMAINS = [
  "j-ferguson.net",
  "j-ferguson.org",
  "j-ferguson.info",
  "jamesferguson.github.com"
]

describe "a generic static site" do
  
  it "uses valid, resolvable links" do
    # pending
    spider_results = `wget -r --spider -l inf -p http://#{TEST_DOMAIN} 2>&1`
    status = $?.exitstatus
    
    errors = spider_results.scan(/(http:\/\/.*)\n.*\nHTTP request sent, awaiting response\.\.\. (?!200 OK)(.*)\n/).map { |result| result.join(" fails with ") }
    # the first error will always be robots.txt - remove it w 'arr[slice]', extra '[* ]' ensures we don't get nil back
    
    [*errors[1..-1]].should == []
    $?.should == 0
  end

  it "uses valid external links" do
    ext_link_pattern = <<-RGX
    (?x)                      # ignore non-escaped whitespace
    <[^>]*                    # we're looking inside tags
    [^>a-zA-Z]                # last char before the link won't be a letter or a close tag
    \\K                       # don't include the above in the match; makes the above a lookbehind, but more efficient
    \\w+://                   # match all chars of protocol, :// is how we know we have a link
    (?\\x21www.w3.org/)       # negative lookahead to exclude irrelevant and slow w3 urls; x21 is chr code for bang
    [^\"\\'\\ />]*            # keep matching until dquo, squo, space, slash or close tag
    RGX
    ext_link_pattern.gsub!(/^\s*|\s*#.*\n/, '') # (?x) must be at index 0
    
    cmd = <<-CMD
    grep -roPhe $'#{ext_link_pattern}' #{APP_ROOT}/_site |  # get all external (http://...) links
    sed s/#{PROD_DOMAIN}/#{TEST_DOMAIN}/ |                  # sub test for prod (used on rss page) as new pages won't exist yet
    sort -f |                                               # case-insensitive sort in order to...
    uniq -i |                                               # remove dupes
    wget --spider --no-check-certificate -i - 2>&1      # get pages (headers only)
    CMD
    cmd.gsub!(/^\s*/, '').gsub!(/\|?\s*#.*\n/, '| ').chomp!('| ')
    
    ext_spider_res = `#{cmd}`
    status = $?.exitstatus
    # sub out all expected output
    ext_spider_res.gsub!(/(?x)
      Spider\ mode\ enabled\.\ Check\ if\ remote\ file\ exists.\n
      | --\d{4,4}-\d\d-\d\d\ \d\d:\d\d:\d\d--\ \ 
      | ^Resolving.*([12]?\d?\d\.){3,3}[12]?\d?\d\n
      | ^Connecting.*\.\.\.\ connected\.\n|HTTP\ request\ sent,\ awaiting\ response\.\.\.\ 200\ OK\n
      | ^Length:.*\nRemote\ file\ exists\ and\ could\ contain\ further\ links\,\nbut\ recursion\ is\ disabled\ --\ not\ retrieving\.\n
      | ^WARNING:.*\n
      | \s*Self-signed\ certificate.*\n
      | ^\n    
    /, '')
    # sub out urls not followed by unexpected output
    ext_spider_res = ext_spider_res.gsub!(/\w+:\/\/.*\n(?=\w+:\/\/|$)/, '').split(/\n/)
    
    ext_spider_res.should == []
    status.should == 0
  end

  it "doesn't contain known templating errors" do
    errors_rgx = <<-RGX
    (?x)                                                                            # must be at index 0
    Included\ file\ &#8216;.*?&#8217;\ not\ found\ in\ <em>includes\ directory</em> # bad include 
    | (\{%|%\})                                                                     # broken statement
    | (\{\{|\}\})                                                                   # broken insert var
    | Liquid\ (?:syntax\ )?error:                                                   # Misc bad syntax
    | This\ liquid\ context                                                         # Stack too deep
    RGX
    errors_rgx.gsub!(/^\s*|\s*#.*\n/, '')
    
    cmd = <<-CMD
    grep -re $'#{errors_rgx}' #{APP_ROOT}/_site
    CMD
    
    errors = `#{cmd}`.split("\n")
    status = $?.exitstatus
    
    errors.should == []
    status.should == 1 # grep exits with 1 if no matches found.
  end
  
  it "correctly redirects alternate domains to itself" do
    alt_lookup_res = `wget --spider -nv #{ALT_DOMAINS.join(' ')} 2>&1`
    status = $?.exitstatus
    
    errors = alt_lookup_res.scan(/^.*(?<! 200 OK)$/)
    
    errors.should == []
    status.should == 0
  end
  
  it "produces no maruku errors" do
    maruku_output = `jekyll --no-server --no-auto #{APP_ROOT} #{APP_ROOT}/_site 2>&1`
    status = $?.exitstatus

    errors = maruku_output.scan(/(?:\+\-+\n\| )([^\n]+)(?:\n\| )([^\n]+)/).map { |err| err.join("\n") }
    
    errors.should == []
    status.should == 0
  end
  
end