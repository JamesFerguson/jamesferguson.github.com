---
layout: post
title: The Obligatory Jekyll Post
category: rspec
tags:
- jekyll
- wget
- validation
truncate_at: 87
---

I remember when I was setting up this blog noticing the number of people
who'd just switched to Jekyll and immediately produced a post about some
neat trick they'd found in the process.

Well, I had something up my sleeve for a Jekyll-related post after I
started this blog, but I'm only just posting it now.

### Specs for any Jekyll site

I wrote up some nice generic specs for a Jekyll blog. You can see [the
source](https://github.com/JamesFerguson/jamesferguson.github.com/blob/master/spec/site_spec.rb) in this blog's repo.

The specs check that your site:

1. __uses valid, resolvable (internal) links:__ uses wget to spider the
   site itself and checks the exit code as well as scanning the output
for error messages and expecting there to be none.
1. __uses valid external links:__ recursively grep the \_site folder for
   links to anywhere other than the local site (removing duplicate
links) then wget the page headers, remove all the expected output (200
OK's, irrelevant chatter and known warnings) and expect the result to be
blank.
1. __doesn't contain known templating errors:__ unfortunately the liquid
   templating engine sometimes spews errors into the generated html
rather than outputting them on the comand line. This greps the \_site
directory for known patterns of template errors and expects the
resulting array to be empty.
1. __correctly redirects alternate doamins to itself:__ because we here
   at the j-ferguson global headquarters take our branding extremely
seriously, it's necessary to check that all the alternate domains we 
<del>were stupid enough to buy</del> own correctly resolve to
j-ferguson.com. We do this by doing a wget spider of the domains with
reduced output and expecting to only see 200 OK's of j-ferguson.com
output.
1. __produces no maruku errors:__ in case you're not paying attention to
   the output of `jekyll --auto` or something this spec generates the
site once and checks for any errors output.
1. __contains valid html:__ this spec depends on tidy_ffi. It reads all
   the html under \_site/, runs it through tidy_ffi, collects the errors
and expects the resulting array to be empty.

Running these just now caught a minor html validation oversight and also
alerted me to the fact that the [git-achievements](https://github.com/icefox/git-achievements) 
plugin I use was producing my [git-achievments](/git-achievements/) page 
with lots of now defunct links to the old kernel.org git man pages. So 
of course I dutifully filed [an issue](https://github.com/icefox/git-achievements/issues/53) 
with the project.

It was putting together some of the chunky regexes in this spec the led 
to the other [post on escaping bang in bash](/scripting/escaping-bang-in-bash/) 
you may recognize the regex at the end from the 'uses valid external
links' spec.

## pending

Finally, you might have also noticed a couple of unfinished specs.
Consider them exercises for the reader ;)

1. __offers a valid rss feed:__ pass the site's atom feed url into 
`http://feedvalidator.org/check.cgi?url=\<feed url\>` and parse the output
for errors.
1. __uses valid js:__ somehow use [jslint on rails](https://github.com/psionides/jslint_on_rails)
 to syntax check any js in the site.
