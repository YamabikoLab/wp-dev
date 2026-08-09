# Issue #25 実装プラン: デバッグログと開発データの表示・保持制御

## 目的

Issue #25「デバッグログと開発データの表示・保持期間を制限する」を、現在の `wp-dev` 構成に合わせて段階的に実装する。

主な目的は次のとおり。

- PHP エラーのブラウザ表示を既定で無効化し、必要な場合だけ明示的に有効化できるようにする。
- WordPress の `debug.log` を無制限に保持しない。
- WordPress、MariaDB、Mailpit、logcut などの開発データについて、保存場所・存続条件・削除方法を明確にする。
- 通常停止と完全初期化を明確に分け、意図しない Docker Volume 削除を防ぐ。
- 実データや機密情報を開発環境へ持ち込まない運用を文書化する。

本プランは実装順序と設計境界を定めるものであり、この PR では挙動変更を行わない。

## 現在の構成

Issue #25 作成後に関連するセキュリティ対応が進んでいるため、Issue 本文をそのまま実装対象にはしない。

### PHP

`.devcontainer/shared/php/php.ini` では現在、次の設定になっている。

```ini
display_errors = On
display_startup_errors = On
log_errors = On
error_reporting = E_ALL
```

WordPress 側では `docker/compose.shared.yaml` により次が設定されている。

```php
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
```

したがって、WordPress の通常処理では画面表示を抑制していても、WordPress 初期化前、直接実行する PHP、起動時エラーなどは別途対策が必要である。

また、`WP_DEBUG_DISPLAY=false` の場合は WordPress 初期化後に `display_errors` が無効化されるため、PHP 側の opt-in を有効にしても通常の WordPress リクエストへは反映されない。この挙動を安全側の境界として採用する。

### 永続データ

現在の共有 Compose 定義で明示的に使用している Named Volume は次の 2 つである。

- `wordpress_data`
- `db_data`

Mailpit には Named Volume を割り当てていない。

Codex CLI と GitHub CLI の認証情報は、Issue #22 / #38 などの対応後、WordPress 用 Named Volume として永続化していない。README でも `/home/developer/.codex` と `/home/developer/.config/gh` を開発コンテナ内の一時的な領域として扱っている。

このため、Issue #25 に記載されている `codex_data` / `gh_config` の保持制御を新たに実装することは本対応の対象外とする。必要なのは、現在の保存場所とライフサイクルをデータ一覧へ正しく反映することである。

### logcut

Issue #25 の対象は、wp-dev 内で利用する際の保存場所・削除方法・注意事項の整理までとする。

logcut 本体の保持仕様やローテーション仕様の変更は対象外とする。

## 設計方針

### 1. 既定値は安全側にする

PHP の既定値を次へ変更する。

```ini
display_errors = Off
display_startup_errors = Off
log_errors = On
error_reporting = E_ALL
```

エラー情報はログで確認できる状態を維持する。

### 2. エラー表示は限定的な opt-in にする

PHP エラー表示の opt-in は、WordPress 初期化前、直接実行する PHP、起動時エラーなど、WordPress が `display_errors` を上書きしない範囲だけを対象とする。

通常の WordPress リクエストでは `WP_DEBUG_DISPLAY=false` を維持し、常に画面へ PHP エラーを表示しない。WordPress 内のエラー確認は `debug.log` などのログを利用する。

候補は、Compose から渡す 1 個の明示的な環境変数で `display_errors` と `display_startup_errors` を同時に切り替える方法とする。

実装時には、使用中の PHP Docker イメージで `php.ini` の環境変数展開が期待どおり動作することを先に確認する。直接展開できない場合は、起動時に小さな override ini を生成する方式へ切り替える。

要件は次のとおり。

