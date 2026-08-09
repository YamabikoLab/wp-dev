# Issue #25 実装プラン: ローカル開発環境のデバッグ情報を最小限に管理する

## 目的

Issue #25 を、ローカル開発環境として費用対効果の高い範囲に絞って実装する。

この対応では、ログを完全に無害化したり、厳密な保持基盤を構築したりすることは目指さない。

基本方針は次の 3 点とする。

1. **実データ・実認証情報を開発環境へ持ち込まない**
2. **PHP エラーを既定で画面へ表示しない**
3. **不要になった開発データを明確な手順で削除できるようにする**

本プランは実装順序と設計境界を定めるものであり、この PR では挙動変更を行わない。

## なぜスコープを絞るか

ローカル開発環境の全ログに対して、次のような対策を厳密に実装すると大きな保守コストが発生する。

- ログ内容の包括的なマスキング
- WordPress / PHP / Apache / MariaDB / Mailpit など全ログの保持期間管理
- `debug.log` の独自ローテーションや世代管理
- 専用の常駐プロセスやログ管理サービスの追加

特にマスキングは、Cookie、Authorization ヘッダー、URL、JSON、POST データ、プラグイン独自ログなど対象が際限なく広がる。

wp-dev では、これらを完全に処理するよりも、**機密データを開発環境へ入れないことを第一の防御線とする**。

## 実装方針

### 1. PHP エラー表示を既定で無効にする

`.devcontainer/shared/php/php.ini` の既定値を次へ変更する。

```ini
display_errors = Off
display_startup_errors = Off
log_errors = On
error_reporting = E_ALL
```

WordPress 側では既存の `WP_DEBUG_DISPLAY=false` を維持する。

これにより、通常の WordPress リクエストだけでなく、WordPress 初期化前、直接実行 PHP、起動時エラーについても既定では画面表示を抑制する。

必要な場合だけ、一時的に PHP エラー表示を有効化できる方法を用意する。

対象は WordPress 初期化前 / 直接実行 PHP / 起動時エラーとし、WordPress 通常リクエストでは `WP_DEBUG_DISPLAY=false` を維持する。

### 2. ログの完全マスキングは行わない

wp-dev はログ内容を自動的に完全サニタイズする責務を持たない。

代わりに、次の運用方針を README または `docs/data-retention.md` に明記する。

- 本番 DB を原則として投入しない
- 本番アップロードを原則として持ち込まない
- 実在する顧客・利用者の個人情報を使用しない
- 実在するパスワード、API キー、トークン、認証リンクをテストデータへ含めない
- 本番由来データが必要な場合は、事前に匿名化・仮名化・最小化する
- 固定の開発用サンプルデータを優先する

アプリケーションやプラグインがログへ機密情報を書き込まないようにする責務は、それぞれの実装側で扱う。

### 3. `debug.log` の独自ローテーションは今回実装しない

既存の `WP_DEBUG_LOG` は開発時の利便性を優先して維持する。

今回の Issue では、次を実装しない。

- サイズベースの独自ローテーション
- 世代数管理
- 保持日数による自動削除
- ログ管理用の常駐プロセスやサービス

代わりに、`debug.log` が開発データであり完全初期化時に削除対象となることを文書化する。

実運用でログ容量が問題になった場合のみ、実測値を基に別 Issue で対応する。

### 4. 主要データの保存場所と削除方法だけ文書化する

`docs/data-retention.md` を作成し、README から参照する。

対象は主要なデータに限定する。

| データ | 主な保存先 | 通常停止後 | 完全初期化後 | 注意事項 |
| --- | --- | --- | --- | --- |
| WordPress / uploads / `debug.log` | `wordpress_data` | 保持 | 削除 | 実データを持ち込まない |
| MariaDB | `db_data` | 保持 | 削除 | 本番 DB を原則投入しない |
| Mailpit | 実測結果を記載 | 実測結果 | 旧メールが残らないことを確認 | 実在メール・認証リンクを避ける |
| Codex CLI / GitHub CLI | 開発コンテナ領域 | コンテナのライフサイクルに従う | コンテナ再作成で削除 | 認証情報を含むため WordPress Volume へ保存しない |
| logcut 失敗ログ | `/tmp/logcut-<uid>/` | コンテナのライフサイクルに従う | コンテナ再作成で削除 | logcut 本体の仕様変更は対象外 |

PHP / Apache / MariaDB などの全ログを網羅する棚卸しは行わない。

### 5. 通常停止と完全初期化を明確にする

