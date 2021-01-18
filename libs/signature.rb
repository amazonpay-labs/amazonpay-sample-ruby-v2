#!/usr/bin/env ruby

=begin
A sample code for calling Amazon Pay API version 2 in Ruby.  
See: http://amazonpaycheckoutintegrationguide.s3.amazonaws.com/amazon-pay-checkout/introduction.html  

# Requires
Ruby version: 2.3.0 or higher  
Note: For less than 2.5.0, you have to update the gem of openssl by following the instructions below:  
    https://github.com/ruby/openssl  

# How to use  
At first, instantiate AmazonPayClient like below:  

```ruby
    client = AmazonPayClient.new {
        public_key_id: 'XXXXXXXXXXXXXXXXXXXXXXXX', # the publick key ID you obtained at seller central
        private_key: File.read('./privateKey.pem'), # the private key you obtained at seller central
        region: 'jp', # you can specify 'na', 'eu' or 'jp'.
        sandbox: true
    }
```

## To generate button signature
Invoke 'generate_button_signature' specifying the parameters below:  
 - payload: the request payload of the API. You can specify either JSON string or Hash instance.  
See: http://amazonpaycheckoutintegrationguide.s3.amazonaws.com/amazon-pay-checkout/add-the-amazon-pay-button.html#3-sign-the-payload

Example:  

```ruby
    signature = client.generate_button_signature {
        webCheckoutDetails: {
            checkoutReviewReturnUrl: 'http://example.com/review'
        },
        storeId: 'amzn1.application-oa2-client.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    }
```

## Others

Invoke 'call_api' method specifying the parameters below:  
 - url_fragment: the last part of the URL of the API. ex) 'checkoutSessions' if the URL is 'https://pay-api.amazon.com/:environment/:version/checkoutSessions/'
 - method: the HTTP method of the API.
 - (Optional) payload: the request payload of the API. You can specify either JSON string or Hash instance. 
 - (Optional) headers: the HTTP headers of the API. ex) {header1: 'value1', header2: 'value2'}
 - (Optional) query_params: the query parameters of the API. ex) {param1: 'value1', param2: 'value2'}  
 The response of the API call is returned.  

Example 1: Create Checkout Session (http://amazonpaycheckoutintegrationguide.s3.amazonaws.com/amazon-pay-api-v2/checkout-session.html#create-checkout-session)  

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

Example 2: Get Checkout Session (http://amazonpaycheckoutintegrationguide.s3.amazonaws.com/amazon-pay-api-v2/checkout-session.html#get-checkout-session)  

```ruby
    response = client.api_call ("checkoutSessions/#{amazon_checkout_session_id}", 'GET')
```
=end

gem 'openssl' if RUBY_VERSION < '2.4'
require 'openssl'

require 'net/http'
require 'time'
require 'json'
require 'base64'

class AmazonPayClient

    def initialize config
        @helper = Helper.new config
    end

    def generate_button_signature payload = ''
        @helper.sign(payload.is_a?(String) ? payload : JSON.generate(payload))
    end

    def api_call url_fragment, method, payload: '', headers: {}, query_params: {}
        query = @helper.to_query query_params
        uri = URI.parse(@helper.base_url + url_fragment + (query ? "?#{query}" : ''))
        request = @helper.http_method(method).new(uri)
        request.body = payload.is_a?(String) ? payload : JSON.generate(payload)

        signed_headers = @helper.signed_headers(method, uri, request.body, headers, query)
        signed_headers.each { |k, v| request[k] = v }

        Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.request(request)
        end
    end
    
    API_VERSION = "v2"
    API_ENDPOINTS = {
        'na' => 'pay-api.amazon.com',
        'eu' => 'pay-api.amazon.eu',
        'jp' => 'pay-api.amazon.jp'
    }
    METHOD_TYPES = {
        'GET' => Net::HTTP::Get,
        'POST' => Net::HTTP::Post,
        'PUT' => Net::HTTP::Put,
        'PATCH' => Net::HTTP::Patch,
        'DELETE' => Net::HTTP::Delete
    }
    HASH_ALGORITHM = "SHA256"
    AMAZON_SIGNATURE_ALGORITHM = "AMZN-PAY-RSASSA-PSS"
    
    class Helper
        attr_reader :base_url

        def initialize config
            @region = get :region, config
            @public_key_id = get :public_key_id, config
            @private_key = get :private_key, config
            @base_url = "https://#{endpoint}/#{get(:sandbox, config) ? 'sandbox' : 'live'}/#{API_VERSION}/"
        end

        def get key, config
            config[key] || config[key.to_s]
        end

        def endpoint
            API_ENDPOINTS[@region] || raise(ArgumentError, "Unknown region, '#{@region}'. The region should be one of follows: #{API_ENDPOINTS.keys}.")
        end

        def http_method method
            METHOD_TYPES[method] || raise(ArgumentError, "Unknown HTTP method, '#{method}'. The HTTP method should be one of follows: #{METHOD_TYPES.keys}.")
        end

        def signed_headers(method, uri, payload, user_headers, query)
            payload = '' if uri.path.include?('account-management/v2/accounts')
    
            headers = Hash[user_headers.map{|k, v| [k.to_s, v.gsub(/\s+/, ' ')]}]
            headers['accept'] = headers['content-type'] = 'application/json'
            headers['x-amz-pay-region'] = @region
            headers['x-amz-pay-date'] = formatted_timestamp
            headers['x-amz-pay-host'] = uri.host
    
            canonical_headers = Hash[ headers.map{|k, v| [k.to_s.downcase, v]}.sort_by { |kv| kv[0] } ]
            canonical_header_names = canonical_headers.keys.join(';')
            canonical_request = <<~EOS.chomp
                #{method}
                #{uri.path}
                #{query}
                #{canonical_headers.map{|k, v| "#{k}:#{v}"}.join("\n")}
                
                #{canonical_header_names}
                #{hex_and_hash(payload)}
            EOS
            signed_headers = "SignedHeaders=#{canonical_header_names}, Signature=#{sign canonical_request}"
            headers['authorization'] = "#{AMAZON_SIGNATURE_ALGORITHM} PublicKeyId=#{@public_key_id}, #{signed_headers}"
    
            headers
        end
    
        def sign string_to_sign
            hashed_canonical_request = "#{AMAZON_SIGNATURE_ALGORITHM}\n#{hex_and_hash(string_to_sign)}"
            rsa = OpenSSL::PKey::RSA.new @private_key
            Base64.strict_encode64(rsa.sign_pss(HASH_ALGORITHM, hashed_canonical_request, salt_length: 20, mgf1_hash: HASH_ALGORITHM))
        end
    
        def to_query(query_params)
            query_params.map{|k, v| [k.to_s, url_encode(v)]}.sort_by{|kv| kv[0]}.map{|kv| "#{kv[0]}=#{kv[1]}"}.join('&')
        end
    
        def hex_and_hash(data)
            Digest::SHA256.hexdigest(data)
        end
    
        def formatted_timestamp
            Time.now.utc.iso8601.split(/[-,:]/).join
        end
    
        def url_encode(value)
            URI::encode(value).gsub('%7E', '~')
        end
    end
end
