#!/bin/bash

IMAGE_ID=$1
SAVE_DIR="get_images"

if [ -z "$IMAGE_ID" ]; then
    echo "引数に画像IDを指定してください"
    exit 1
fi

# 保存ディレクトリが存在しない場合は作成
mkdir -p "$SAVE_DIR"

# Content-Dispositionヘッダーからfilenameを取得
echo "Content-Dispositionからfilenameを取得します..."
content_disposition=$(curl -s -I http://127.0.0.1:5000/image/$IMAGE_ID | grep -i "Content-Disposition" | sed -n 's/.*filename="\([^"]*\)".*/\1/p' | tr -d '\r\n' | head -1)

if [ -z "$content_disposition" ]; then
    echo "エラー: filenameを取得できませんでした"
    exit 1
fi

# filenameを名前と拡張子に分割
filename="${content_disposition%.*}"  # 拡張子を除いた部分（最後の.より前）
ext="${content_disposition##*.}"      # 拡張子（最後の.以降）

# 拡張子が空の場合の処理（ドットがないファイル名の場合）
if [ "$filename" == "$content_disposition" ]; then
    filename="$content_disposition"
    ext=""
fi

echo "名前部分: $filename"
echo "拡張子部分: $ext"

# ファイル名を作成
file_name="${filename}.${ext}"
echo "作成されたファイル名: $file_name"

# 画像をダウンロードして保存（HTTPステータスコードをチェック）
echo "画像をダウンロードしています..."
http_code=$(curl -s -w "%{http_code}" -o "$SAVE_DIR/$file_name" http://127.0.0.1:5000/image/$IMAGE_ID)

if [ "$http_code" != "200" ]; then
    # エラー時は保存されたファイルを削除
    rm -f "$SAVE_DIR/$file_name"
    echo "エラー: 画像の取得に失敗しました (HTTPステータス: $http_code)"
    echo "指定された画像ID ($IMAGE_ID) はDBに存在しません"
    exit 1
fi

echo "画像を保存しました: $SAVE_DIR/$file_name"
echo "処理が完了しました。"