- 変数未指定時は必ず `Off`。
- `default` と `wp683` で同じ仕組みを使う。
- opt-in の対象が WordPress 初期化前 / 直接実行 PHP に限定されることを文書化する。
- 一時的に有効化する手順と、元へ戻す手順を README または focused doc に記載する。
- WordPress の `WP_DEBUG_DISPLAY=false` は維持する。
- WordPress 初期化後の通常ページでは、opt-in の有無にかかわらず PHP エラーが画面表示されないことを確認する。

### 3. `debug.log` に明示的な上限を設け、HTTP 公開可否も確認する

`WP_DEBUG_LOG` を維持する場合、`wp-content/debug.log` を無制限に成長させない。

あわせて、標準の `wp-content/debug.log` が HTTP 経由で取得可能かを実測する。取得可能な場合は、次のいずれかを採用する。

- `WP_DEBUG_LOG` をドキュメントルート外の明示パスへ移す。
- Web サーバー側で対象ログへのアクセスを拒否する。

採用した保存場所とアクセス制御は、ローテーション設計および `docs/data-retention.md` に反映する。

実装方式は次の条件を満たすものを選ぶ。

- コンテナ起動時だけでなく、長時間起動中にも上限が機能する。
- WordPress / Apache の通常動作を妨げない。
- `debug.log` の所有者・権限を壊さない。
- `default` と `wp683` で共有設定を利用する。
- 専用の常駐サービス追加が必要な場合は、そのコストを採用理由とともに記録する。

第一候補はサイズベースのローテーションとし、実装前に実効性を確認する。

暫定目標値は次とする。

- 1 ファイルあたり最大 10 MiB 程度。
- 現行ファイルを除き最大 3 世代程度。
- 古い世代は自動削除する。

値を変更する場合は、開発時の診断性と保持リスクのバランスを PR に記載する。

ログへ次を不用意に出力しない方針も文書化する。

- パスワード
- Cookie
- Authorization ヘッダー
- API キー / トークン
- 個人情報
- 本番由来の機密データ

### 4. データ保持ポリシーを 1 箇所へ集約する

新しい focused doc として `docs/data-retention.md` を作成し、README から参照する。

最低限、次の列を持つ一覧を作る。

| データ | 保存場所 | 永続化方式 | 通常停止後 | 完全初期化後 | 削除方法 | 注意事項 |
| --- | --- | --- | --- | --- | --- | --- |
| WordPress 本体・アップロード・`debug.log` | 実装後の `WP_DEBUG_LOG` 実パス / `wordpress_data` | Named Volume または採用したログ保存方式 | 保持 | 削除 | Compose 経由 | HTTP 公開可否を確認し、実データを持ち込まない |
| MariaDB | `db_data` 内 | Named Volume | 保持 | 削除 | Compose 経由 | 本番 DB を原則投入しない |
| Mailpit | 実装時に実測確認 | Named Volume なし | 実測結果を記載 | 削除されることを確認 | Mailpit / Compose | 実在メール・認証リンクを避ける |
| Codex CLI | `/home/developer/.codex` | コンテナ領域 | ライフサイクルを記載 | 削除 | コンテナ再作成 | 認証情報を含む |
| GitHub CLI | `/home/developer/.config/gh` | コンテナ領域 | ライフサイクルを記載 | 削除 | コンテナ再作成 | 認証情報を含む |
| logcut 失敗ログ | `/tmp/logcut-<uid>/` | コンテナ一時領域 | ライフサイクルを記載 | 削除 | ファイル削除 / コンテナ再作成 | ログ内容に注意 |
| PHP / Apache その他ログ | 実装時に棚卸し | 実測結果 | 実測結果 | 実測結果 | 実測結果 | 不要な長期保持を避ける |

保存場所やライフサイクルを推測で記載せず、実装時にコンテナ内で確認した結果を正とする。

### 5. 通常停止と完全初期化を明確に分ける

README では次を明確にする。

#### 通常停止

```bash
docker compose ... down
```

- コンテナを停止・削除する。
- Named Volume は保持する。
- WordPress と MariaDB の開発状態を次回へ引き継ぐ用途とする。

#### 完全初期化

