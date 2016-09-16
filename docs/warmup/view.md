---
name: Front-End Prototype
desc: Building the front-end of your Pakyow project using view-first development.
---

Pakyow encourages a [view-first development
process](/docs/concepts/view-first-development). This process lets us build a
navigable prototype of our project without writing any back-end code. All it
takes is basic knowledge of HTML to create the front-end presentation layer that
you, along with any stakeholders, can use within a web browser.

For reference, here's the front-end that we'll be creating:
<br>
<br>
<blockquote>
<br>
<img src="//pakyow.org/images/warmup-screenshot__1baf0d0ba1f747b87a4f0f5de669b10e.png" width="700" alt="Pakyow Warmup Result">
<br>
<br>
</blockquote>

The "active viewers" and "all time" counters will tell us how many people are
currently on the page and the number of total views, respectively. These values,
along with new comments, will show up as the state changes on the server. And we
won't have to write a single line of JavaScript!

## Markdown Content

The first part of our view is just plaintext content. Let's write this in
Markdown rather than HTML. Pakyow makes this easy with view processors. To
install the view processor for Markdown, open the `Gemfile` file (./warmup/Gemfile) in a text editor and add
this code at the end:

```ruby
gem 'pakyow-markdown'
```

Stop the server with `Ctrl-C` and run `bundle install` at the root of the
project. Then start the server. Now we're ready to write our content. Create a
file named `_content.md` in the `app/views` directory. Write some markdown
content, maybe something like this:

```
# Pakyow &ndash; Realtime Web Framework for Ruby

We designed Pakyow to deliver modern realtime features in a traditional backend-driven
architecture. Build websites and apps your users will love, using simple processes
that will keep you smiling. It's unlike anything you've used before.
```

What we've created is a view partial, written in Markdown. Now we can include
the partial into our page. Open up `app/views/index.html` and replace the content with the
following HTML markup:

```html
<article>
  <!-- @include content -->
</article>
```

Pakyow extends HTML with a few features that make it easy to avoid duplication
and reuse parts of the front-end code throughout a project. The `@include`
directive tells Pakyow to replace the comment with the markup contained in the
`content` partial we created in the previous step. Before doing so, the Markdown
view processor converts the Markdown into HTML code. The result is an HTML
document composed from multiple sources.

Take a minute to restart your server and refresh your browser so you can see the rendered content. Cool,
huh?

## Traffic Counters

Next, we need to define the front-end for our traffic counters. 
Add the following markup between the opening and closing `<article>` tags of `app/views/index.html`, after the
`include` comment:

```html
<div data-scope="stats">
  <span data-prop="active">
    1
  </span>

  <span>
    active viewers
  </span>

  <span data-prop="total" class="margin-l">
    2
  </span>

  <span>
    all time
  </span>
</div>
```

Refresh your browser and you'll see the new counters.

## Comment Form / List

Now let's build the form a user would use to create a comment, along with a
comments list. Create a new `app/views/_comment-form.html` file, add the following
markup:

```html
<form data-scope="comment" class="margin-t">
  <input data-prop="content" placeholder="your comment here...">
  <input type="submit" value="post">
</form>
```

Next, create a new `app/views/_comment-list.html` file and add the following markup:

```html
<p data-scope="comment" data-version="empty">
  no comments :(
</p>

<article data-scope="comment">
  <p data-prop="content">
    Comment Goes Here
  </p>
</article>
```

Finally, include both of these partials in your `index.html` file. The contents of the
file should now look like this:

```html
<article>
  <!-- @include content -->

  <div data-scope="stats">
    <span data-prop="active">
      1
    </span>

    <span>
      active viewers
    </span>

    <span data-prop="total" class="margin-l">
      2
    </span>

    <span>
      all time
    </span>
  </div>

  <!-- @include comment-form -->
  <!-- @include comment-list -->
</article>
```

With your server still running, refresh your browser one more time and you'll see the completed prototype of our
simple web app. Nothing works yet, but it's enough to understand the larger
picture of what we're building.

## Scopes &amp; Props

You'll notice the `data-scope` and `data-prop` attributes on a few of the nodes.
This pattern allows us to label the specific nodes that represent the underlying
data of our app.

You can think of a scope as representing a particular data type and a prop
representing an attribute of a type. In the comment list case, the node
containing `data-scope="comment"` represents data of type `comment`, and the node
with `data-prop="title"` represents the `title` property of a `comment`.

Building this knowledge of state into the view is a fundamental concept in
Pakyow. We'll see why this is so important in the next few sections as we add
the back-end code to power our presentation layer.

## Front-End Wrapup

That's all there is to building a front-end prototype in Pakyow! It only took a
few minutes, and we only had to write a bit of HTML and Markdown. Next, we'll
add the back-end code. And here's a spoiler: we won't have to touch our views
again!
