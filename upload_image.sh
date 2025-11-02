#!/bin/bash

LOAD_DIR="upload_images"
BASE_NAME=$1

if [ -z "$BASE_NAME" ]; then
    echo "引数に画像ファイル名を指定してください"
    exit 1
fi

mkdir -p "$LOAD_DIR"

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

curl -X POST http://127.0.0.1:5000/upload_binary \
     -H "Content-Type: application/octet-stream" \
     -H "X-Filename: $BASE_NAME.$ext" \
     --data-binary "@$file_path"