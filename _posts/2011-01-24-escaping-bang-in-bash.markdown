---
layout: post
category: scripting
title: Escaping bang in Bash
---
Bash. A venerable language; ugly... like, I mean:

{% highlight text %}
if [ -a file.txt ]; then
  echo "found file.txt";
fi
{% endhighlight %}

[ugly](http://www.gnu.org/software/bash/manual/bashref.html#Bash-Conditional-Expressions)! - but workable... or so I thought.

Try this little exercise before you read further: try to get `echo "Don't break on me!"` to produce `Don't break me!` in Bash, that is without errors, extraneous backspaces or lost apostrophes or bangs.

Losing some hair?

Ok, first things first, ! has special meaning. It "starts a history substitution, except when followed by a space, tab, newline, equals or left bracket (when the extglob shell option is enabled, which it is by default in OS X)."[^1] 

So `!echo` will search for the last command in history that begins with `echo` and substitute the whole line. If there's no matching command it'll give you the wonderfully cryptic `-bash: !echo: event not found`.

I can see [history expansion](http://www.gnu.org/software/bash/manual/bashref.html#History-Interaction) is very powerful, but I've never seen anyone use it and I have serious doubts about it being useful in practice.

From there these are the decisions Bash made that stymie you in this scenario:

1. __Bang is expanded within double quotes:__ unlike [braces][], [tildes][], or [file globs][], apparently it's essential to be able to pull whole commands out of history and expand them within double quotes without first dropping it into a variable.
1. __Single quote cannot be escaped/used within single quotes:__ in fact nothing can be escaped within single quotes. __Read: single quotes are crippled.__
1. __Bash even expands !"__: the most common place you'll hit this whole problem is trying to pass a string that ends in !, even the humble `echo "Hello world!"` program will crap itself. It sees !" as a history search for a command beginning with ". Why would anyone begin a command with double quote? This is why:
    {% highlight bash %}
$ cd /bin
$ ln -s echo "multi-word named echo"
$ "multi-word named echo" "Hello World"{% endhighlight %}Seem a little absurd? No, I've never seen a command with spaces in the filename either. It is, however, legal Bash. Of course other shells ignore `!"` even though they're infuriating all those users of multi-word commands out there.
1. __There's a less-broken kind of single quotes... but they're still broken:__ with a `$'<msg>'` syntax, ANSI-C quotes do what single quotes should and allow escaping, e.g. `echo $'You can\'t do this in single quotes'`. But they're broken in the same way double quotes are...
1. __Escaping bang is horribly broken in ANSI-C and double quotes:__ I'll let the Bash docs speak for themselves:
  >   \[Within double or ANSI-C quotes\] If enabled, history expansion will be performed unless an '!' appearing in double quotes is escaped using a backslash. The backslash preceding the '!' is not removed.
  Why isn't the backslash removed? Presumably because that would be sane.

## Solutions

There are two solutions:

1. __ANSI-C quotes with character codes:__ you'd have no variable or command substitution, but if that's not a problem it'd work. Specifically:
 {% highlight bash %}
 echo $'Don\'t break on me\x21'
 {% endhighlight %}
  __Verdict__: 4 characters where 2 should do, little used quote style, and cryptic escape code to boot, but it works.
1. __Take advantage of Bash's implicit concatenation:__ when Bash parses a command it splits the line on (unquoted) whitespace and turns each item into an argument. Specifically if two strings appear together with no whitespace inbetween they are implicitly concatenated. This means you can do:
 {% highlight bash %}
 echo "Don't break on me"'!'
 {% endhighlight %}
  __Verdict__: 2 extra characters, a little known quirk about Bash concatenation, and you have to juggle two sets of escape code expansion (three if you're making a system from another language), but the output is obvious from reading it and it works.

## In practice

In practice I came across this while calling grep from Ruby and that introduces an extra layer of escaping.

It's a complex regex, including a negative lookahead[^2]: the syntax is `(?!not this pattern)` you'll have to double escape everything. It'll be expanded once when the string is read from source and again when passed to the system call.

The obvious choices look like this:

{% highlight ruby %}
# option 1: ANSI-C quotes.
rgx = <<-RGX
(?x)                      # ignore non-escaped whitespace
<[^>]*                    # we're looking inside tags
[^>a-zA-Z]                # last char before the link won't be a letter or a close tag
\\K                       # don't include the above in the match; makes the above a lookbehind, but more efficient
\\w+://                   # match all chars of protocol, :// is how we know we have a link
(?\\x21www.w3.org/)       # negative lookahead to exclude irrelevant and slow w3 urls; x21 is chr code for bang
[^\"\\'\\ >]*            # keep matching until dquo, squo, space or close tag
RGX
`grep -Pe $'#{rgx}' file` # use Perl style regexes

# option 2: Implicit concat with single quoted !.
rgx = <<-RGX
(?x)                      # ignore non-escaped whitespace
<[^>]*                    # we're looking inside tags
[^>a-zA-Z]                # last char before the link won't be a letter or a close tag
\\K                       # don't include the above in the match; makes the above a lookbehind, but more efficient
\\w+://                   # match all chars of protocol, :// is how we know we have a link
(?\"'!'\"www.w3.org/)       # negative lookahead to exclude irrelevant and slow w3 urls
[^\\\"'\\ >]*            # keep matching until dquo, squo, space or close tag
RGX
`grep -Pe "#{rgx}" file` # use Perl style regexes
{% endhighlight %}

The double escaping is because Ruby will expand escapes and Bash will do it again. The heredoc just makes explicit the fact that backticks expand escape codes in the same way as double quotes. The contents of substituted variables are not expanded again so there is no need for triple escaping.

But there is a better way, the percent style single quote format removes the need for double escaping, it looks like this:

{% highlight ruby %}
# option 2: Implicit concat with single quoted !.
rgx = %q{(?x)           # ignore non-escaped whitespace, must start at index 0 of string
<[^>]*                  # we're looking inside tags
[^>a-zA-Z]              # last char before the link won't be a letter or a close tag
\K                      # don't include the above in the match; makes the above a lookbehind, but more efficient
\w+://                  # match all chars of protocol, :// is how we know we have a link
(?"'!'"www.w3.org/)     # negative lookahead to exclude irrelevant and slow w3 urls
[^\"\'\ >]*             # keep matching until dquo, squo, space or close tag
}
`grep -Pe "#{rgx}" file` # use Perl style regexes
{% endhighlight %}

which is marginally closer to readable. Of course if you use `{}` in the regex you'll need to pick a different delimiter (e.g. `%q|regex|` or `%q^regex^` or something).

## Conclusion

To be honest, my conclusion is to use the following snippet of Ruby (found [here][snippet]):

{% highlight ruby %}
Dir['**/*.php'].each do |path|
  File.open( path ) do |f|
    f.grep( /search_string/ ) do |line|
      puts path, ':', line
    end
  end
end
{% endhighlight %}

to replace grep and then (in my case) pass the results into wget. That way I get native Ruby regexes, which require enough escaping as it is without passing them into another language to be escaped again. . . and especially not Bash!

[braces]: http://www.gnu.org/software/bash/manual/bashref.html#Brace-Expansion
[tildes]: http://www.gnu.org/software/bash/manual/bashref.html#Tilde-Expansion
[file_globs]: http://www.gnu.org/software/bash/manual/bashref.html#Filename-Expansion
[snippet]: http://kennethhunt.com/archives/001331.html

[^1]: loosely quoting the Bash documentation
[^2]: a negative look-ahead tells the pattern matcher not to continue matching if the characters ahead match those in the capture group, but it does not capture the characters looked at or advance the matchers' pointer. So `"foobaz".scan /foo(?!bar)/` returns `["foo"]` but `"foobar".scan /foo(?!bar)/` returns `[]`. There are positive look-aheads and negative and positive look-behinds as well. If you've used `\b` to match word boundaries you've used a positive lookahead.