---
layout: post
categories:
- testing
- bdd
tags:
- cucumber
- the\_checklist\_manifesto
- best_practices
---
Since getting into BDD and Cucumber I've been getting mixed messages about what should be covered by features and what shouldn't. 

Firstly, as with TDD, I'm told that BDD tests are so important they should be written before you touch the code. But then, conflictingly, I've had a number of people suggest that if a feature is mostly provided by a gem or plugin or Rails itself then you needn't test it.

Now, granted, for TDD/Rspec I tend to agree - it'd be futile to go spec-ing every magic method provided by Rails or Devise.

In the case of BDD/Cucumber however, I disagree.

Some brief reasons first:

1. You've made a customer provide a story and told them it'll become a test. When you misconfigure the plugin and fail acceptance testing you don't just have rejected story, you have a customer wondering why they wrote the story.

2. BDD testing makes you think about trivialities like email copy and flash messages which are easy to forget to customise. Some customers may not care but for the rest you'll look slapdash for ignoring their stories.

3. I've seen it catch bugs. I was implementing Devise and went to the trouble of cuke-ing the Resend Confirmation page and I was surprised to see it fail with a big ugly broken template message. A bad Find/Replace had introduced a wayward space into the path of a partial.

But there's a broader point here...

### Stick to the Checklist

[The Checklist Manifesto][checklist] is a book by Atul Gawande about how to reduce errors caused by simple oversights, particularly in highly complex professions. I know you're thinking this could just be another Seth-Godin-esque mishmash of oversimplified advice backed by nothing but charming anecdotes and overconfident rhetoric, except that Gawande actually backs his suggestions up with the results of applying it in a number of mission-critical hospital settings.

Now I haven't actually read the book yet, but the idea is pretty obvious from the title, professionals dealing with significant complexity need checklists to avoid silly mistakes. To quote a reviewer:

> \[Gawande\] walks us through a series of examples from medicine showing how the routine tasks of surgeons have now become so incredibly complicated that mistakes ... are virtually inevitable: it's just too easy for an otherwise competent doctor to miss a step, or forget to ask a key question... Gawande then visits with pilots and the people who build skyscrapers and comes back with a solution. Experts need checklists--literally--written guides that walk them through the key steps in any complex procedure. In the last section of the book, Gawande shows how his research team has taken this idea, developed a safe surgery checklist, and applied it around the world, with staggering success.

Gawande's idea isn't new, in fact it's exactly what BDD is about, though BDD adds automated testing[^1]. Notice though, that it's not what TDD is about. Specs test "Does this work as I expect it to?" but Cucumber features test "Have I provided all the functionality the customer asked for?".

The first question can often be assumed to be true if the function is provided by third-party code. There will often be very little complexity in the inputs and outputs of a single function and good third-party code will have its own tests. However, when testing a feature/story you're not just testing multiple functions (which, I admit, may well all reside in third party code and be tested there), you're checking off customer expectations against the implementation provided by that third party code. 

So, unless the third-party code was custom built for your customer, you can't expect it meets their expectations.

[checklist]: http://www.amazon.com/Checklist-Manifesto-How-Things-Right/dp/0805091742 "The Checklist Manifesto on Amazon"

[^1]: Gawande apparently argues that checklists need to be applied by someone other than ourselves and for developers it makes sense to have that someone be the computer.