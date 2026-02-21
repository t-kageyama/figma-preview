# figma-preview docker

Figmaプロトタイプを、制約のない実験環境として動かすための最小Docker環境。

> - 固定ファイル差し替えで挙動を検証
> - URLだけで顧客に共有  
> - 簡単に撤収できるDocker環境

## Why?

Figma AIで画面遷移を作ってみたところ、想像以上に実用的なプロトタイプがすぐに出来上がりました。
しかし次のようなことをやろうとすると、ブラウザ上（Figmaサイト上）では制約が多く、自由な検証が難しくなります。

- 固定ファイルを書き換えて挙動を変えたい
- ローカルデータで条件分岐を試したい
- 顧客にURLだけで触ってもらいたい
- アカウント作成なしで確認してもらいたい

そこで、

- Figmaからダウンロードしたソースを
- 自分の管理下で動かし
- 固定ファイル差し替えで挙動を変え
- そして簡単に撤収できる

小さなDocker環境を用意しました。

## Use Case

#### 1. 顧客に画面遷移を軽く見てもらう

- URLを渡すだけ
- ログイン不要
- 好きな時間に確認できる
- デザインツールUIなし

#### 2. 固定ファイルで挙動を検証する

APIを作り込む前に、固定JSONを書き換えて挙動を素早く検証できます。

本プロジェクトは`API実装`ではなく、固定ファイル差し替えによる挙動確認を主目的としています。

## Prerequisites（必須）

- Docker
- docker compose
- Figmaからエクスポートした `project.zip` ファイル

⚠ `project.zip` が存在しない場合、構築・更新は失敗します。

## Figmaからのダウンロード方法
（確認日: 2026-02-21）

1. Figmaサイトで対象のFigmaファイルを開く
1. Export / Download
1. HTML形式でエクスポート
1. `project.zip` を取得

※ FigmaのUIは変更される可能性があります。
最新の操作方法は公式ドキュメントをご確認ください。

### 1. 構築

`project.zip` をプロジェクトディレクトリに配置した後、docker composeを実行します。

```bash
$ docker compose build
$ docker compose up
```

起動後、ブラウザで指定ポートにアクセスしてください。

### 2. 更新
#### 2-1. Figmaデザインを更新する場合（project.zip → update_src.sh）

`update_src.sh` は `Dockerfile` / `docker-compose.yml` と同じディレクトリにあります。

1. Figmaから再度 `project.zip` をエクスポート
2. `project.zip` を置き換え
`docker-compose.yml` のある該当ディレクトリに `project.zip` をコピーして以下のコマンドを実行すればプロジェクトが更新されます。

```bash
$ ./update_src.sh
```

⚠ `project.zip` が同じディレクトリに存在しない場合、更新は失敗します。

3. 必要ならコンテナを再起動
自動更新が動作しない場合に実行してください。

```bash
$ docker compose restart
```

### 固定ファイル配信（nginx例）

```nginx
location /myshop/api/ {
  alias /var/www/ojizo/myshop/api/;
  try_files $uri =404;

  add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0" always;
  add_header Pragma "no-cache" always;
  expires -1;
}
```

#### なぜキャッシュ無効が必須か？

固定ファイルを書き換え、

```
「条件を反映しました。再度実行してください」
```

と案内する運用を想定しています。

キャッシュが有効だと古いデータが返り、挙動確認が成立しません。

### 3. 撤収
```bash
$ docker compose down
```

コンテナを停止すれば環境は撤収できます。
ホストに依存パッケージを残さない設計です。

## Customization（環境の調整）

### タイムゾーン変更

`Dockerfile` 内で変更できます。

```dockerfile
ENV TZ=Asia/Tokyo
```

### ポート変更の考え方

ホスト側ポートのみ変更します。
同一ホスト上で本プロジェクトを複数起動する場合や、
既に 5173 ポートが利用されている場合を主に想定しています。
`docker-compose.yml` を以下のように変更します。

```yaml
services:
  figma:
    ports:
      - "5174:5173"  # ホスト:コンテナ
```

- 左側：ホスト側ポート（よく変更する）
- 右側：コンテナ内部ポート（通常は固定）

```
迷ったら docker-compose.yml の該当行の左側だけ変更してください。
```

### コンテナ内部ポートの変更について

`Dockerfile`内の

```dockerfile
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173"]
```

を変更することも可能ですが、
これはより複雑な構成へ発展させたい方向けの調整であり、本プロジェクトの想定範囲外です。

### サブディレクトリで公開する場合

例:
```md
例:
https://example.com/myapp/
```

