# snow-tf
`open tofu`から`snowflake`へオブジェクトの作成を行います。
# Snowflakeの準備
https://qiita.com/hiro-wa/items/4aeb1c7346714d6b5e53
### 鍵の生成
```
$ cd ~/.ssh
$ openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out snowflake_tf_snow_key.p8 -nocrypt
$ openssl rsa -in snowflake_tf_snow_key.p8 -pubout -out snowflake_tf_snow_key.pub
$ cat snowflake_tf_snow_key.pub | pbcopy
```
### Snowflake user の作成
Snowflakeのクエリエディタからopen tofu用ユーザーを作成します。<br>
`RSA_PUBLIC_KEY`には先ほど生成した`snowflake_tf_snow_key.pub`を記入してください。<br>
※公開鍵をペーストした際に前後に-----BEGIN PUBLIC KEY-----, -----END PUBLIC KEY----—も入ると思うので、それは忘れずに消しておいてください。
```
CREATE USER "tf-snow"
	RSA_PUBLIC_KEY='${生成した公開鍵}'
	DEFAULT_ROLE=PUBLIC
	MUST_CHANGE_PASSWORD=FALSE;

GRANT ROLE SYSADMIN TO USER "tf-snow";
GRANT ROLE SECURITYADMIN TO USER "tf-snow";
```
###　環境変数の設定
Snowflakeのログイン用urlから`アカウント識別子`を確認します。
```
https://{アカウント識別子}.snowflakecomputing.com/console/login
```
環境変数を設定します。サンプルはzshです。
```
$ export SNOWFLAKE_USER="tf-snow"
$ export SNOWFLAKE_PRIVATE_KEY_PATH="~/.ssh/snowflake_tf_snow_key.p8"
$ export SNOWFLAKE_ACCOUNT="${アカウント識別子}"
```
冒頭の記事では、`アカウントLocator`と`リージョンID`を環境変数に設定していますが、非推奨となっているため[アカウント識別子](https://docs.snowflake.com/ja/user-guide/admin-account-identifier)を使います。<br>
``環境変数はターミナルを立ち上げる度に入力しないといけないので、snow.envなどのファイルを用意しそこに記載しておくと次回以降入力が楽です。``

# open tofuの準備
### asdfのインストール
`ToDo`
### tofuのインストール
gitリポジトリの.tool-versionsが存在するディレクトリで実行します。
`ToDo`
### tfファイルの作成
main.tfを作成します。
データベースとウェアハウスをSnowflakeに作成します。
```
terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "0.42.1"
    }
  }
}
# プロバイダのロールを指定
provider "snowflake" {
  role  = "SYSADMIN"
}
# データベース
resource "snowflake_database" "db" {
  name     = "TF_DEMO_DB"
}
# ウェアハウス
resource "snowflake_warehouse" "warehouse" {
  name           = "TF_DEMO_WH"
  warehouse_size = "large"
  auto_suspend = 60
}
```
### tofuの実行
main.tfファイルの存在するディレクトリで初期化します。
```
tofu init
```
planします。
```
tofu plan
```
実行結果
```
$ tofu plan

OpenTofu used the selected providers to generate the following execution plan. Resource
actions are indicated with the following symbols:
  + create

OpenTofu will perform the following actions:

  # snowflake_database.db will be created
  + resource "snowflake_database" "db" {
      + data_retention_time_in_days = (known after apply)
      + id                          = (known after apply)
      + is_transient                = false
      + name                        = "TF_DEMO_DB"
    }

  # snowflake_warehouse.warehouse will be created
  + resource "snowflake_warehouse" "warehouse" {
      + auto_resume                         = (known after apply)
      + auto_suspend                        = 60
      + id                                  = (known after apply)
      + max_cluster_count                   = (known after apply)
      + max_concurrency_level               = 8
      + min_cluster_count                   = (known after apply)
      + name                                = "TF_DEMO_WH"
      + resource_monitor                    = (known after apply)
      + scaling_policy                      = (known after apply)
      + statement_queued_timeout_in_seconds = 0
      + statement_timeout_in_seconds        = 172800
      + warehouse_size                      = "large"
    }

Plan: 2 to add, 0 to change, 0 to destroy.

──────────────────────────────────────────────────────────────────────────────────────────────
```
applyします。
```
tofu apply
```
Enter a value: `yes`
実行結果
```
 tofu apply

OpenTofu used the selected providers to generate the following execution plan. Resource
actions are indicated with the following symbols:
  + create

OpenTofu will perform the following actions:

  # snowflake_database.db will be created
  + resource "snowflake_database" "db" {
      + data_retention_time_in_days = (known after apply)
      + id                          = (known after apply)
      + is_transient                = false
      + name                        = "TF_DEMO_DB"
    }

  # snowflake_warehouse.warehouse will be created
  + resource "snowflake_warehouse" "warehouse" {
      + auto_resume                         = (known after apply)
      + auto_suspend                        = 60
      + id                                  = (known after apply)
      + max_cluster_count                   = (known after apply)
      + max_concurrency_level               = 8
      + min_cluster_count                   = (known after apply)
      + name                                = "TF_DEMO_WH"
      + resource_monitor                    = (known after apply)
      + scaling_policy                      = (known after apply)
      + statement_queued_timeout_in_seconds = 0
      + statement_timeout_in_seconds        = 172800
      + warehouse_size                      = "large"
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  OpenTofu will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

snowflake_warehouse.warehouse: Creating...
snowflake_database.db: Creating...
snowflake_database.db: Creation complete after 1s [id=TF_DEMO_DB]
snowflake_warehouse.warehouse: Creation complete after 1s [id=TF_DEMO_WH]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```