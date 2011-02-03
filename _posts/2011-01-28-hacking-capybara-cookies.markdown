---
layout: post
categories:
- testing
- bdd
tags:
- remember_me
- cookies
- capybara
- cucumber
truncate_at: 111
---
I once tried and failed to write a cucumber test for a remember-me login feature. I was using Webrat to drive Cucumber interactions at the time and it just didn't seem to provide the access to cookies I needed. So I logged a feature request with Webrat and left the test marked `pending`.

Fast forward to more recent times and I was cukeing login features but using Capybara to drive it. So when it came to the remember-me feature I tried again hoping that Capybara might be more supportive. It wasn't directly, but thanks to this [nifty little gist][gist] I was able to hack in what I needed.

The gist, which has since become [the `show_me_the_cookies` gem][gem], had one flaw: it explicitly deleted a session cookie that it expected to expire by name. To me that seemed like cheating, I wanted to simulate a browser session restart - cookies are deleted because they're past their expiry date or because the don't have an expiry date and so are considered (browsing) 'session' cookies. But it wasn't hard to fix.

For a simple Rack-based scenario the gist basically did the following:

{% highlight gherkin %}
# features/step_definitions/app_websteps.rb
Given /^I close my browser$/ do
  delete_cookie session_cookie_name
end
{% endhighlight %}

and

{% highlight ruby %}
# features/support/cookie_helper.rb
existing_cookie = Rails.application.config.session_options[:key] rescue "_session_id" # the first is Rails3 only

rack_session = Capybara.current_session.driver.current_session.instance_variable_get(:@rack_mock_session)

rack_session.cookie_jar.instance_variable_get(:@cookies).reject! do |existing_cookie|
  existing_cookie.name.downcase == cookie_name
end
{% endhighlight %}

My change is just one line of code:

{% highlight diff %}
# features/support/cookie_helper.rb
existing_cookie = Rails.application.config.session_options[:key] rescue "_session_id" # the first is Rails3 only

rack_session = Capybara.current_session.driver.current_session.instance_variable_get(:@rack_mock_session)

rack_session.cookie_jar.instance_variable_get(:@cookies).reject! do |existing_cookie|
-  existing_cookie.name.downcase == cookie_name
+  # catch session cookies/no expiry (nil) and past expiry (true)
+  existing_cookie.expired? != false
end
{% endhighlight %}

The `!= false` rather than just returning the boolean is because `.expired?` returns `nil` if the cookie doesn't have an expiry date. We want to remove cookies that are expired _and_ cookies with no expiry date because this is what a browser does when you restart it.

## show_me_the_cookies

You should definitely use the `show_me_the_cookies` gem if you need a cookie checking Cucumber step. It's a lot less unsightly than the above chain of eight method calls, it's more likely to be maintained and it offers a bit more:

* a `delete_cookie(name)` method with an implementation like the one from the gist shown above
* as the name suggests a `show_me_the_cookies` method to read the cookies
* Selenium support for both
* Culerity support for both

If you want my `restart_browser` implementation you're going to have to hack it into the gem, monkey patch it, contribute it as a patch or wait for me to submit a patch.

[gist]: https://gist.github.com/484787
[gem]: https://github.com/nruth/show_me_the_cookies