---
title: Going from prototype to application
---

The view template you defined in the previous section tell Pakyow everything it needs to build in some basic behavior to your project. To see the app in action, restart the project by pressing `Ctrl-C` to stop the current process and boot into normal development mode:

```
pakyow boot
```

Reload your web browser and this time you'll see just the empty message view and form:

![Pakyow Example: Message List](https://github.com/metabahn/pakyow-marketing-public/raw/master/docs/common/images/hello-example-screen-4.png "Pakyow Example: Message List")

Pakyow understands that no messages are available to present, so it automatically renders the empty version. Helpful, right? Let's explore some other behavior that Pakyow has added for us.

Try using the form to create a new message. You'll find that submitting the form causes a new message to be created, which is then presented in the list:

![Pakyow Example: New Message](https://github.com/metabahn/pakyow-marketing-public/raw/master/docs/common/images/hello-example-screen-5.png "Pakyow Example: New Message")

And that isn't all--there's some other behavior going on behind the scenes. To see it, open two browser windows side by side, then create a message in one of the windows:

![Pakyow Example: Realtime UI](https://github.com/metabahn/pakyow-marketing-public/raw/master/docs/common/images/hello-example-screen-6.gif "Pakyow Example: Realtime UI")

Changes made by one user are instantly available to other users! Pakyow handles everything about these updates for you.

Okay, at this point we have some of the basic behavior of our app working. And all we had to do was define a single html view template to make it happen. The UI could use some more features to make it more user friendly, so we'll take care of that next.
