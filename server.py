from flask import Flask, request, jsonify
from dotenv import load_dotenv
import mysql.connector
import os

load_dotenv()
MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD')
MYSQL_DATABASE = os.getenv('MYSQL_DATABASE')

app = Flask(__name__)

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
    'database': MYSQL_DATABASE
}

@app.route('/upload_binary', methods=['POST'])
def upload_binary():
    # リクエストボディの生バイナリを取得
    image_data = request.data
    filename = request.headers.get('X-Filename', 'unknown.jpg')  # ヘッダで渡す例

    # MySQLにバイナリを保存
    conn = mysql.connector.connect(**db_config)
    cur = conn.cursor()
    sql = "INSERT INTO images (filename, data) VALUES (%s, %s)"
    cur.execute(sql, (filename, image_data))
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({'message': 'Binary upload success', 'filename': filename})

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
        content_type = get_content_type(filename)
        headers = {
            'Content-Type': content_type,
            'Content-Disposition': f'inline; filename="{filename}"'
        }
        return image_data, 200, headers
    else:
        return jsonify({'error': 'Image not found'}), 404

if __name__ == '__main__':
    app.run(debug=True)
