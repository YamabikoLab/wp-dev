# WordPress URL 構成

`wp-dev` では、ホストのブラウザと Dev Container 内のツールから、同じ WordPress 正規 URL を使用します。

この文書では、その理由と `WORDPRESS_HOST`、`WORDPRESS_PORT`、`WORDPRESS_URL`、Apache、Playwright の関係を説明します。

## 目的

WordPress は `home` / `siteurl` を基準に、管理画面やログイン画面などで正規 URL へのリダイレクトを行います。

Docker Compose では、通常はホストの公開ポートとコンテナ内部の待受ポートが異なります。たとえば `WORDPRESS_PORT=8080` の場合、ホストからは `127.0.0.1:8080` でアクセスしますが、Docker の公開先はコンテナの Apache の 80 番ポートです。

この状態で WordPress の正規 URL だけを `http://127.0.0.1:8080` にすると、Dev Container 内の Playwright などが同じ URL へアクセスした際に、コンテナ自身の 8080 番ポートへ接続しようとします。Apache が 80 番ポートでしか待ち受けていなければ接続できません。

`wp-dev` ではこの差を Playwright 側の特別な URL で吸収せず、ホストと Dev Container の両方から同じ正規 URL を利用できるようにします。

## URL の設定

環境ファイルでは、WordPress のホスト名と公開ポートを設定します。

```dotenv
WORDPRESS_HOST=127.0.0.1
WORDPRESS_PORT=8080
```

`docker/compose.shared.yaml` は、この 2 つから次の URL を導出します。

```text
http://${WORDPRESS_HOST}:${WORDPRESS_PORT}
```

この URL がコンテナ内の `WORDPRESS_URL` です。`WORDPRESS_URL` は環境ファイルへ個別に設定しません。

`default` のサンプルでは `http://127.0.0.1:8080`、`wp683` のサンプルでは `http://127.0.0.1:8081` になります。

## ホストからのアクセス

Docker Compose は、ホスト側の `${WORDPRESS_PORT}` をコンテナの 80 番ポートへ公開します。

```yaml
ports:
  - "127.0.0.1:${WORDPRESS_PORT}:80"
```

そのため、ホストのブラウザで `http://${WORDPRESS_HOST}:${WORDPRESS_PORT}` を開くと、Docker のポートマッピングを経由して Apache の 80 番ポートへ到達します。

## Dev Container 内からのアクセス

Dev Container は WordPress と同じ `wordpress` コンテナを使用します。

コンテナ内部では Docker のホスト向けポートマッピングを経由しないため、Apache が `${WORDPRESS_PORT}` でも待ち受けます。起動時に Apache 設定テンプレートへ `WORDPRESS_HOST` と `WORDPRESS_PORT` を反映し、80 番ポートとは別に同じ WordPress を提供します。

これにより、Dev Container 内から `http://${WORDPRESS_HOST}:${WORDPRESS_PORT}` へアクセスしても Apache に直接到達します。

ホストと Dev Container では通信経路が異なりますが、使用する URL は同じです。

## WordPress の正規 URL

`WORDPRESS_CONFIG_EXTRA` で `WP_HOME` と `WP_SITEURL` を `WORDPRESS_URL` に固定します。

```php
if (!defined('WP_HOME')) {
    define('WP_HOME', getenv('WORDPRESS_URL'));
}
if (!defined('WP_SITEURL')) {
    define('WP_SITEURL', getenv('WORDPRESS_URL'));
}
```

これにより、WordPress が生成する URL と、ホストや Dev Container から実際に使用する URL を一致させます。

既存の `wordpress_data` ボリュームに、この設定を含まない `wp-config.php` が残っている場合は、Dev Container の起動処理が同じ設定ブロックを追加します。既に `WP_HOME` または `WP_SITEURL` が明示的に定義されている場合は、その定義を上書きしません。

## Playwright との関係

Dev Container には、Playwright が利用する次の環境変数を公開します。

```text
WP_BASE_URL=http://${WORDPRESS_HOST}:${WORDPRESS_PORT}
WP_USERNAME=${WORDPRESS_ADMIN_USER}
WP_PASSWORD=${WORDPRESS_ADMIN_PASSWORD}
```

`WP_BASE_URL` は `WORDPRESS_URL` と同じ URL です。

外部プロジェクトの `playwright.config.ts` では、たとえば次のように利用します。

```ts
use: {
    baseURL: process.env.WP_BASE_URL,
}
```

テストコードでは WordPress の絶対 URL をハードコードせず、相対パスを使用できます。

```ts
await page.goto( '/wp-admin/' );
```

Playwright は `baseURL` と相対パスを組み合わせて、同じ WordPress 正規 URL へアクセスします。

## `webServer` を使用しない理由

Playwright の `webServer` は、テスト実行時に対象の Web サーバーを起動するための機能です。

`wp-dev` では Dev Container の起動時点で WordPress と Apache がすでに稼働しています。そのため、外部プロジェクトの Playwright は既存の WordPress へ接続するだけでよく、`webServer` で別のサーバーを起動しません。

WordPress の起動とネットワーク構成は `wp-dev` が担当し、テスト内容と Playwright 設定は外部プロジェクトが担当します。

## 環境を追加・変更するとき

新しい WordPress 環境を追加したりポートを変更したりする場合は、次の関係を維持してください。

| 設定 | 役割 |
| --- | --- |
| `WORDPRESS_HOST` | WordPress 正規 URL のホスト名 |
| `WORDPRESS_PORT` | ホスト公開ポートとコンテナ内部の追加 Apache 待受ポート |
| `WORDPRESS_URL` | `WORDPRESS_HOST` と `WORDPRESS_PORT` から Compose が導出する正規 URL |
| `WP_HOME` / `WP_SITEURL` | `WORDPRESS_URL` を参照する WordPress の正規 URL |
| `WP_BASE_URL` | Playwright が利用する `WORDPRESS_URL` と同一の URL |

`WORDPRESS_URL` や `WP_BASE_URL` を環境ファイルで個別に上書きしないでください。URL を変更する場合は `WORDPRESS_HOST` または `WORDPRESS_PORT` を変更します。

Apache の追加待受はコンテナ内部でのみ使用します。Docker Compose の `ports` に `${WORDPRESS_PORT}:${WORDPRESS_PORT}` のような追加公開を設定する必要はありません。

## 図解について

通信経路の図解画像は、この文書の内容と実装が確定した後に追加します。図解は説明を補助するものであり、設定の正しい内容はこの文書と実装を基準とします。
