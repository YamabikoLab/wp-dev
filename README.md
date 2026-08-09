# wp-dev

WordPressプラグイン・テーマ開発用の共通Dev Container環境です。

開発対象のリポジトリを外部からマウントし、WordPress、MariaDB、PHP、WP-CLIなどを含む開発環境を提供します。開発環境と製品コードを分離できるため、複数のWordPressプロジェクトで同じ環境を再利用できます。

<img width="1448" height="1086" alt="wp-dev-overview" src="https://github.com/user-attachments/assets/2a422f72-5d27-4883-9441-0ba5b6e32510" />

WordPressの正規URLと、ホスト・Dev Container・Playwrightからのアクセス方法については、[WordPress URL 構成](docs/wordpress-url.md)を参照してください。

開発データの取り扱い、PHPエラー表示、保存場所、削除・初期化方法については、[開発データの保持と初期化](docs/data-retention.md)を参照してください。

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
| `WP_CLI_SHA256`          | WP-CLI PHAR の検証に使用するSHA-256                          |
| `XDEBUG_VERSION`         | 開発コンテナへインストールするXdebugのバージョン            |
| `CODEX_CLI_VERSION`      | 開発コンテナへインストールするCodex CLIのバージョン         |
| `LOGCUT_VERSION`         | 開発コンテナへインストールするlogcutのバージョン            |
| `WORDPRESS_HOST`         | WordPressの正規URLに使用するホスト名                         |
| `WORDPRESS_PORT`         | WordPressの公開ポート                                       |
| `MAILPIT_WEB_PORT`       | MailpitのWeb UIを公開するホスト側ポート                     |
| `PHP_DISPLAY_ERRORS`     | PHPエラー画面表示。通常は`Off`、限定的な診断時のみ`On`      |
| `LOCAL_UID`              | Dev Containerの`developer`ユーザーに割り当てるUID           |
| `LOCAL_GID`              | Dev Containerの`developer`ユーザーに割り当てるGID           |
| `WP_PROJECT_DIRECTORY`   | `plugins`または`themes`                                     |
| `WP_PROJECT_SLUG`        | WordPress内で使用するプラグインまたはテーマのディレクトリ名 |
| `WP_PROJECT_SOURCE_PATH` | 開発対象リポジトリへの相対パス                              |

`WORDPRESS_URL`は`WORDPRESS_HOST`と`WORDPRESS_PORT`からDocker Composeが導出します。環境設定ファイルへ個別に設定しないでください。

`PHP_DISPLAY_ERRORS`は既定で`Off`です。WordPress初期化前、直接実行PHP、起動時エラーの診断時だけ一時的に`On`へ変更し、対象コンテナを再作成してください。WordPress通常リクエストでは`WP_DEBUG_DISPLAY=false`を維持するため、この設定を`On`にしてもWordPress初期化後の通常ページへPHPエラーを表示する用途には使用しません。

### 3. Dev Containerを開く

Visual Studio Codeで`wp-dev`を開き、コマンドパレットから次を実行します。

```text
Dev Containers: Reopen in Container
```

複数のDev Container構成が表示された場合は、次のいずれかを選択します。

- `default`: `environments/default.env`を使用
- `wp683`: `environments/wp683.env`を使用

Dev Containerは`developer`ユーザーで開き、開発対象のリポジトリが`/workspaces/project`として直接表示されます。`developer`のUID/GIDは環境設定の`LOCAL_UID` / `LOCAL_GID`を使用します。

WordPress、Apache、PHPはベースイメージ標準の`www-data`で実行し、`www-data`のUID/GIDは`LOCAL_UID` / `LOCAL_GID`へ変更しません。

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

Mailpitのメールだけを削除する場合はWeb UIの`Delete all`を使用できます。Mailpitは永続Volumeを使用していないため、コンテナを削除・再作成すると旧メールは引き継がれません。詳しくは[開発データの保持と初期化](docs/data-retention.md)を参照してください。

## 開発ユーザーとCLI認証情報

VS Code、Git、npm、Composer、WP-CLI、Codex CLI、GitHub CLIなどの開発操作は`developer`ユーザーで実行します。

