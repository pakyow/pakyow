---
title: Submitting forms in the background
---

Pakyow includes a `form` component you can use to integrate your forms with other frontend behavior, such as the `navigator` component. This allows form submissions to happen in the background rather than require a full page reload, making your forms more feel more responsive to end users.

You can attach the `form` component to your form using the `ui` attribute like this:

```html
<form binding="message" ui="form">
  ...
</form>
```

Pakyow will take care of including the necessary JavaScript as an [asset pack](doc:frontend/asset-packs).
