from flask import Flask, request, jsonify
from dotenv import load_dotenv
import mysql.connector
import os
from urllib.parse import quote

load_dotenv()
MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD')
MYSQL_DATABASE = os.getenv('MYSQL_DATABASE')

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False  # 日本語をUnicodeエスケープせずに表示

# 拡張子からContent-Typeを取得する関数
def get_content_type(filename):
    """ファイル名から拡張子を取得し、適切なContent-Typeを返す"""
    ext = os.path.splitext(filename)[1].lower()
    content_types = {
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.gif': 'image/gif',
        '.webp': 'image/webp',
        '.bmp': 'image/bmp',
        '.svg': 'image/svg+xml',
    }
    return content_types.get(ext, 'image/jpeg')  # デフォルトはjpeg

# MySQL接続設定
db_config = {
    'user': 'root',
    'password': MYSQL_PASSWORD,
    'host': 'localhost',
    'database': MYSQL_DATABASE,
    'charset': 'utf8mb4',
    'collation': 'utf8mb4_unicode_ci',
    'use_unicode': True
}

@app.route('/upload_binary', methods=['POST'])
def upload_binary():
    # リクエストボディの生バイナリを取得
    image_data = request.data
    # HTTPヘッダーからファイル名を取得
    import base64
    filename_raw = request.headers.get('X-Filename', 'unknown.jpg')
    is_encoded = request.headers.get('X-Filename-Encoded', '0') == '1'
    
    # Base64エンコードされている場合はデコード、そうでない場合はそのまま使用
    if is_encoded:
        try:
            filename = base64.b64decode(filename_raw).decode('utf-8')
        except Exception:
            # デコードに失敗した場合はそのまま使用
            filename = filename_raw
    else:
        # エンコードされていない場合は、URLデコードを試みる
        from urllib.parse import unquote
        if isinstance(filename_raw, bytes):
            filename = unquote(filename_raw.decode('utf-8'))
        else:
            filename = unquote(filename_raw)

    # MySQLにバイナリを保存
    conn = mysql.connector.connect(**db_config)
    cur = conn.cursor()
    sql = "INSERT INTO images (filename, data) VALUES (%s, %s)"
    cur.execute(sql, (filename, image_data))
    image_id = cur.lastrowid
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({'message': 'Binary upload success', 'filename': filename, 'id': image_id})

@app.route('/image/<int:id>', methods=['GET'])
def get_image(id):
    conn = mysql.connector.connect(**db_config)
    cur = conn.cursor()
    cur.execute("SELECT filename, data FROM images WHERE id=%s", (id,))
    row = cur.fetchone()
    cur.close()
    conn.close()

    if row:
        filename, image_data = row
        print(f'filename: {filename}')
        content_type = get_content_type(filename)
        # RFC 5987に従って、UTF-8でエンコードされたファイル名を設定
        # 非ASCII文字が含まれる場合はfilename*パラメータを使用
        if any(ord(c) > 127 for c in filename):
            # 非ASCII文字が含まれる場合はRFC 5987形式を使用
            # filenameパラメータにはASCII互換の代替名を設定（拡張子は保持）
            _, ext = os.path.splitext(filename)
            safe_filename = f"image{ext}" if ext else "image"
            encoded_filename = quote(filename.encode('utf-8'), safe='')
            content_disposition = f'inline; filename="{safe_filename}"; filename*=UTF-8\'\'{encoded_filename}'
        else:
            # ASCII文字のみの場合は通常形式
            content_disposition = f'inline; filename="{filename}"'
        headers = {
            'Content-Type': content_type,
            'Content-Disposition': content_disposition
        }
        return image_data, 200, headers
    else:
        return jsonify({'error': 'Image not found'}), 404

if __name__ == '__main__':
    app.run(debug=True)
