---
name: Sending Data
desc: Sending data or a file in a response.
---

The `send` helper is an easy way to send a file or data in the response:

```ruby
send a_file
```

You can pass it a file or a path. You can also pass the file name and the mime type (which is guessed if not provided):

```ruby
send a_file, 'text/xml', 'xml_data.xml'
```

It can also send data (a mime type must be provided in this case):

```ruby
send some_data, 'text/xml'
```
