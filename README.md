# 画像API通信練習アプリ

ローカル環境で画像ファイルのAPI通信を実行し、同機能を理解するための練習用アプリです。

## 概要

このアプリケーションは、FlaskとMySQLを使用して画像のアップロード・取得機能を提供するREST APIです。
バイナリデータとして画像をデータベースに保存し、IDを指定して取得することができます。

## 機能

- **画像のアップロード**: 画像ファイルをバイナリデータとしてMySQLに保存
- **画像の取得**: 保存された画像IDを指定して画像を取得
- **対応画像形式**: JPEG, PNG, GIF, WebP, BMP, SVG

## セットアップ

### 1. 必要な環境

- Python 3.x
- MySQL 5.7以上
- pip

### 2. MySQLのセットアップ

MySQLでデータベースとテーブルを作成します。

```sql
CREATE DATABASE your_database_name

USE your_database_name;

CREATE TABLE images (
  id INT AUTO_INCREMENT PRIMARY KEY,
  filename VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  data LONGBLOB
); 
```

### 3. 環境変数の設定

プロジェクトルートに `.env` ファイルを作成し、以下の環境変数を設定してください。

```env
MYSQL_PASSWORD=your_mysql_password
MYSQL_DATABASE=your_database_name
```

### 4. 依存パッケージのインストール

```bash
pip install -r requirements.txt
```

### 5. サーバーの起動

```bash
python server.py
```

サーバーは `http://127.0.0.1:5000` で起動します。

## 使い方

### 画像のアップロード

`upload_images/` ディレクトリに画像ファイルを配置し、以下のコマンドでアップロードします。

```bash
chmod +x upload_image.sh
./upload_image.sh ファイル名（拡張子なし）
```

例:
```bash
./upload_image.sh test_image
```

アップロードが成功すると、データベースに保存された画像のID、ファイル名がレスポンスに含まれます。

**注意:**
- 拡張子を除いたファイル名を引数に指定してください（例: `テスト.png` の場合、`./upload_image.sh テスト`）。

### 画像の取得

保存された画像IDを指定して、画像を取得・保存します。

```bash
chmod +x get_image.sh
./get_image.sh 画像ID
```

例:
```bash
./get_image.sh 1
```

取得した画像は `get_images/` ディレクトリに、元のファイル名で保存されます。

## APIエンドポイント

### POST /upload_binary

画像をバイナリデータとしてアップロードします。

**リクエストヘッダー:**
- `Content-Type: application/octet-stream`
- `X-Filename: ファイル名.拡張子` (Base64エンコードされたファイル名も可)
- `X-Filename-Encoded: 0または1` (1の場合はX-FilenameがBase64エンコードされていることを示す)

**リクエストボディ:**
- 画像ファイルのバイナリデータ

**レスポンス:**
```json
{
  "message": "Binary upload success",
  "filename": "テスト.png",
  "id": 1
}
```

**注意:**
- 日本語ファイル名を含む場合は、Base64エンコードして`X-Filename-Encoded: 1`を設定することで正しく処理されます。
- `upload_image.sh`スクリプトは自動的にBase64エンコードを行います。

### GET /image/<id>

指定されたIDの画像を取得します。

**パスパラメータ:**
- `id`: 画像ID（整数）

**レスポンスヘッダー:**
- `Content-Type`: 画像のMIMEタイプ（画像形式に応じて自動設定）
- `Content-Disposition: inline; filename="ファイル名"`: 元のファイル名を含む

**レスポンス:**
- 成功時 (200): 画像データのバイナリ
- 失敗時 (404): JSONエラーレスポンス
  ```json
  {
    "error": "Image not found"
  }
  ```

**注意:**
- `get_image.sh`スクリプトは`Content-Disposition`ヘッダーからファイル名を取得して保存します。

## ディレクトリ構成

```
image_API/
├── server.py              # Flask APIサーバー
├── upload_image.sh        # 画像アップロード用スクリプト
├── get_image.sh           # 画像取得用スクリプト
├── upload_images/         # アップロードする画像を配置するディレクトリ
├── get_images/            # 取得した画像を保存するディレクトリ
├── requirements.txt       # Python依存パッケージ
└── README.md             # このファイル
```

## 技術スタック

- **フレームワーク**: Flask
- **データベース**: MySQL
- **データベース接続**: mysql-connector-python
- **環境変数管理**: python-dotenv

## アーキテクチャ

### データフロー

#### 画像アップロード
1. `upload_image.sh`が`upload_images/`ディレクトリから画像ファイルを読み込む
2. ファイル名をBase64エンコードしてHTTPヘッダーに設定（日本語対応）
3. 画像のバイナリデータを`POST /upload_binary`エンドポイントに送信
4. サーバーがMySQLの`images`テーブルにバイナリデータを保存
5. データベースに保存された画像IDをレスポンスで返す

#### 画像取得
1. `get_image.sh`が画像IDを指定して`GET /image/<id>`エンドポイントにリクエスト
2. サーバーがデータベースから画像データを取得
3. ファイル名とContent-Typeを適切なHTTPヘッダーに設定して画像データを返す
4. クライアントが`Content-Disposition`ヘッダーからファイル名を取得
5. 画像を`get_images/`ディレクトリに保存

## 学習ポイント

1. **バイナリデータの扱い**: 画像をバイナリデータとして扱う方法
2. **HTTPヘッダーの活用**: ファイル名をヘッダーで渡す方法、Base64エンコーディングの活用
3. **Content-Typeの設定**: 適切なContent-Typeヘッダーの設定と拡張子からの自動判定
4. **データベースへのバイナリ保存**: LONGBLOB型を使った画像データの保存
5. **RESTful APIの設計**: シンプルなREST APIの実装
6. **curlコマンドの活用**: シェルスクリプトからのAPI呼び出し

## 注意事項

- このアプリは学習・練習用です。本番環境で使用する場合は、適切なエラーハンドリング、認証、セキュリティ対策を実装してください。
- 大きな画像ファイルを扱う場合、メモリ使用量に注意してください。