```bash
docker compose ... down --volumes
```

- 対象 Compose プロジェクトの Named Volume を削除する。
- WordPress と MariaDB の状態が失われる。
- Mailpit など Named Volume を使わないデータについても、実際のライフサイクルを確認して記載する。
- ホスト側の外部プロジェクト `WP_PROJECT_SOURCE_PATH` は削除対象にしない。
- バックアップやホストへコピー済みのデータは別途残り得ることを明記する。

### 6. 安全確認付きの完全初期化を用意する

破壊的操作の誤実行を減らすため、完全初期化用スクリプトを追加する方向で実装する。

想定する責務は次のとおり。

1. 対象環境名を明示的に受け取る。
2. 対応する env ファイルと Compose entry point を解決する。
3. 実行前に Compose プロジェクト名を表示する。
4. 削除される Named Volume を表示または確認できるようにする。
5. 明示的な確認後だけ `down --volumes` を実行する。
6. 外部プロジェクトの bind mount 元を削除しない。

環境ファイルを shell の `source` / `eval` で安易に読み込まない。Compose 自身が解決した設定を利用する方法を優先する。

スクリプトが既存の Compose コマンドより安全性を改善しない場合は、スクリプト追加を見送り、README の確認手順を source of truth とする。その判断は実装 PR に記録する。

### 7. Mailpit の保持挙動を実測して決める

現在の Compose 定義では Mailpit に Named Volume を割り当てていないため、新たな永続化を前提にしない。

実装時に次を確認する。

- メールがコンテナ内のどこに保存されるか。
- コンテナ停止だけで保持されるか。
- `docker compose down` 後の再作成で残るか。
- 完全初期化時に旧メールが残らないか。
- Mailpit API または UI で手動削除する標準的な方法があるか。

保持期間や件数上限を追加する場合も、Mailpit のためだけに新しい永続 Volume を導入しないことを基本方針とする。

### 8. 実データを持ち込まない

README または `docs/data-retention.md` に次を明記する。

- 本番 DB を原則として投入しない。
- 本番アップロードを原則として持ち込まない。
- 実在する顧客・利用者の個人情報を使用しない。
- 実在する認証情報、パスワード再設定 URL、API キー、トークンをテストデータへ含めない。
- 本番由来データが不可避な場合は、事前に匿名化・仮名化・最小化する。
- 固定の開発用サンプルデータを優先する。

## 実装フェーズ

大きな変更を 1 PR に詰め込まず、責務ごとに分けて進める。

### Phase 1: PHP エラー表示の既定値を安全側へ変更

対象候補:

- `.devcontainer/shared/php/php.ini`
- `docker/compose.shared.yaml`
- `environments/*.env.example`
- README または focused doc

実施内容:

- `display_errors=Off`。
- `display_startup_errors=Off`。
- `log_errors=On` / `error_reporting=E_ALL` を維持。
- WordPress 初期化前 / 直接実行 PHP に限定した一時的な opt-in の方法を追加。
- `WP_DEBUG_DISPLAY=false` は維持し、WordPress 通常リクエストでは常に非表示とする。
- `default` / `wp683` で共通化。

### Phase 2: WordPress `debug.log` の上限管理と公開範囲確認

対象候補:

- `.devcontainer/shared/`
- `docker/compose.shared.yaml`
- 必要に応じてログローテーション用設定・スクリプト
- 必要に応じて Apache 側のアクセス制御
- `docs/data-retention.md`

実施内容:

- `debug.log` の所有者・権限・実パスを確認。
- `wp-content/debug.log` が HTTP 経由で取得できないかを `default` / `wp683` の両方で確認。
- HTTP 取得可能な場合は、ドキュメントルート外への移動または Web サーバー側のアクセス拒否を実装。
- 採用した `WP_DEBUG_LOG` の保存場所をローテーション設計と `docs/data-retention.md` に反映。
- サイズベースの自動ローテーションを実装。
- 世代数とサイズ上限を設定。
- 長時間起動中にも機能することを確認。