README で次の違いを明記する。

#### 通常停止

```bash
docker compose ... down
```

- コンテナを停止・削除する
- Named Volume は保持する
- WordPress と MariaDB の開発状態を次回へ引き継ぐ

#### 完全初期化

```bash
docker compose ... down --volumes
```

- 対象 Compose プロジェクトの Named Volume を削除する
- WordPress と MariaDB の状態が失われる
- 外部プロジェクトの bind mount 元は削除しない
- バックアップやホストへコピー済みのデータは別途残り得る

誤操作防止のため、対象 Compose プロジェクトを事前に確認できる手順を記載する。

専用クリーンアップスクリプトは、既存 Compose コマンドより明確に安全性を改善できる場合だけ追加する。

### 6. Mailpit は実測して削除方法を文書化する

現在の Compose 定義では Mailpit に Named Volume を割り当てていない。

実装時に最低限、次を確認する。

- `docker compose down` 後の再作成でメールが残るか
- 完全初期化後に旧メールが残らないか
- Mailpit API または UI でメールを削除する標準的な方法

実測結果に基づく削除・初期化方法を README または `docs/data-retention.md` に記載する。

Mailpit のためだけに新しい永続 Volume や保持管理サービスは追加しない。

## 実装フェーズ

### Phase 1: PHP エラー表示を安全側へ変更

- `display_errors=Off`
- `display_startup_errors=Off`
- `log_errors=On` / `error_reporting=E_ALL` を維持
- 必要時の限定的な opt-in 方法を追加
- `WP_DEBUG_DISPLAY=false` を維持
- `default` / `wp683` で確認

### Phase 2: データ保持・削除方針を文書化

- `docs/data-retention.md` を追加
- 実データ・実認証情報を持ち込まない方針を記載
- 通常停止と完全初期化の違いを README に記載
- WordPress / MariaDB / Codex CLI / GitHub CLI / logcut の主要な保存場所と削除方法を整理

### Phase 3: Mailpit の挙動を確認

- Mailpit の保存・削除挙動を実測
- 削除・初期化方法を文書化
- 完全初期化後に旧メールが残らないことを確認

## 検証計画

### PHP / WordPress

- opt-in 未指定時、`display_errors` / `display_startup_errors` が `Off`
- opt-in 有効時、WordPress 初期化前または直接実行 PHP ではエラー表示を有効化できる
- WordPress 通常ページでは `WP_DEBUG_DISPLAY=false` によりエラーが画面表示されない
- `WP_DEBUG_LOG` が従来どおり利用できる

### Compose

- `default` / `wp683` の双方で `docker compose ... config --quiet` が成功する
- 通常の `docker compose down` で Named Volume が保持される
- 完全初期化で対象環境の Named Volume が削除される
- `WP_PROJECT_SOURCE_PATH` の bind mount 元が削除されない

### ドキュメント

- 実データ・機密情報を持ち込まない方針が記載されている
- 通常停止と完全初期化の違いが明確になっている
- 主要データの保存場所・削除方法が現在の構成と一致する
- Mailpit の削除・初期化方法が実測結果と一致する

## 完了条件

- [ ] `display_errors` / `display_startup_errors` が既定で無効
- [ ] 必要時だけ PHP エラー表示を一時的に有効化できる
- [ ] `WP_DEBUG_DISPLAY=false` を維持する
- [ ] 実データ・実認証情報を開発環境へ持ち込まない方針が文書化されている
- [ ] WordPress / MariaDB / Mailpit / Codex CLI / GitHub CLI / logcut の主要な保存場所と削除方法が文書化されている
- [ ] 通常停止と完全初期化の違いが README に記載されている
- [ ] 完全初期化時に対象 Compose プロジェクトを確認できる
- [ ] Mailpit のメールを削除・初期化する方法が明記されている
- [ ] 完全初期化後に Mailpit の旧メールが残らない
- [ ] `default` / `wp683` の両環境で通常利用と必要なデバッグ確認が可能
- [ ] 両環境で Compose 構成検証が成功する

## 今回は実装しないこと

以下は、実際の運用で必要性が確認された場合に別 Issue として検討する。

- `debug.log` のサイズ・世代ローテーション
- ログ内容の包括的なマスキング
- 全ログの厳密な保持期間管理
- PHP / Apache / MariaDB / Mailpit などの完全なログ棚卸し
- 専用ログ管理サービスや常駐プロセスの追加

詳細な検討内容は PR / Git の履歴に残るため、旧プランを別ファイルとして保存しない。
