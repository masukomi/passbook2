# passbook2

The passbook2 gem let's you create a pkpass files for Apple's PassKit. 
It is a fork of the "passbook" gem that has been updated to work with OpenSSL 3.0 and Ruby 3.x. It no longer uses p12 files which because they are no longer supported by Apple.

Apple's [PassKit](https://developer.apple.com/documentation/passkit_apple_pay_and_wallet) is used for processing Apple Pay payments & distributing tickets. This library is currently concerned with simplifying the process of generating a `.pass` bundle for distribution to your users. It's been thoroughly tested as a means of distributing even tickets to iOS devices.

This library does _not_ address updating information on tickets you've already distributed.

Note: This is a fork of [the original passbook gem](https://github.com/frozon/passbook). In addition to a lot of cleanup, it has been updated to support Ruby 3.0 and Apple's current cryptographic requirements.

## Installation

Include the passbook2 gem in your project.

```
gem 'passbook2'
```

## Configuration



```ruby

      # Note: the pb_confg variable below is typically a singleton 
      # configuration object that has knowledge of where you store 
      # your certificate files & related passwords
      # You definitely should not be hardcoding that information.
      pb_config = <your config object>

      Passbook.configure do |passbook|

        # Path to your wwdc cert file# path to the latest
        # "Apple Intermediate Certificate Worldwide Developer Relations" certificate
        # (.cer) file downloaded from here https://www.apple.com/certificateauthority/
        # and placed somewhere under the rails root. It doesn't matter where.
        # ⚠❗ these expire
        passbook.apple_intermediate_cert = pb_config.apple_intermediate_certificate

        # Path to your X509 cert. This is downloaded after generating
        # a certificate from your apple Pass Type ID on apple's developer site
        passbook.certificate = pb_config.x509_certificate

        # Path to the .pem file generated from public key of the RSA keypair
        # that was generated when you made a Certificate Signing Request
        # It'll be in your keychain under the "Common Name" you specified
        # for the signing request.
        passbook.rsa_private_key = pb_config.private_key_pem

        # Password for the .pem file above
        passbook.password = pb_config.rsa_password
      end

```

Additional (optional) configuration variables:
- `notification_cert`
- `notification_gateway`
- `notification_passphrase`


## Usage

First create a new `PKPass` object and pass it your pass' JSON data in the initializer. This will be stored in the pass' `pass.json` file.

``` ruby
    pass = Passbook::PKPass.new('{"YOUR STRINGIFIED JSON DATA"}')
```

Then iterate over the files you need to add to the pass. The order you add them in doesn't matter, but the names must adhere to Apple's Passbook naming convention.

``` ruby
    pass.add_file("path/to/icon.png")
    pass.add_files(["path/to/icon@2x.png", "path/to/thumbnail.png"])
```

![sample.pass](https://github.com/masukomi/passbook2/blob/master/docs/images/passbook_file_structure.png?raw=true)

Once you've added everything you need to your pass, it's time to generate the `.pkpass` zip file. 

``` ruby
  pass.file # returns a Tempfile containing a ZipStream
  
  # you can optionally specify the file name and directory to store it in.
  pass.file({file_name: 'pass.pkpass', directory: Dir.tmpdir})

```

In a Rails app you'd want to send the `.pkpass` data to users with the appropriate mime-type. Here's how to do that.

``` ruby
      zip_file_path = my_pass.file.path
      File.open(zip_file_path, "r") do |file|
        send_data(file.read,
                  type:        "application/vnd.apple.pkpass",
                  disposition: "attachment",
                  filename:    "#{thingy.descriptive_name}.pkpass")
      end
```

### Creating MultiPasses 

Apple supports the idea of a MultiPass. This is just a zipped collection of multiple passes. If, for example, someone buys 5 tickets, you can send them a MultiPass with all 5 wallet passes in it. 

A MultiPass must contain between 1 and 10 passes (inclusive). If your user needs more than 10 items you'll just have to convince them to download multiple MultiPasses. This is annoying, but it's Apple's restriction so there's nothing we can do about it.

To create a MultiPass simply call `PKMultiPass.create_multipass` and give it an array of `PKPass` objects and a valid path and filename to store your MultiPass in. Note that it must end with `.pkpasses`

``` ruby
      my_file_path = File.join(temp_dir, "#{my_order_number}.pkpasses")
      multipass_zip_file_path = Passbook::PKMultiPass.create_multipass(
                        array_of_pk_pass_objects, my_file_path
                      )

```
This will return you the same path you passed in. The resulting `.pkpasses` zip file will use ordinal numbers for the names of the `.pkpass` files inside. E.g. `1.pkpass`, `2.pkpass`, `3.pkpass`, etc. 

Note: if you know where the current documentation for creating MultiPass files is, please let me know. 

Sending this data to users is exactly the same as sending the data for an individual pass. 

-----

### Original Passbook(1) functionality
⚠ WARNING

The following features & documentation come from the original passbook gem, and have _not_ been tested with Apple's current requirements. Signing _does_ work by default, but custom signing has not been tested and appears to still be thinking in terms of `.p12` files which Apple no longer honors. 

Please make a PR if you make an updated version of any of this.


#### Using Different Certificates For Different Passes

Sometime you might want to be able to use different certificates for different passes.  This can be done by passing in a Signer class into your PKPass initializer. You don't have to use environment variables, but it's a good way to make these things easy to rotate in the future when the certs expire.

```
  signer = Passbook::Signer.new(
    certificate:             Rails.root.join(ENV['PASSBOOK_X509_CERTIFICATE']),
    rsa_private_key:         Rails.root.join(ENV['PASSBOOK_PRIVATE_KEY_PEM']),
    password:                ENV['PASSBOOK_RSA_PASSWORD'],
    apple_intermediate_cert: Rails.root.join(ENV['PASSBOOK_APPLE_INTERMEDIATE_CERTIFICATE'])
  )
  pk_pass = Passbook::PKPass.new(data, signer)

  ....
```

### Push Notifications

If you want to support passbook push notification updates you will need to configure the appropriate bits above.

In order to support push notifications you will need to have a basic understanding of the way that push notifications work and how the data is passed back and forth. 

Your pass will need to have a field called 'webServiceURL' with the base url to your site and a field called 'authenticationToken'. The json snippet should look like this.  Note that your url needs to be a valid signed https endpoint for production.  You can put your phone in dev mode to test updates against a insecure http endpoint (under settings => developer => passkit testing).

```
...
  "webserviceURL" : "https://www.honeybadgers.com/",
  "authenticationToken" : "yummycobras"
...
```

Passbook includes rack middleware to make the job of supporting the passbook endpoints easier.  You will need to configure the middleware as outlined above and then implement a class called Passbook::PassbookNotification.  Below is an annotated implementation.

```
module Passbook
  class PassbookNotification

    # This is called whenever a new pass is saved to a users passbook or the
    # notifications are re-enabled.  You will want to persist these values to
    # allow for updates on subsequent calls in the call chain.  You can have
    # multiple push tokens and serial numbers for a specific
    # deviceLibraryIdentifier.

    def self.register_pass(options)
      the_passes_serial_number = options['serialNumber']
      the_devices_device_library_identifier = options['deviceLibraryIdentifier']
      the_devices_push_token = options['pushToken']
      the_pass_type_identifier = options["passTypeIdentifier"]
      the_authentication_token = options['authToken']

      # this is if the pass registered successfully
      # change the code to 200 if the pass has already been registered
      # 404 if pass not found for serialNubmer and passTypeIdentifier
      # 401 if authorization failed
      # or another appropriate code if something went wrong.
      {:status => 201}
    end

    # This is called when the device receives a push notification from apple.
    # You will need to return the serial number of all passes associated with
    # that deviceLibraryIdentifier.

    def self.passes_for_device(options)
      device_library_identifier = options['deviceLibraryIdentifier']
      passes_updated_since = options['passesUpdatedSince']

      # the 'lastUpdated' uses integers values to tell passbook if the pass is
      # more recent than the current one.  If you just set it is the same value
      # every time the pass will update and you will get a warning in the log files.
      # you can use the time in milliseconds,  a counter or any other numbering scheme.
      # you then also need to return an array of serial numbers.
      {'lastUpdated' => '1', 'serialNumbers' => ['various', 'serial', 'numbers']}
    end

    # this is called when a pass is deleted or the user selects the option to disable pass updates.
    def self.unregister_pass(options)
      # a solid unique pair of identifiers to identify the pass are
      serial_number = options['serialNumber']
      device_library_identifier = options['deviceLibraryIdentifier']
      the_pass_type_identifier = options["passTypeIdentifier"]
      the_authentication_token = options['authToken']
      # return a status 200 to indicate that the pass was successfully unregistered.
      {:status => 200}
    end

    # this returns your updated pass
    def self.latest_pass(options)
      the_pass_serial_number = options['serialNumber']
      # create your PkPass the way you did when your first created the pass.
      # you will want to return
      my_pass = PkPass.new 'your pass json'
      # you will want to return the string from the stream of your PkPass object.
      {:status => 200, :latest_pass => mypass.stream.string, :last_modified => '1442120893'}
    end

    # This is called whenever there is something from the update process that is a warning
    # or error
    def self.passbook_log(log)
      # this is a VERY crude logging example.  use the logger of your choice here.
      p "#{Time.now} #{log}"
    end

  end
end

```

To send a push notification for a updated pass simply call Passbook::PushNotification.send_notification with the push token for the device you are updating

```
  Passbook::PushNotification.send_notification the_device_push_token

```

Apple will send out a notification to your phone (usually within 15 minutes or less),  which will cause the phone that this push notification is associated with to make a call to your server to get pass serial numbers and to then get the updated pass.  Each phone/pass combination has it's own push token whch will require a separate call for every phone that has push notifications enabled for a pass (this is an Apple thing).  In the future we may look into offering background process support for this as part of this gem.  For now,  if you have a lot of passes to update you will need to do this yourself.

## Tests

To launch tests:

```bash
  bundle exec rake spec
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


License
-------

passbook is released under the MIT license:

* http://www.opensource.org/licenses/MIT
