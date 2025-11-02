#!/bin/bash

LOAD_DIR="upload_images"
BASE_NAME=$1

if [ -z "$BASE_NAME" ]; then
    echo "引数に画像ファイル名を指定してください"
    exit 1
fi

mkdir -p "$LOAD_DIR"

FILE_PATH=""
ext=""
for f in $LOAD_DIR/${BASE_NAME}.*; do 
    if [[ -f "$f" ]]; then
        FILE_PATH=$f
        ext=$(echo $f | awk -F '.' '{print $NF}')
        if [ -z "$ext" ]; then
            echo "エラー: $f に拡張子が見つかりません"
            exit 1
        fi
        break
        # mimetype=$(file --mime-type -b "$f")

        # case "$mimetype" in
        #     image/jpeg) ext="jpg" ;;
        #     image/png)  ext="png" ;;
        #     image/gif)  ext="gif" ;;
        #     image/webp) ext="webp" ;;
        #     *) ext="" ;;
        # esac
        
        # if [ -n "$ext" ]; then
        #     if [[ $f == $LOAD_DIR/$BASE_NAME.$ext ]]; then
        #         FILE_PATH=$LOAD_DIR/$BASE_NAME.$ext
        #         break
        #     else
        #         FILE_PATH=$f
        #         break
        #     fi
        # fi
    fi
done

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    echo "エラー: $LOAD_DIR/${BASE_NAME}.* に画像ファイルが見つかりません"
    exit 1
fi

curl -X POST http://127.0.0.1:5000/upload_binary \
     -H "Content-Type: application/octet-stream" \
     -H "X-Filename: $BASE_NAME.$ext" \
     --data-binary "@$FILE_PATH"