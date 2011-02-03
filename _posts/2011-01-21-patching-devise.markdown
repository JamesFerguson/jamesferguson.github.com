---
layout: post
title: Patching Devise
category: rails
tags:
- foss
- security
- devise
- cookie
truncate_at: 67
---

I submitted my first patch to an open source Ruby project the other day. 

I got interested in the [HttpOnly][] flag on cookies and decided to check up on which cookies set it. After a little more fiddling than should have really been required (see the side note) I was able to establish that the Rails session cookie is `HttpOnly` by default (since about 2.2 or 2.3).

<div class="sidenote" markdown="1">
#### Checking the HttpOnly flag in Chrome

1. Switch to the tab with the page the cookie is set for.
1. Open Tools > Developer > Developer Tools (Alt + Cmd + I)
1. Switch to the Storage tab
1. Click the item under 'Cookies' (localhost in my case).

Look at the 'HTTP' column. There'll be a tick if the cookie is `HttpOnly`. For example the rails session cookie, called \_session\_id by default, should have one.
</div>

However, I noticed Devise's `remember_<scope>_token` cookie used for the remember-me feature wasn't. Since a remember-me cookie is essentially a super session cookie, and Rails' session cookie is `HttpOnly` by default, I figured Devise's default needed to change.

[The test][test] ended up being a single line adding an assertion to an existing test:

<script type="text/javascript" src="https://gist.github.com/805027.js?file=56e55726c8cdc920f48c97187c7fe8b9d2baddc6.diff">&nbsp;</script>

It asserts that the server response after submitting a remember-me login will include a 'Set-Cookie' header that has a line that begins `remember_user_token` and ends `HttpOnly`.

[The change][change] itself was one line:

<script type="text/javascript" src="https://gist.github.com/805027.js?file=5f98caca1b192c30f1f3774a365a66f786958cae.diff">&nbsp;</script>

It just passes through an additional option.

I put these changes in a pull-request and sent it along to the Devise guys and Jose Valim very kindly merged it into `master`. Amazingly he appears to have found time to do that on Christmas Day (unless GitHub's handling of timezones is fooling me).

### HttpOnly

Modern browsers support an `HttpOnly` flag for cookies that tells the browser to lock the cookie against access from Javascript. If Javascript can't access your cookie, then attackers can't exploit [XSS vulnerabilities][xss] to harvest your session cookie and impersonate you to the site. 

Such session harvesting is the most flexible way to use an XSS vulnerability[^xss] to escalate privileges. But even with an `HttpOnly` session cookie a site with an XSS flaw would still be vulnerable to a '[just do it][]' attack. That is, rather than embedding a script to harvest the user's session and then doing something dastardly on his own machine, the attacker could simply embed a different script that directly does something dastardly and have it run on the user's own machine.

However a 'just do it' attack is probably a little more constrained because the malicious script has to get by both the site's (admittedly already at least partially faulty) input filtering as well as any browser limitations on Javascript. It's also a more complex script than session harvesting and has to be run blind.

[HttpOnly]: http://en.wikipedia.org/wiki/HttpOnly#Cross-site_scripting_.E2.80.93_cookie_theft
[just do it]: http://en.wikipedia.org/wiki/HttpOnly#Cross-site_scripting_.E2.80.93_just_do_it
[test]: https://github.com/JamesFerguson/devise/blob/56e55726c8cdc920f48c97187c7fe8b9d2baddc6/test/integration/rememberable_test.rb "See the whole file"
[change]: https://github.com/JamesFerguson/devise/blob/5f98caca1b192c30f1f3774a365a66f786958cae/lib/devise/hooks/rememberable.rb "See the whole file"
[xss]: http://en.wikipedia.org/wiki/Cross-site_scripting

*[XSS]: Cross-site scripting