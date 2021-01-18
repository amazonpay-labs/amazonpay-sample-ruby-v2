require './keys/keyinfo'
require './libs/signature'

require 'sinatra'
require 'json'
require 'securerandom'

config = {
    region: 'jp',
    public_key_id: KeyInfo::PUBLIC_KEY_ID,
    private_key: File.read('./keys/privateKey.pem'),
    sandbox: true
}

client = AmazonPayClient.new config

get '/' do
  redirect '/cart'
end

get '/cart' do
    payload = JSON.generate({
        webCheckoutDetails: {
            checkoutReviewReturnUrl: 'http://localhost:4567/review'
        },
        storeId: KeyInfo::STORE_ID
    })
    erb :cart, locals: {
        merchant_id: KeyInfo::MERCHANT_ID,
        payload: payload,
        signature: client.generate_button_signature(payload), # Sign the payload
        public_key_id: KeyInfo::PUBLIC_KEY_ID
    }
end

get '/review' do
    # Get Checkout Session
    response = client.api_call("checkoutSessions/#{params['amazonCheckoutSessionId']}", 'GET')
    if response.code.to_i == 201 || response.code.to_i == 200
        erb :review, locals: JSON.parse(response.body)
    else
        erb :error, locals: {status: response.code.to_i, body: response.body}
    end
end

post '/auth' do
    # Update Checkout Session
    response = client.api_call("checkoutSessions/#{params['amazonCheckoutSessionId']}", 'PATCH',
        payload: {
            webCheckoutDetails: {
                checkoutResultReturnUrl: 'http://localhost:4567/thanks'
            },
            paymentDetails: {
                paymentIntent: 'Authorize',
                canHandlePendingAuthorization: false,
                chargeAmount: {
                    amount: '29980',
                    currencyCode: "JPY"
                }
            },
            merchantMetadata: {
                merchantReferenceId: "MY-ORDER-100",
                merchantStoreName: "Test Store",
                noteToBuyer: "Description of the order that is shared in buyer communication.",
                customInformation: "Custom info for the order. This data is not shared in any buyer communication."
            }
        },
        headers: {
            'x-amz-pay-idempotency-key': SecureRandom.hex(10)
        }
    )
    if response.code.to_i == 201 || response.code.to_i == 200
        response.body
    else
        "{\"status\": \"#{response.code.to_i}\", \"body\": \"#{response.body}\"}"
    end
end

get '/thanks' do
    # Complete Checkout Session
    response = client.api_call("checkoutSessions/#{params['amazonCheckoutSessionId']}/complete", 'POST',
        payload: {
            chargeAmount: {
                amount: '29980',
                currencyCode: "JPY"
            }
        }
    )
    if response.code.to_i == 201 || response.code.to_i == 200
        erb :thanks
    else
        erb :error, locals: {status: response.code.to_i, body: response.body}
    end
end
