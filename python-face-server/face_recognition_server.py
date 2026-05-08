from flask import Flask, request, jsonify
import numpy as np
import base64
import cv2
from deepface import DeepFace

app = Flask(__name__)

# Load model sekali saat server start (bukan tiap request)
print("Loading model, harap tunggu...")
DeepFace.build_model("Facenet512")
print("Model siap!")

def decode_image(base64_str):
    if ',' in base64_str:
        base64_str = base64_str.split(',')[1]
    img_data = base64.b64decode(base64_str)
    nparr = np.frombuffer(img_data, np.uint8)
    img_bgr = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    # Auto enhance brightness & contrast
    lab = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    l = clahe.apply(l)
    enhanced = cv2.merge([l, a, b])
    img_bgr = cv2.cvtColor(enhanced, cv2.COLOR_LAB2BGR)
    
    return img_bgr

def get_embedding(img):
    result = DeepFace.represent(
        img_path=img,
        model_name="Facenet512",
        enforce_detection=False,
        detector_backend="opencv"
    )
    return np.array(result[0]['embedding'])

def cosine_similarity(a, b):
    dot = np.dot(a, b)
    norm = np.linalg.norm(a) * np.linalg.norm(b)
    return dot / norm if norm != 0 else 0

@app.route('/register-multiple', methods=['POST'])
def register_multiple():
    try:
        data = request.json
        images_base64 = data['images_base64']  # list 3 foto

        embeddings = []
        for b64 in images_base64:
            img = decode_image(b64)

            # Cek kecerahan
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            brightness = gray.mean()
            if brightness < 40:
                return {"success": False, "message": "Salah satu foto terlalu gelap"}, 400

            emb = get_embedding(img)
            embeddings.append(emb)

            # Tambah versi flip untuk variasi
            emb_flip = get_embedding(cv2.flip(img, 1))
            embeddings.append(emb_flip)

        # Rata-rata semua embedding (6 total: 3 foto x 2)
        avg_embedding = np.mean(embeddings, axis=0).tolist()
        print(f"Multi-embedding berhasil dari {len(images_base64)} foto")

        return {"success": True, "embedding": avg_embedding}

    except Exception as e:
        print(f"ERROR register-multiple: {e}")
        return {"success": False, "message": str(e)}, 400

@app.route('/extract-embedding', methods=['POST'])
def extract_embedding():
    try:
        data = request.json
        img = decode_image(data['image_base64'])

        # Ambil 3 embedding dengan flip horizontal untuk variasi
        emb1 = get_embedding(img)
        emb2 = get_embedding(cv2.flip(img, 1))  # mirror
        
        # Rata-rata embedding
        avg_embedding = ((emb1 + emb2) / 2).tolist()

        print(f"Embedding berhasil, panjang: {len(avg_embedding)}")
        return {"success": True, "embedding": avg_embedding}

    except Exception as e:
        print(f"ERROR extract: {e}")
        return {"success": False, "message": str(e)}, 400

@app.route('/verify-face', methods=['POST'])
def verify_face():
    try:
        data = request.json
        current_img = decode_image(data['current_image_base64'])

        current_embedding = get_embedding(current_img)
        stored_embedding = np.array(data['stored_embedding'])

        similarity = cosine_similarity(current_embedding, stored_embedding)
        confidence = round(float(similarity) * 100, 2)

        # Threshold 0.5 lebih longgar
        match = bool(similarity > 0.4)

        print(f"Similarity: {similarity:.4f} ({confidence}%), Match: {match}")

        return {
            "success": True,
            "match": match,
            "confidence": confidence
        }

    except Exception as e:
        print(f"ERROR verify: {e}")
        return {"success": False, "match": False, "message": str(e)}, 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=False)