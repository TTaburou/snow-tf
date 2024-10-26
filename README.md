# snow-tf
`OpenTofu`から`Snowflake`へオブジェクトの作成を行います。
# Snowflakeの準備
[参考リンク](https://qiita.com/hiro-wa/items/4aeb1c7346714d6b5e53)
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
参照の記事では、`アカウントLocator`と`リージョンID`を環境変数に設定していますが、非推奨となっているため[アカウント識別子](https://docs.snowflake.com/ja/user-guide/admin-account-identifier)を使います。<br>
``環境変数はターミナルを立ち上げる度に入力しないといけないので、snow.envなどのファイルを用意しそこに記載しておくと次回以降入力が楽です。``
※クレデンシャルのハードコードは非推奨ですが、[プロバイダのパラメータとして指定](https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs)することも可能です。

# open tofuの準備
### asdfのインストール
`ToDo`
### tofuのインストール
gitリポジトリの.tool-versionsが存在するディレクトリで実行します。
`ToDo`
### tfファイルの作成
main.tfを作成します。</br>
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
その他のリソースは[terraformドキュメント](https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs)が参考になります。
# GitHubactionsの追加
[こちらの記事](https://zenn.dev/dataheroes/articles/dfc62ed51ef925)を参考にymlを作成します。<br>
記事ではアカウントとパスワードを使用しますが、アカウント識別子とキーペア認証します。
### GitHubにシークレットを登録
GitHuibのSettings→Secrets and variables→Actionsに以下の３つを追加します。
- SNOWFLAKE_USER `tf-snow`
 -  <img width="1440" alt="git_sf_usr" src="https://github.com/user-attachments/assets/209ee58c-f6f0-4441-80e4-7aa2b66dae22">
- SNOWFLAKE_PRIVATE_KEY
 - <img width="1440" alt="git_sf_pk" src="https://github.com/user-attachments/assets/9d677c1d-2201-40e9-a168-c88fa2e3163e">
- SNOWFLAKE_ACCOUNT="${アカウント識別子}"
 -  <img width="1440" alt="git_sf_acnt" src="https://github.com/user-attachments/assets/57300b4d-409d-4e88-b498-948fe80c6165">
### workflowの作成
[こちら](https://github.com/marketplace/actions/opentofu-setup-tofu)を参考にmain.ymlを作成します。
```
name: OpenToFu Plan and Apply on Main Branch Push

on:
  push:
    branches:
      - main

jobs:
  terraform:
    name: 'tofu Plan'
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: modules/
    env:
      SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
      SNOWFLAKE_PRIVATE_KEY: ${{ secrets.SNOWFLAKE_PRIVATE_KEY }}
      SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_USER }}

    steps:
    - name: Checkout Repository
      uses: actions/checkout@v3

    - name: Setup OpenTofu
      uses: opentofu/setup-opentofu@v1

    - name: OpenTofu Initialize
      run: tofu init -no-color

    - name: OpenTofu Validate
      run: tofu validate -no-color

    - name: OpenTofu Plan
      run: tofu plan -no-color

    - name: OpenTofu Apply
      run: tofu apply -no-color -auto-approve
```
