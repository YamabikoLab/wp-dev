# wp-dev

WordPressプラグイン・テーマ開発用の共通Dev Container環境です。

開発対象のリポジトリを外部からマウントし、WordPress、MariaDB、PHP、WP-CLI、Mailpitを含む開発環境を提供します。

## 必要なもの

- Docker
- Visual Studio Code
- Dev Containers拡張機能

## セットアップ

### 1. リポジトリを配置する

`wp-dev`と開発対象のリポジトリを、相対パスで参照できる場所へ配置します。

```text
projects/
├── wp-dev/
└── your-wordpress-project/
```

### 2. 共通設定ファイルを作成する

```bash
cd wp-dev
cp environments/.env.example environments/.env
```

`environments/.env`を開き、開発対象に合わせて変更します。

```dotenv
PROJECT_NAME=your-project
WP_PROJECT_DIRECTORY=plugins
WP_PROJECT_SLUG=your-plugin-slug
WP_PROJECT_SOURCE_PATH=../../your-wordpress-project
WORKSPACE_NAME=your-wordpress-project
```

テーマを開発する場合は、`WP_PROJECT_DIRECTORY=themes`にします。

環境固有のWordPressバージョン、ポート、Composeプロジェクト名は、コミット済みのプリセットで管理します。

| 構成 | WordPress | WordPress URL | Mailpit URL |
| --- | --- | --- | --- |
| `default` | 7.0.2 / PHP 8.3 / Apache | `http://127.0.0.1:8080` | `http://127.0.0.1:8025` |
| `wp683` | 6.8.3 / PHP 8.3 / Apache | `http://127.0.0.1:8081` | `http://127.0.0.1:8026` |

`PROJECT_NAME`には、それぞれ自動的に`-default`または`-wp683`が付きます。そのため、両環境を同時に起動してもコンテナ、ネットワーク、ボリュームが競合しません。

### 3. Dev Containerを選択する

Visual Studio Codeで`wp-dev`を開き、コマンドパレットから次を実行します。

```text
Dev Containers: Reopen in Container
```

表示された構成から、用途に応じて次のいずれかを選択します。

- `wp-dev: default`
- `wp-dev: wp683`

開発対象のリポジトリは、次の2箇所へマウントされます。

```text
/var/www/html/wp-content/<plugins|themes>/<slug>
/workspaces/<workspace-name>
```

`wp-dev`自体は`/workspaces/wp-dev`へマウントされます。`cdw`で開発対象のワークスペースへ移動できます。

## 構成の検証

共通設定ファイルを作成した後、次のコマンドで両構成を検証できます。

```bash
docker compose -f .devcontainer/default/compose.yaml config --quiet
docker compose -f .devcontainer/wp683/compose.yaml config --quiet
```

実行中のWordPressバージョンは、コンテナ内で次のように確認できます。

```bash
wp core version
php --version
```

## 環境の停止

`default`を停止します。

```bash
docker compose -f .devcontainer/default/compose.yaml down
```

`wp683`を停止します。

```bash
docker compose -f .devcontainer/wp683/compose.yaml down
```

ボリュームも削除して初期化する場合のみ、対象コマンドに`--volumes`を追加してください。

## 初期ログイン情報

初期値は`environments/.env`で変更できます。

```text
ユーザー名: admin
パスワード: admin
メールアドレス: admin@example.test
```

これらはローカル開発専用です。本番環境では使用しないでください。

## データの永続化

次のデータは環境ごとのDockerボリュームへ保存されます。

- WordPress本体とアップロードデータ
- MariaDBのデータ
- Codexの設定データ
- GitHub CLIの設定データ
