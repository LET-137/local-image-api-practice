#!/bin/bash

IMAGE_ID=$1
SAVE_DIR="get_images"

if [ -z "$IMAGE_ID" ]; then
    echo "引数に画像IDを指定してください"
    exit 1
fi

# 保存ディレクトリが存在しない場合は作成
mkdir -p "$save_dir"

# Content-Dispositionヘッダーからファイル名を取得
filename=$(curl -s -I http://127.0.0.1:5000/image/$IMAGE_ID | grep -i "Content-Disposition" | sed -n 's/.*filename="\([^"]*\)".*/\1/p' | tr -d '\r\n')

# ファイル名が取得できなかった場合、Content-Typeから拡張子を推測
if [ -z "$filename" ]; then
    content_type=$(curl -s -I http://127.0.0.1:5000/image/$IMAGE_ID | grep -i "Content-Type" | sed -n 's/.*Content-Type: *\([^;]*\).*/\1/p' | tr -d '\r\n' | head -1)
    case "$content_type" in
        *image/png*) ext="png" ;;
        *image/jpeg*) ext="jpg" ;;
        *image/gif*) ext="gif" ;;
        *image/webp*) ext="webp" ;;
        *image/bmp*) ext="bmp" ;;
        *image/svg*) ext="svg" ;;
        *) ext="jpg" ;;  # デフォルト
    esac
    filename="image_${IMAGE_ID}.${ext}"
fi

# 画像をダウンロードして保存
curl -s http://127.0.0.1:5000/image/$IMAGE_ID --output "$SAVE_DIR/$filename"

if [ $? -eq 0 ]; then
    echo "画像を保存しました: $SAVE_DIR/$filename"
else
    echo "エラー: 画像の取得に失敗しました"
    exit 1
fi