### Phase 3: データ保持ポリシーと安全な初期化手順

対象候補:

- `docs/data-retention.md`
- README
- 必要に応じて完全初期化用スクリプト

実施内容:

- WordPress / MariaDB / Codex CLI / GitHub CLI / logcut / PHP / Apache の保存場所とライフサイクルを実測。
- 通常停止と完全初期化を文書化。
- 完全初期化時に対象 Compose プロジェクトと Named Volume を確認する手順を用意。
- 外部プロジェクトの bind mount が削除されないことを確認。

### Phase 4: Mailpit と残りの一時データを確認

実施内容:

- Mailpit の保存・削除挙動を実測。
- 必要なら手動削除方法を文書化。
- PHP、Apache、WordPress 以外の主要な一時ログを確認。
- 不要な長期保持があれば最小限の対策を追加。

## 検証計画

実装 PR ごとに、その PR に関係する範囲だけを検証する。

### PHP / WordPress

- opt-in 未指定時、`display_errors` / `display_startup_errors` が `Off` であること。
- opt-in 有効時、WordPress 初期化前または直接実行 PHP では PHP エラー表示が有効になること。
- opt-in 有効時でも、WordPress 初期化後の通常ページでは `WP_DEBUG_DISPLAY=false` により PHP エラーが画面表示されないこと。
- `WP_DEBUG_LOG` が引き続き機能すること。

### `debug.log`

- `default` / `wp683` の双方で `debug.log` の実パスを確認する。
- HTTP 経由でログを直接取得できないことを確認する。
- 取得可能だった構成では、採用した対策後に HTTP アクセスが拒否されることを確認する。
- ローテーションが指定サイズ付近で発生すること。
- 世代数上限を超えた古いログが削除されること。
- 所有者・権限が壊れないこと。

### Compose

- 通常の `docker compose down` で Named Volume が保持されること。
- 完全初期化で対象環境の Named Volume だけが削除されること。
- `WP_PROJECT_SOURCE_PATH` の bind mount 元が削除されないこと。

### データ保持

- `docs/data-retention.md` の保存場所・ライフサイクルが実測結果と一致すること。
- Codex CLI / GitHub CLI / logcut / Mailpit の扱いが現在の構成と一致すること。

## Issue #25 の完了条件との対応

| Issue #25 の完了条件 | 対応 Phase |
| --- | --- |
| `display_errors` / `display_startup_errors` を既定で無効化 | Phase 1 |
| 必要時だけ PHP エラー表示を有効化 | Phase 1。ただし WordPress 初期化前 / 直接実行 PHP に限定 |
| `debug.log` に容量または期間の上限 | Phase 2 |
| `debug.log` の HTTP 公開範囲を安全にする | Phase 2 |
| 古い WordPress デバッグログを自動削除 / ローテーション | Phase 2 |
| 主要データの保存場所と保持方針を文書化 | Phase 3 / 4 |
| 通常停止と完全初期化の違いを README へ記載 | Phase 3 |
| Docker Volume を安全に削除する手順 | Phase 3 |

## 対象外

- 本番環境向けのログ集約基盤。
- logcut 本体の保持仕様変更。
- Issue #22 / #38 で解消済みの `codex_data` / `gh_config` Named Volume の再設計。
- 外部プロジェクトのソースコード変更。

## 実装時の進め方

1. Phase 1 から順に、責務の小さい PR として実装する。
2. Phase 2 のローテーション方式は、常駐プロセス追加の要否と `debug.log` の HTTP 公開可否を確認してから確定する。
3. Phase 3 で実測した保存場所・ライフサイクルを `docs/data-retention.md` の source of truth とする。
4. Phase 4 で Mailpit と残りの一時データを埋め、Issue #25 の完了条件を最終確認する。
5. 必要なら各 Phase を Issue #25 の子 Issue として切り出すが、重複する要件は親 Issue 側へ残さず参照関係を明確にする。
