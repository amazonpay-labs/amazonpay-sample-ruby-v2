# Amazon Pay v2 sample application for Ruby

This is a sample application of the following Amazon Pay v2 for Ruby.
https://developer.amazon.com/ja/docs/amazon-pay-checkout/introduction.html

## Requirements

Ruby 2.3.0 or higher
Note: If you have less than 2.5.0, you will need to update the "openssl" gem according to the instructions below.
https://github.com/ruby/openssl

## Overview

This application provides a sample that executes a simple checkout flow with Amazon Pay as shown movie below.

<img src="images/checkout-flow.gif" width="350">

## Installation

### Clone the repository

You will clone this repository.

```sh
git clone https://github.com/amazonpay-labs/amazonpay-sample-ruby-v2.git

# Go to the repository you cloned
cd amazonpay-sample-ruby-v2
```

### Create and configure your application in Seller Central

Run Ruby script with the following command.

```sh
ruby keys/init.rb
```

The following files will be created under the keys directory.

- keyinfo.rb
- privateKey.pem

Prepare an application for this sample at [Seller Central](https://sellercentral.amazon.co.jp/) and click [here](https://developer.amazon.com/ja/docs/amazon-pay-checkout/get-set-up-for-integration.html) to obtain the Merchant ID, Public Key ID, Store ID, Store ID, and Private Key, respectively, and copy them to the following

- Merchant ID: MERCHANT_ID in keys/keyinfo.rb
- Public Key ID: PUBLIC_KEY_ID in keys/keyinfo.rb
- Store ID: STORE_ID in keys/keyinfo.rb
- Private Key: keys/privateKey.pem

### Install dependent modules

In this directory, execute the following command to install the dependent modules.

#### If you use Bundler

```sh
bundle install
```

#### If you use RubyGems

```sh
# Note! ↓↓↓ Only if your Ruby version is less than 2.5.0
gem install openssl
# Note! ↑↑↑ Only if your Ruby version is less than 2.5.0 ↑↑↑↑.
# You also need to enable the gem by running "gem 'openssl'" in the source further in the case of 2.3, as described in https://github.com/ruby/openssl.
# In this application, this is done at the top of the code in libs/signature.rb.

gem install sinatra
```

## Launch the server

Execute the following command in this directory.

```sh
ruby app.rb
```

Access [http://localhost:4567/](http://localhost:4567/) to check running.

# Configuration of this application

This application mainly consists of the following three rb files.

## app.rb

This is the main body of the web application. It is implemented in [Sinatra](http://sinatrarb.com/) and is less than 100 lines long.

## keys/keyinfo.rb

This is a configuration file in which only various configuration values are defined.

## libs/signature.rb

This is a sample that shows how to call the Amazon Pay API, and has about 120 lines of code.

---

First, instantiate the AmazonPayClient as shown below:

```ruby
    client = AmazonPayClient.new {
        public_key_id: 'XXXXXXXXXXXXXXXXXXXXXXXX', # publick key ID retrieved from SellerCentral
        private_key: File.read('./privateKey.pem'), # private key retrieved by SellerCentral
        region: 'jp', # 'na', 'eu', 'jp' can be specified
        sandbox: true
    }
```

### Generate Signature for Amazon Pay button

Call 'generate_button_signature' with the following parameters.

- payload: The payload to pass to the API, which can be a JSON string or a Hash instance.

See: https://developer.amazon.com/ja/docs/amazon-pay-checkout/add-the-amazon-pay-button.html

Example:

```ruby
    signature = client.generate_button_signature {
        webCheckoutDetails: {
            checkoutReviewReturnUrl: 'http://example.com/review'
        },
        storeId: 'amzn1.application-oa2-client.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    }
```

### Other API calls

Call 'api_call' with the following parameters.

- url_fragment: The last part of the URL of the API call. e.g.) For 'https://pay-api.amazon.com/:environment/:version/checkoutSessions/', "checkoutSessions".
- method: HTTP method of the API call
- (Optional) payload: The request payload of the API call, which can be a JSON string or a Hash instance.
- (Optional) headers: HTTP header of the API call. e.g.) {header1: 'value1', header2: 'value2'}
- (Optional) query_params: The query parameter of the API call. Example) {param1: 'value1', param2: 'value2'}

The response of the Amazon Pay API call result will be returned.

Example 1: [Create Checkout Session](https://developer.amazon.com/ja/docs/amazon-pay-api-v2/checkout-session.html)

```ruby
    response = client.api_call ("checkoutSessions", "POST",
        payload: {
            webCheckoutDetails: {
                checkoutReviewReturnUrl: "https://example.com/review"
            },
            storeId: "amzn1.application-oa2-client.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        },
        headers: {'x-amz-pay-idempotency-key': SecureRandom.hex(10)}
    )
```

Example 2: [Get Checkout Session](https://developer.amazon.com/ja/docs/amazon-pay-api-v2/checkout-session.html)

```ruby
    response = client.api_call ("checkoutSessions/#{amazon_checkout_session_id}", 'GET')
```
