require 'open4'

APP_ROOT = File.realpath('..', File.dirname(__FILE__)) # /Users/jim/Coding/jamesferguson.github.com

PROD_DOMAIN = "j-ferguson.com"
TEST_DOMAIN = "localhost:4000"

describe "a generic static site" do
  
  it "uses valid, resolvable links" do
    # pending
    spider_results = `wget -r --spider -l inf -p http://#{TEST_DOMAIN} 2>&1`
    errors = spider_results.scan(/(http:\/\/.*)\n.*\nHTTP request sent, awaiting response\.\.\. (?!200 OK)(.*)\n/).map { |result| result.join(" fails with ") }
    # the first error will always be robots.txt - remove it w 'arr[slice]', extra '[* ]' ensures we don't get nil back
    [*errors[1..-1]].should == []
    $?.to_i.should == 0
  end

  it "uses valid external links" do
        @ext_spider_res = `<<-CMD
    grep -roPhe $'<[^>]*[^>a-zA-Z]\\K\\w+://(?\\x21www.w3.org/)[^"\\']*' #{APP_ROOT}/_site | sed s/#{PROD_DOMAIN}/#{TEST_DOMAIN}/ | sort | uniq -i | wget --spider --no-check-certificate -nv -i - 2>&1 | grep -ve "200 OK|WARNING|Self-signed certificate"
        CMD`
        status = $? #Open4::popen4(cmd) do |pid, stdin_io, stdout_io, stderr_io|
        #   @ext_spider_res = stdout_io.read.split("\n")
        # end
        puts @ext_spider_res.inspect + "xyz"
        @ext_spider_res.should == []
        status.to_i.should == 0

#     cmd = <<-CMD
# grep -roPhe $'<[^>]*[^>a-zA-Z]\\K\\w+://(?\\x21www.w3.org/)[^"\\']*' #{APP_ROOT}/_site | sed s/#{PROD_DOMAIN}/#{TEST_DOMAIN}/ | sort | uniq -i | wget --spider --no-check-certificate -nv -i - 2>&1 | grep -ve "200 OK|WARNING|Self-signed certificate"
#     CMD
#     status = Open4::popen4(cmd) do |pid, stdin_io, stdout_io, stderr_io|
#       @ext_spider_res = stdout_io.read.split("\n")
#     end
#     puts @ext_spider_res.inspect + "xyz"
#     @ext_spider_res.should == []
#     status.to_i.should == 0
  end

  it "doesn't contain known templating errors" do
    cmd = <<-CMD
    
    CMD
    pending
    # Included file &#8216;.*?&#8217; not found in <em>includes directory</em> # Jekyll
    # (\{%|%\})
    # (\{\{|\}\})
    # Liquid (?:syntax )?error:
    # This liquid context
    
  end
  
end