`docker-compose.yml` に環境変数を追加します。

```yaml
services:
  figma:
    environment:
      VITE_BASE: "/myapp/"
      VITE_ALLOWED_HOSTS: "example.com"
```

nginx側の設定もあわせて調整してください。
以下に一例を示します。proxy_pass等の値はご自身の環境に合わせて変更してください。

```nginx
location /myapp/ {
        proxy_pass http://127.0.0.1:5173;
        proxy_http_version 1.1;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
}
```

### Design Philosophy

- APIを作り込まない
- 固定ファイルで挙動を検証する
- URLで軽く見せる
- 環境は簡単に消せる

試すためだけの環境は、簡単に立ち上げられて、簡単に消せるべきだと考えています。

<hr>

# figma-preview docker

A minimal Docker environment to run Figma prototypes as a constraint-free experimentation workspace.

> - Validate behavior by swapping fixed files
> - Share with clients via a simple URL  
> - Tear down easily when done

## Why?

When using Figma AI to create screen transitions, I found that surprisingly practical prototypes could be generated very quickly.

However, when trying to:

- Change behavior by editing fixed files
- Test conditional flows using local data
- Share via a simple URL
- Allow clients to review without creating accounts

the Figma web environment (browser-based) introduces limitations that make free experimentation difficult.

So I created a small Docker-based environment that:

- Runs the exported Figma source locally
- Allows behavior changes by swapping fixed files
- Allows behavior changes by swapping fixed files
- Can be removed cleanly

## Use Cases

#### 1. Lightly share screen transitions with clients

- Share via URL only
- No login required
- Clients can review at their own pace
- No design-tool UI visible

#### 2. Validate behavior using fixed files

Before building a real API, you can quickly test behavior by editing fixed JSON files.

This project is `not intended for API implementation`, but for validating behavior by swapping fixed files.

## Prerequisites

- Docker
- docker compose
- `project.zip` exported from Figma

⚠ If `project.zip` is missing, build and update will fail.

## How to download from Figma
(Confirmed as of 2026-02-21)

1. Open the target Figma file
1. Export / Download
1. Export as HTML
1. Obtain`project.zip`

Note: Figma UI may change in the future. Please refer to official documentation if needed.

### 1. Build

Place `project.zip` in the project directory, then run:

```bash
$ docker compose build
$ docker compose up
```

Access the specified port in your browser.

### 2. Update
#### 2-1. Updating the Figma design (project.zip → update_src.sh)

`update_src.sh` is located in the same directory as `Dockerfile` and `docker-compose.yml`.

1. Export a new `project.zip` from Figma
2. Replace the existing `project.zip`
3. Run:

```bash
$ ./update_src.sh
```

⚠ If `project.zip` is not in the same directory, the update will fail.

3. Restart the container if necessary:

```bash
$ docker compose restart
```

### Fixed file delivery （nginx example）

```nginx
location /myshop/api/ {
  alias /var/www/ojizo/myshop/api/;
  try_files $uri =404;

  add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0" always;
  add_header Pragma "no-cache" always;
  expires -1;
}
```

#### Why disabling cache is required?

The expected workflow is:

```
"The condition has been updated. Please reload."
```

If caching is enabled, outdated data may be returned and validation will fail.

### 3. Cleanup
```bash
$ docker compose down
```

Stopping the container removes the environment cleanly.
No dependencies remain on the host.

## Customization

### Change timezone

Modify in`Dockerfile`:

```dockerfile
ENV TZ=Asia/Tokyo
```

### Port configuration

In most cases, only change the **host-side port**:

```yaml
services:
  figma:
    ports:
      - "5174:5173"  # host:container
```

- Left: host port (commonly changed)
- Right: container internal port (usually fixed)

```
If unsure, change only the host-side port.
```

### Changing the container internal port

You may modify:

```dockerfile
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173"]
```

However, this is outside the intended scope of this project and is meant for more advanced Docker customization.

### Serving under a subdirectory

```md
Example:
https://example.com/myapp/
```

Add environment variables in `docker-compose.yml`:

```yaml
services:
  figma:
    environment:
      VITE_BASE: "/myapp/"
      VITE_ALLOWED_HOSTS: "example.com"
```

Adjust nginx accordingly:
replace proxy_pass or other values according to your host environments.

```nginx
location /myapp/ {
        proxy_pass http://127.0.0.1:5173;
        proxy_http_version 1.1;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
}
```

### Design Philosophy

- Do not overbuild APIs
- Validate behavior using fixed files
- Share via simple URLs
- Keep the environment disposable

An environment created just for experimentation should be easy to start and easy to remove.