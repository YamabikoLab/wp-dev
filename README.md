# wp-dev

WordPressプラグイン・テーマ開発用の共通Dev Container環境です。

開発対象のリポジトリを外部からマウントし、WordPress、MariaDB、PHP、WP-CLIなどを含む開発環境を提供します。開発環境と製品コードを分離できるため、複数のWordPressプロジェクトで同じ環境を再利用できます。

<img width="1448" height="1086" alt="wp-dev-overview" src="https://github.com/user-attachments/assets/2a422f72-5d27-4883-9441-0ba5b6e32510" />

WordPressの正規URLと、ホスト・Dev Container・Playwrightからのアクセス方法については、[WordPress URL 構成](docs/wordpress-url.md)を参照してください。

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

使用する環境のサンプルをコピーします。

```bash
cd wp-dev
cp environments/default.env.example environments/default.env
# WordPress 6.8.3を使用する場合
cp environments/wp683.env.example environments/wp683.env
```

作成した環境設定ファイルを開き、開発対象に合わせて次の項目を変更します。

```dotenv
COMPOSE_PROJECT_NAME=your-project-default
WP_PROJECT_DIRECTORY=plugins
WP_PROJECT_SLUG=your-plugin-slug
WP_PROJECT_SOURCE_PATH=../../your-wordpress-project
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
| `NODE_VERSION`           | 開発コンテナへインストールするNode.jsのバージョン           |
| `PLAYWRIGHT_VERSION`     | Chromiumのインストールに使用するPlaywrightのバージョン      |
| `WP_CLI_VERSION`         | 開発コンテナへインストールするWP-CLIのバージョン            |
| `XDEBUG_VERSION`         | 開発コンテナへインストールするXdebugのバージョン            |
| `CODEX_CLI_VERSION`      | 開発コンテナへインストールするCodex CLIのバージョン         |
| `LOGCUT_VERSION`         | 開発コンテナへインストールするlogcutのバージョン            |
| `WORDPRESS_HOST`         | WordPressの正規URLに使用するホスト名                         |
| `WORDPRESS_PORT`         | WordPressの公開ポート                                       |
| `MAILPIT_WEB_PORT`       | MailpitのWeb UIを公開するホスト側ポート                     |
| `WP_PROJECT_DIRECTORY`   | `plugins`または`themes`                                     |
| `WP_PROJECT_SLUG`        | WordPress内で使用するプラグインまたはテーマのディレクトリ名 |
| `WP_PROJECT_SOURCE_PATH` | 開発対象リポジトリへの相対パス                              |

`WORDPRESS_URL`は`WORDPRESS_HOST`と`WORDPRESS_PORT`からDocker Composeが導出します。環境設定ファイルへ個別に設定しないでください。

### 3. Dev Containerを開く

Visual Studio Codeで`wp-dev`を開き、コマンドパレットから次を実行します。

```text
Dev Containers: Reopen in Container
```

複数のDev Container構成が表示された場合は、次のいずれかを選択します。

- `default`: `environments/default.env`を使用
- `wp683`: `environments/wp683.env`を使用

Dev Containerは`dev`サービスへ接続し、`developer`ユーザーとして起動します。開発対象のリポジトリは`/workspaces/project`として直接表示されます。

`wp683`のサンプル設定ではWordPressを`http://127.0.0.1:8081`、Mailpitを`http://127.0.0.1:8026`で公開します。

コンテナの作成時に、`wp-dev`内の初期化スクリプトが自動的に実行されます。

### 4. WordPressへアクセスする

初期設定では、次のURLからアクセスできます。

```text
http://127.0.0.1:8080
```

URLを変更する場合は、使用する環境設定ファイルの`WORDPRESS_HOST`または`WORDPRESS_PORT`を変更してください。同じ正規URLをホストとDev Containerの両方から利用する仕組みは、[WordPress URL 構成](docs/wordpress-url.md)で説明しています。

### 5. 送信メールを確認する

WordPressから送信されたメールは外部へ配送されず、Mailpitに保存されます。初期設定では、次のURLから確認できます。

```text
http://127.0.0.1:8025
```

Web UIのポートを変更する場合は、使用する環境設定ファイルの`MAILPIT_WEB_PORT`を変更してください。

開発環境では、WordPressのメール送信元が次の値に統一されます。

```text
送信元アドレス: wordpress@example.test
送信者名: WordPress Development
```

## サービスと権限分離

WordPressの実行環境と開発ツールの認証情報を分離するため、役割を2つのサービスへ分けています。

| サービス | 実行ユーザー | 主な役割 |
| -------- | ------------ | -------- |
| `wordpress` | `www-data` | Apache/PHP、WordPressの実行 |
| `dev` | `developer` | Visual Studio Code、Codex CLI、GitHub CLI、開発コマンド |

CodexとGitHub CLIの認証データは`dev`サービスだけにマウントされます。

```text
/home/developer/.codex
/home/developer/.config/gh
```

`wordpress`サービスにはこれらのボリュームをマウントしないため、WordPress/PHPプロセスから開発ツールの認証データへアクセスできません。Dockerソケットもマウントしません。

## 構成の検証

```bash
docker compose --env-file environments/default.env -f .devcontainer/default/compose.yaml config --quiet
docker compose --env-file environments/wp683.env -f .devcontainer/wp683/compose.yaml config --quiet
```

`wp683`のコンテナ内では、次のコマンドでバージョンを確認できます。

```bash
wp core version
php --version
```

開発用サービスでは、次のコマンドで開発ツールを確認できます。

```bash
codex --version
gh auth status
```

## マウント先

開発対象のリポジトリは、コンテナ内の次の2箇所へマウントされます。

```text
/var/www/html/wp-content/<plugins|themes>/<slug>
/workspaces/project
```

1つ目はWordPressから読み込むためのパス、2つ目はVisual Studio Codeで編集するための固定ワークスペースです。

`wp-dev`自体は開発用`dev`サービスの次の場所へマウントされます。

```text
/workspaces/wp-dev
```

## 初期ログイン情報

初期値は次のとおりです。必要に応じて使用する環境設定ファイルで変更してください。

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
- Codexの設定データ（`dev`サービスの`/home/developer/.codex`）
- GitHub CLIの設定データ（`dev`サービスの`/home/developer/.config/gh`）

CodexとGitHub CLIのボリュームは`wordpress`サービスにはマウントされません。

環境を完全に初期化する場合は、対象のComposeプロジェクトに紐づくボリュームも削除してください。

## 環境の停止

Dev Containerを閉じても、`shutdownAction`の設定によりコンテナは自動停止しません。

`default`を停止する場合は、`wp-dev`ディレクトリで次を実行します。

```bash
docker compose \
  --env-file environments/default.env \
  -f .devcontainer/default/compose.yaml \
  down
```

`wp683`を停止する場合は、次を実行します。

```bash
docker compose \
  --env-file environments/wp683.env \
  -f .devcontainer/wp683/compose.yaml \
  down
```

ボリュームも削除して初期化する場合は、対象コマンドに`--volumes`を追加します。
