# 開発データの保持と初期化

wp-dev はローカル開発環境です。ログや開発データを完全にサニタイズする仕組みは提供しないため、**本番データや実認証情報を持ち込まないこと**を第一の防御線とします。

## 開発データの取り扱い

次のデータは原則として開発環境へ投入しないでください。

- 本番データベース
- 本番アップロード
- 実在する顧客・利用者の個人情報
- 実在するパスワード、API キー、トークン、認証リンク

本番由来データが必要な場合は、事前に匿名化・仮名化・最小化してください。可能な限り固定の開発用サンプルデータを使用してください。

wp-dev はログ内容の包括的なマスキングを行いません。アプリケーションやプラグインが機密情報をログへ出力しないようにする責務は、それぞれの実装側で扱います。

## PHP エラー表示

PHP の `display_errors` と `display_startup_errors` は既定で `Off` です。`log_errors=On` と `error_reporting=E_ALL` は維持します。

一時的に WordPress 初期化前、直接実行 PHP、起動時エラーの表示が必要な場合は、使用する `environments/*.env` で次を設定し、対象コンテナを再作成してください。

```dotenv
PHP_DISPLAY_ERRORS=On
```

確認後は必ず次へ戻してください。

```dotenv
PHP_DISPLAY_ERRORS=Off
```

WordPress 通常リクエストでは `WP_DEBUG_DISPLAY=false` を維持します。そのため、`PHP_DISPLAY_ERRORS=On` の場合でも WordPress 初期化後の通常ページでは PHP エラーを画面表示しない方針です。

## 主な保存場所と削除方法

| データ | 主な保存先 | `docker compose down` 後 | `down --volumes` 後 | 削除・初期化方法 |
| --- | --- | --- | --- | --- |
| WordPress 本体 / uploads / `wp-content/debug.log` | `wordpress_data` Named Volume | 保持 | 削除 | 対象 Compose プロジェクトで `down --volumes` |
| MariaDB | `db_data` Named Volume | 保持 | 削除 | 対象 Compose プロジェクトで `down --volumes` |
| Mailpit メール | Mailpit の一時 SQLite DB。wp-dev では永続 Volume を割り当てない | Mailpit コンテナ削除・再作成で消去 | 消去 | Web UI の `Delete all`、または Mailpit コンテナの再作成 |
| Codex CLI 認証 | `/home/developer/.codex` | コンテナのライフサイクルに従う | コンテナ再作成で消去 | Dev Container / WordPress コンテナを再作成し、必要なら再認証 |
| GitHub CLI 認証 | `/home/developer/.config/gh` | コンテナのライフサイクルに従う | コンテナ再作成で消去 | Dev Container / WordPress コンテナを再作成し、必要なら再認証 |
| logcut 失敗ログ | `/tmp/logcut-<uid>/` | コンテナのライフサイクルに従う | コンテナ再作成で消去 | コンテナ再作成、または logcut の運用に従って削除 |

`WP_PROJECT_SOURCE_PATH` はホスト上の外部プロジェクトを bind mount するため、`down --volumes` では削除されません。ホストへ別途コピーしたバックアップやエクスポートも削除されません。

## WordPress Core バージョンの不一致

wp-dev は `WORDPRESS_IMAGE_TAG` で選択した Docker image 内の WordPress Core を正として扱います。起動時に image 側の `/usr/src/wordpress` と `wordpress_data` volume 側の `/var/www/html` のバージョンを比較し、一致しない場合は起動を失敗させます。

例えば、`default` を WordPress 7.1.0 に更新した後も既存 volume に WordPress 7.0.4 が残っている場合は、次のようなエラーになります。

```text
Expected WordPress 7.1.0, but the current WordPress volume contains 7.0.4.
Recreate the WordPress volume before continuing.
```

Core の自動更新は wp-dev 側で無効化されますが、選択した image と異なる Core が残っている `wordpress_data` volume は自動的に置き換えられません。その場合は、対象 Compose プロジェクトを確認したうえで、後述の「完全初期化」を実行してください。

`down --volumes` は WordPress 本体だけでなく MariaDB の `db_data` も削除します。必要な開発データがある場合は、実行前に退避してください。

## 通常停止と完全初期化

### 通常停止

通常の停止では Named Volume を保持します。

```bash
docker compose \
  --env-file environments/default.env \
  -f .devcontainer/default/compose.yaml \
  down
```

WordPress と MariaDB の状態は次回起動へ引き継がれます。Mailpit は永続 Volume を使用していないため、コンテナ削除・再作成後は以前のメールを引き継ぎません。

### 完全初期化

完全初期化は WordPress と MariaDB の Named Volume を削除する破壊的操作です。実行前に対象 Compose プロジェクトを確認してください。

```bash
docker compose \
  --env-file environments/default.env \
  -f .devcontainer/default/compose.yaml \
  ps
```

対象が正しいことを確認してから実行します。

```bash
docker compose \
  --env-file environments/default.env \
  -f .devcontainer/default/compose.yaml \
  down --volumes
```

`wp704` では `environments/wp704.env` と `.devcontainer/wp704/compose.yaml`、`wp683` では `environments/wp683.env` と `.devcontainer/wp683/compose.yaml` を使用してください。

## Mailpit の削除・初期化

wp-dev の Mailpit サービスには `MP_DATABASE` や永続 Volumeを設定していません。Mailpit の既定動作では一時 SQLite DB が使用され、Mailpit プロセス終了時に削除されます。

メールだけを削除したい場合は Mailpit Web UI の Inbox で `Delete all` を使用できます。

環境単位で初期化する場合は、対象 Compose プロジェクトの Mailpit コンテナを削除・再作成します。通常の `docker compose down` でも Mailpit コンテナが削除されるため、再作成後に旧メールが残らない構成です。

実環境での検証では、`default`、`wp704`、`wp683` の各環境でメールを投入した後に停止・再作成し、旧メールが残っていないことを確認してください。

## 構成検証

変更後は各環境の Compose 構成を確認します。

```bash
docker compose --env-file environments/default.env -f .devcontainer/default/compose.yaml config --quiet
docker compose --env-file environments/wp704.env -f .devcontainer/wp704/compose.yaml config --quiet
docker compose --env-file environments/wp683.env -f .devcontainer/wp683/compose.yaml config --quiet
```
