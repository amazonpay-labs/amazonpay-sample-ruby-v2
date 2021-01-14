#!/usr/bin/env ruby

open __dir__ + '/keyinfo.rb', 'w' do |f|
    f.write <<~FINISH
        KEY_INFO = {
            merchant_id: 'XXXXXXXXXXXX',
            public_key_id: 'XXXXXXXXXXXXXXXXXXXXXXXXX',
            store_id: 'amzn1.application-oa2-client.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
        }
    FINISH
end

open __dir__ + '/privateKey.pem', 'w' do |f|
    f.write <<~FINISH
        -----BEGIN RSA PRIVATE KEY-----
        PASTE YOUR PRIVATE KEY HERE!
        -----END RSA PRIVATE KEY-----
    FINISH
end
