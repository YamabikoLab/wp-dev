# wp-dev

WordPressプラグイン・テーマ開発用の共通Dev Container環境です。

開発対象のリポジトリを外部からマウントし、WordPress、MariaDB、PHP、WP-CLIなどを含む開発環境を提供します。開発環境と製品コードを分離できるため、複数のWordPressプロジェクトで同じ環境を再利用できます。

## 必要なもの

- Docker
- Visual Studio Code
- Dev Containers拡張機能

## セットアップ

### 1. リポジトリを配置する

`wp-dev`と開発対象のリポジトリを、同じ親ディレクトリなど相対パスで参照できる場所へ配置します。

```text
projects/
├── wp-dev/
└── your-wordpress-project/
```

### 2. 環境設定ファイルを作成する

サンプルをコピーします。

```bash
cd wp-dev
cp environments/default.env.example environments/default.env
```

`environments/default.env`を開き、開発対象に合わせて次の項目を変更します。

```dotenv
COMPOSE_PROJECT_NAME=your-project-default
WP_PROJECT_DIRECTORY=plugins
WP_PROJECT_SLUG=your-plugin-slug
WP_PROJECT_SOURCE_PATH=../../your-wordpress-project
WORKSPACE_NAME=your-wordpress-project
```

テーマを開発する場合は、`WP_PROJECT_DIRECTORY`を`themes`にします。

```dotenv
WP_PROJECT_DIRECTORY=themes
```

主な設定項目は次のとおりです。

| 項目                     | 説明                                                        |
| ------------------------ | ----------------------------------------------------------- |
| `COMPOSE_PROJECT_NAME`   | Docker Composeプロジェクト名                                |
| `WORDPRESS_IMAGE_TAG`    | 使用するWordPress Dockerイメージのタグ                      |
| `WORDPRESS_PORT`         | ホスト側で公開するWordPressのポート                         |
| `MAILPIT_WEB_PORT`       | MailpitのWeb UIを公開するホスト側ポート                     |
| `WP_PROJECT_DIRECTORY`   | `plugins`または`themes`                                     |
| `WP_PROJECT_SLUG`        | WordPress内で使用するプラグインまたはテーマのディレクトリ名 |
| `WP_PROJECT_SOURCE_PATH` | 開発対象リポジトリへの相対パス                              |
| `WORKSPACE_NAME`         | Dev Container内のワークスペース名                           |

### 3. Dev Containerを開く

Visual Studio Codeで`wp-dev`を開き、コマンドパレットから次を実行します。

```text
Dev Containers: Reopen in Container
```

複数のDev Container構成が表示された場合は、`default`を選択します。

コンテナの作成時に、`wp-dev`内の初期化スクリプトが自動的に実行されます。

### 4. WordPressへアクセスする

初期設定では、次のURLからアクセスできます。

```text
http://127.0.0.1:8080
```

ポートを変更した場合は、`WORDPRESS_SITE_URL`も同じ値に合わせてください。

### 5. 送信メールを確認する

WordPressから送信されたメールは外部へ配送されず、Mailpitに保存されます。初期設定では、次のURLから確認できます。

```text
http://127.0.0.1:8025
```

Web UIのポートを変更する場合は、`environments/default.env`の`MAILPIT_WEB_PORT`を変更してください。

開発環境では、WordPressのメール送信元が次の値に統一されます。

```text
送信元アドレス: wordpress@example.test
送信者名: WordPress Development
```

## マウント先

開発対象のリポジトリは、コンテナ内の次の2箇所へマウントされます。

```text
/var/www/html/wp-content/<plugins|themes>/<slug>
/workspaces/<workspace-name>
```

1つ目はWordPressから読み込むためのパス、2つ目はVisual Studio Codeで編集するためのワークスペースです。

`wp-dev`自体は次の場所へマウントされます。

```text
/workspaces/wp-dev
```

## 初期ログイン情報

初期値は次のとおりです。必要に応じて`environments/default.env`で変更してください。

```text
ユーザー名: admin
パスワード: admin
メールアドレス: admin@example.test
```

これらはローカル開発専用です。本番環境では使用しないでください。

## データの永続化

次のデータはDockerボリュームへ保存されます。

- WordPress本体とアップロードデータ
- MariaDBのデータ
- Codexの設定データ
- GitHub CLIの設定データ

環境を完全に初期化する場合は、対象のComposeプロジェクトに紐づくボリュームも削除してください。

## 環境の停止

Dev Containerを閉じても、`shutdownAction`の設定によりコンテナは自動停止しません。

停止する場合は、`wp-dev`ディレクトリで次を実行します。

```bash
docker compose \
  --env-file environments/default.env \
  -f .devcontainer/default/compose.yaml \
  down
```

ボリュームも削除して初期化する場合は、`--volumes`を追加します。

```bash
docker compose \
  --env-file environments/default.env \
  -f .devcontainer/default/compose.yaml \
  down --volumes
```