CodexとGitHub CLIの認証情報は次の`developer`専用領域へ保存されます。

```text
/home/developer/.codex
/home/developer/.config/gh
```

これらのディレクトリは`developer`だけがアクセスできる権限で作成されます。WordPress/PHPの`www-data`から認証情報を読み取らせないためです。

CLI認証情報用のDockerボリュームは使用しません。Dev Containerまたはコンテナを再作成すると認証情報は失われるため、必要に応じてCodex CLIとGitHub CLIを再認証してください。

通常のCodex起動には`codex`コマンドを使用します。

## 構成の検証

```bash
docker compose --env-file environments/default.env -f .devcontainer/default/compose.yaml config --quiet
docker compose --env-file environments/wp683.env -f .devcontainer/wp683/compose.yaml config --quiet
```

Dev Container内では、次のコマンドで実行ユーザーと開発ツールを確認できます。

```bash
whoami
id
codex --version
gh auth status
```

`wp683`のコンテナ内では、次のコマンドでバージョンを確認できます。

```bash
wp core version
php --version
```

## マウント先

開発対象のリポジトリは、コンテナ内の次の2箇所へマウントされます。

```text
/var/www/html/wp-content/<plugins|themes>/<slug>
/workspaces/project
```

1つ目はWordPressから読み込むためのパス、2つ目はVisual Studio Codeで編集するための固定ワークスペースです。

WordPress側のマウントは読み取り専用です。WordPress、Apache、PHPを実行する`www-data`から開発対象ソースへ書き込めません。一方、`/workspaces/project`は`developer`による編集用として読み書き可能なままです。両方とも同じホスト側ソースを参照するため、`developer`が生成したビルド成果物はWordPress側の読み取り専用マウントにもそのまま反映されます。

`wp-dev`自体は次の場所へマウントされます。

```text
/workspaces/wp-dev
```

`/workspaces`は`developer`所有の`0700`相当で構成されます。そのため、`developer`は`/workspaces/project`と`/workspaces/wp-dev`を通常どおり利用できますが、WordPress/PHPの`www-data`は`/workspaces`配下を辿れません。WordPress側の読み取り専用マウントと組み合わせ、同じホスト側ソースへの別のread-write経路をWordPress/PHPから利用できないようにしています。

## 初期ログイン情報

初期値は次のとおりです。必要に応じて使用する環境設定ファイルで変更してください。

```text
ユーザー名: admin
パスワード: admin
メールアドレス: admin@example.test
```

これらはローカル開発専用です。本番環境では使用しないでください。本番DB、本番アップロード、実在する個人情報、実認証情報は原則として開発環境へ持ち込まないでください。

## データの永続化

次のデータはDockerのNamed Volumeへ保存されます。

- WordPress本体、アップロード、`wp-content/debug.log`: `wordpress_data`
- MariaDB: `db_data`

通常の`docker compose down`ではこれらのNamed Volumeを保持します。CodexとGitHub CLIの認証情報はNamed Volumeへ永続化しません。Mailpitも永続Volumeを使用しません。

保存場所、データごとのライフサイクル、Mailpitの削除方法については[開発データの保持と初期化](docs/data-retention.md)を参照してください。

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

### 完全初期化

`down --volumes`はWordPressとMariaDBのNamed Volumeを削除する破壊的操作です。実行前に、対象Composeプロジェクトが正しいことを確認してください。

`default`の場合:

```bash
docker compose \
  --env-file environments/default.env \
  -f .devcontainer/default/compose.yaml \
  ps
```

対象が正しいことを確認した後に実行します。

```bash
docker compose \
  --env-file environments/default.env \
  -f .devcontainer/default/compose.yaml \
  down --volumes
```

`wp683`では`environments/wp683.env`と`.devcontainer/wp683/compose.yaml`を使用してください。

完全初期化では対象Composeプロジェクトの`wordpress_data`と`db_data`が削除されます。`WP_PROJECT_SOURCE_PATH`で指定したホスト側のbind mount元は削除されません。また、バックアップやホストへ別途コピーしたデータは残る可能性があります。
