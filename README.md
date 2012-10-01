# Trackbook

Passbook Package tracking

![](http://i.imgur.com/4LlO6.png)

## Usage

Head over to
[https://trackbook.herokuapp.com](https://trackbook.herokuapp.com) and
give it a try.

I'm running this on a broke ass free heroku instance with a 5MB redis
db. So it maybe slow or completely crumble.

My hope is that people think this is a cool idea and one day is picked
up by UPS (or maybe Amazon) themselves.

## TODO

* Support more services (Fedex, USPS)
* Cleanup web site form design

## Contributing

### Setting up Certificates

Apple doesn't make this easy, you're going to need setup some
certificate stuff inorder to generate passes locally.

First head over to the [iOS Provisioning Portal](https://developer.apple.com/ios/manage/overview/index.action),
follow the directions and create a new "Pass Type ID".

![](http://i.imgur.com/tPkAE.png)

Take note of the full team and type ID. Mine is
`5SW9VUVYKC.pass.trackbook.tracking-info`. Then export that as an
environment variable in your shell.

``` sh
$ export PASS_TYPE_ID=5SW9VUVYKC.pass.trackbook.tracking-info
```

![](http://i.imgur.com/0yf26.png)

Next, download the certificate and find it in your Keychain. It should
be called something like `Pass Type ID: pass.something`. Export it
somewhere as a `.p12` file. Remember
the location and the password you've choosen.

``` sh
$ export CERT_PASS=secret
$ ./script/format-cert ~/Desktop/Certificates.p12
$ export CERT=...
```

Use the `format-cert` script and export its output in your shell. Then
export the password too.

![](http://i.imgur.com/i88Qk.png)

Last, find another certificate in Keychain called *Apple Worldwide
Developer Relations Certification Authority*. Export that as a `.pem`
somewhere.

``` sh
$ ./script/format-wwdr ~/Desktop/Apple\ Worldwide\ Developer\ Relations\ Certification\ Authority.pem
$ export WWDR_CERT=...
```

Use the `format-wwdr` script and export the output to your terminal.

Wow, okay hopefully all that worked. You probably want to save those
variables to a script you can source when you want to work on the app.

### Ruby

Typical ruby/rails setup with bundler. You'll also need a redis db
server running on its default port.

``` sh
$ bundle install
```

Try running the tests. This should confirm the certificate stuff is
setup correctly.

``` sh
$ bundle exec rake
```

Then bootup a server

``` sh
$ bundle exec rackup -p 3000
$ open http://localhost:3000/
```


## Passbook References

* http://developer.apple.com/library/ios/#documentation/UserExperience/Conceptual/PassKit_PG/Chapters/Introduction.html
* http://developer.apple.com/library/ios/#documentation/PassKit/Reference/PassKit_WebService/WebService.html
* http://developer.apple.com/library/ios/#documentation/UserExperience/Reference/PassKit_Bundle/Chapters/Introduction.html
