---
name: Documentation Style Guide
---

First off, we want to be clear that want your help and contributions to this
documentation.  Please don't become petrified by styling laid out herein
to the point that you don't submit anything. That said, in an effort to keep
final editing to a minimum, here are some guidelines to keep in mind when
writing content:

**Use proper English.** If you need general pointers, there are some excellent
[online](http://www.englishgrammar.org/) [resources](http://www.quickanddirtytips.com/education/grammar).
Keep in mind that Pakyow, Ruby, GitHub, etc. are proper nouns and should be
capitalized. This is also true for the "Web", when referring to the Internet
-- itself a proper noun.

**Keep the narrative consistent.** Refer to the reader in second-person and
Pakyow (framework or team) in third-person.

**Be clear but not elementary.** A beginner should be able to read the docs and 
understand how to use Pakyow, but the concepts should be described for what they 
are and in terms a seasoned developer can relate to.

**Segregate content when it makes sense.** Because Pakyow aims to [open the Web
to more people](/docs/overview/democratic), there will be more than one type of
"beginner" working with it. To this end, the documentation uses specific types
of block quotes for information that is specific for those who are new to Ruby,
or new to programming in general. These blocks should be formatted as follows
(the first line each example may be copied and used literally):
```markdown
> ![Ruby Logo](/img/ruby.png)
>> Details for those new to Ruby...
```
```markdown
> ![Programming Icon](/img/programming.png)
>> Concepts for new programmers...
```

**Include examples as necessary** Like a picture, a good example can be worth a
thousand words. We use [GitHub Flavored Markdown](https://guides.github.com/features/mastering-markdown/#GitHub-flavored-markdown)
within this documentation (look at an existing file for a formatting
example). If the example produces meaningful output, include the output
as a code comment at the end of the example.

**Add references to related concepts as applicable.** This includes
references to other Pakyow docs as well as core Ruby or general
programming concepts. When making a reference be sure to include some
details on how the reference relates to the current topic.

**Keep links usable and accessible.** Avoid using phrases like "click here" for
links. Instead, phrase sentences in such a way that the links are an integral
part of the prose. You can see numerous examples on this page.

**Feel free to break up content.** If content for a particular topic
needs to be broken up, do so with level four headings. See [Routing
Overview](/docs/routing) for an example.

**Denote what is code.** When referencing a symbol (e.g. class,
method) wrap in tildes so it is formatted as `code`. If a particular
class/method is being referenced format as `ClassName#method_name`. If
the context is implied (e.g. the method for defining a GET route), do
not include the class name.

**Keep things tidy.** When providing an example, indent your code, and
generally keep it [nicely styled](https://github.com/bbatsov/ruby-style-guide).
Also, try to limit all line lengths (not just code examples) to a maximum of 80
characters.