# Ruby版 Amazon Pay v2 サンプルアプリケーション
下記Amazon Pay v2の、Ruby版サンプルアプリケーションです。  
http://amazonpaycheckoutintegrationguide.s3.amazonaws.com/amazon-pay-checkout/introduction.html

## 動作環境
Ruby 2.3.0 以上  
Note: 2.5.0 未満の場合、「openssl」のGemを下記指示にしたがって更新する必要があります。  
https://github.com/ruby/openssl  

## 概要
本アプリケーションでは、下記のようにAmazon Payでの購入の単純なFlowを実行するサンプルを提供しています。  
<img src="images/checkout-flow.gif" width="500">  

主に下記の３つのrbファイルで構成されています。  
- app.rb (Webアプリ本体)
- libs/signature.rb (Amazon Pay API呼出用)
- keys/keyinfo.rb (設定値定義用)

Note: 本アプリケーションで利用されていないAPIの呼び出し方については、「libs/signature.rb」のコメントを参考にして下さい。

## インストール

### リポジトリのclone
本リポジトリをcloneします。  
```
git clone https://github.com/amazonpay-labs/amazonpay-sample-ruby-v2.git
```

### Seller Centralでのアプリケーション作成・設定
keys/template ディレクトリ下の、
  - keyinfo.rb  
  - privateKey.pem

を一階層上の keys ディレクトリ直下にコピーします。  

[Seller Central](https://sellercentral.amazon.co.jp/)にて、本サンプル用にアプリケーションを用意し、[こちら](https://amazonpaycheckoutintegrationguide.s3.amazonaws.com/amazon-pay-checkout/get-set-up-for-integration.html#4-get-your-public-key-id)を参考に、Merchant ID, Public Key ID, Store ID, Private Keyを取得し、それぞれ下記にコピーします。
  * Merchant ID: keys/keyinfo.rb の merchant_id
  * Public Key ID: keys/keyinfo.rb の public_key_id
  * Store ID: keys/keyinfo.rb の store_id
  * Private Key: keys/privateKey.pem

### 依存モジュールのインストール
本ディレクトリにて、下記のコマンドを実行して依存モジュールをインストールします。

#### Bundlerを使用する場合
```sh
bundle install
```

#### RubyGemsを使用する場合
```sh
# Note: 上記「動作環境」でも述べたとおり、Rubyのバージョンが 2.5.0 未満の場合、「openssl」のGemを下記指示にしたがって更新する必要があります。
# https://github.com/ruby/openssl

gem install sinatra
```

## サーバーの起動
本ディレクトリにて、下記コマンドを実行します。
```sh
ruby app.rb
```

[http://localhost:4567/](http://localhost:4567/) にアクセスして、動作を確認します。
