# cloudflare-tunnel-without-docker

Docker不要でCloudflare Tunnelを動作させるためのシェルスクリプト集。

`cloudflared`バイナリを直接ダウンロードし、トークンベースでトンネルを起動・停止する。

## 前提条件

- Linux (amd64 / arm64 / armv7l) または macOS (amd64 / arm64)
- `curl`
- Cloudflare DashboardでTunnelを作成済みであること

## セットアップ

```bash
# 1. cloudflaredバイナリをダウンロード
./src/setup.sh

# 2. トークンを設定
cp .env.example .env
# .env の TUNNEL_TOKEN にCloudflare Dashboardで取得したトークンを記載
```

## 使い方

```bash
# トンネル起動
./src/start.sh

# トンネル停止
./src/stop.sh

# cloudflaredを最新版に更新
./src/setup.sh --update
```

ログは `tmp/cloudflared.log` に出力される。

## ファイル構成

```
.
├── src/
│   ├── lib.sh       # 共通関数(プロセス検出等)
│   ├── setup.sh     # cloudflaredダウンロード・更新
│   ├── start.sh     # トンネル起動
│   └── stop.sh      # トンネル停止
├── bin/              # cloudflaredバイナリ配置先(.gitignore)
├── tmp/              # PIDファイル・ログ(.gitignore)
├── .env.example      # トークン設定テンプレート
└── .gitignore
```

## セットアップ時の検証

`setup.sh`はダウンロード時に以下を自動的に検証する:

- OSとアーキテクチャを判定し、適切なバイナリをダウンロード
- ダウンロードしたファイルが正しいバイナリ形式であることを確認
  （Linux: ELF、macOS: Mach-O）
- バイナリが実行可能であることを確認(アーキテクチャ不一致を検知)

検証に失敗した場合は不正なファイルを削除してエラー終了する。

## プロセス管理

- PIDファイル(`tmp/cloudflared.pid`)とプロセス走査の両方でプロセスを追跡する
  （Linux: `/proc`、macOS: `ps`コマンド）
- 二重起動の防止、PIDファイル消失時の検出に対応
- 外部コマンド(`pgrep`等)への依存なし
- 起動直後のクラッシュを検知し、ログを表示してエラー終了する

## セキュリティ

- トンネルトークンはコマンドライン引数ではなく環境変数経由で`cloudflared`に渡される(`ps`でトークンが表示されない)
