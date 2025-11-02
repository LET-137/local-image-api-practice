#!/bin/bash

LOAD_DIR="upload_images"
BASE_NAME=$1

if [ -z "$BASE_NAME" ]; then
    echo "引数に画像ファイル名を指定してください"
    exit 1
fi

mkdir -p "$LOAD_DIR"

echo "ファイルを検索しています: $LOAD_DIR/${BASE_NAME}.*"

file_path=""
ext=""
for f in $LOAD_DIR/${BASE_NAME}.*; do 
    if [[ -f "$f" ]]; then
        file_path=$f
        ext=$(echo $f | awk -F '.' '{print $NF}')
        if [ -z "$ext" ]; then
            echo "エラー: $f に拡張子が見つかりません"
            exit 1
        fi
        break
    fi
done

if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
    echo "エラー: $LOAD_DIR/${BASE_NAME}.* に画像ファイルが見つかりません"
    exit 1
fi

echo "サーバーにアップロードしています..."

# 実際のファイル名を取得（basenameでパスからファイル名のみを抽出）
actual_filename=$(basename "$file_path")

# ファイル名をBase64エンコードしてHTTPヘッダーで安全に送信
if command -v python3 &> /dev/null; then
    encoded_filename=$(python3 -c "import base64, sys; print(base64.b64encode(sys.argv[1].encode('utf-8')).decode('ascii'))" "$actual_filename")
    encoded_flag="1"  # Base64エンコードされていることを示すフラグ
else
    # Pythonがない場合はそのまま（文字化けする可能性あり）
    encoded_filename="$actual_filename"
    encoded_flag="0"
fi

response=$(curl -s -w "\n%{http_code}" -X POST http://127.0.0.1:5000/upload_binary \
     -H "Content-Type: application/octet-stream" \
     -H "X-Filename: $encoded_filename" \
     -H "X-Filename-Encoded: $encoded_flag" \
     --data-binary "@$file_path")

http_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" -eq 200 ]; then
    echo "レスポンス: $body"
    echo "処理が完了しました。"
else
    echo "エラー: アップロードに失敗しました (HTTPステータスコード: $http_code)"
    echo "レスポンス: $body"
    exit 1
fi