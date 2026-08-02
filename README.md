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

### 3. Dev Containerを開く

Visual Studio Codeで`wp-dev`を開き、コマンドパレットから次を実行します。

```text
Dev Containers: Reopen in Container
```

次のいずれかを選択します。

- `wp-dev: default`: `environments/default.env`をそのまま使用
- `wp-dev: wp683`: `environments/default.env`を基礎に、WordPress 6.8.3用の設定を上書き

`wp683`では次の設定が使用されます。

| 項目 | 値 |
| --- | --- |
| WordPressイメージ | `wordpress:6.8.3-php8.3-apache` |
| WordPress URL | `http://127.0.0.1:8081` |
| Mailpit URL | `http://127.0.0.1:8026` |
| Composeプロジェクト名 | `wp-dev-wp683` |

開発対象のリポジトリは、どちらの環境でも同じ方法でマウントされます。

```text
/var/www/html/wp-content/<plugins|themes>/<slug>
/workspaces/<workspace-name>
```

## 構成の検証

```bash
docker compose -f .devcontainer/default/compose.yaml config --quiet
docker compose -f .devcontainer/wp683/compose.yaml config --quiet
```

`wp683`のコンテナ内では、次のコマンドでバージョンを確認できます。

```bash
wp core version
php --version
```

## 環境の停止

`default`を停止します。

```bash
docker compose \
  --env-file environments/default.env \
  -f .devcontainer/default/compose.yaml \
  down
```

`wp683`を停止します。

```bash
docker compose \
  -f .devcontainer/wp683/compose.yaml \
  down
```

ボリュームも削除して初期化する場合は、対象コマンドに`--volumes`を追加してください。
