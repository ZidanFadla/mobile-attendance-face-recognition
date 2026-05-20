# 🎯 Face Recognition Server v2.0

Clean, secure, and production-ready face recognition server with liveness detection.

## ✨ Features

- ✅ **High Accuracy:** ArcFace model (99.86% accuracy)
- ✅ **Liveness Detection:** Anti-spoofing untuk mencegah fraud
- ✅ **Quality Validation:** Brightness, blur, face size checks
- ✅ **Clean Code:** Simple, maintainable, well-documented
- ✅ **API Compatible:** Match dengan Flutter app

---

## 🚀 Quick Start

### **1. Install Dependencies**

```bash
# Create virtual environment (recommended)
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### **2. Configure (Optional)**

```bash
# Copy .env.example to .env
copy .env.example .env  # Windows
cp .env.example .env    # Linux/Mac

# Edit .env if needed (default values are good)
```

### **3. Run Server**

```bash
python face_recognition_server.py
```

Server akan berjalan di `http://localhost:5000`

---

## 📡 API Endpoints

### **1. Register Face**

```http
POST /face/register
Content-Type: application/json

{
  "images": [
    "base64_image_1",
    "base64_image_2",
    "base64_image_3"
  ]
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Registrasi wajah berhasil",
  "data": {
    "embeddings": [[...], [...], ...],
    "embeddings_count": 6
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "Foto 1: Kualitas kurang baik - too_dark"
}
```

---

### **2. Verify Face**

```http
POST /face/verify
Content-Type: application/json

{
  "image": "base64_image",
  "type": "image",
  "stored_embeddings": [[...], [...], ...]
}
```

**Response (Match):**
```json
{
  "success": true,
  "match": true,
  "confidence": 95.5,
  "message": "Wajah terverifikasi",
  "data": {
    "liveness_passed": true,
    "liveness_confidence": 87.3,
    "quality_metrics": {
      "brightness": 128.5,
      "blur_score": 450.2
    },
    "similarity": 0.955
  }
}
```

**Response (No Match):**
```json
{
  "success": true,
  "match": false,
  "confidence": 45.2,
  "message": "Wajah tidak cocok",
  "data": {
    "liveness_passed": true,
    "similarity": 0.452
  }
}
```

**Response (Liveness Failed):**
```json
{
  "success": false,
  "match": false,
  "confidence": 0.0,
  "message": "Liveness check gagal - terdeteksi foto/video palsu"
}
```

---

### **3. Check Registration**

```http
GET /face/check
```

**Response:**
```json
{
  "registered": true
}
```

---

### **4. Health Check**

```http
GET /health
```

**Response:**
```json
{
  "status": "ok",
  "model": "ArcFace",
  "detector": "retinaface",
  "liveness": true,
  "version": "2.0.0"
}
```

---

## 🔧 Configuration

Edit `.env` file untuk mengubah konfigurasi:

```env
# Model (default: ArcFace - best accuracy)
MODEL_NAME=ArcFace

# Detector (default: retinaface - best accuracy)
DETECTOR_BACKEND=retinaface

# Match threshold (default: 0.68 - recommended for ArcFace)
MATCH_THRESHOLD=0.68

# Liveness threshold (default: 0.7)
LIVENESS_THRESHOLD=0.7

# Minimum face size in pixels (default: 80)
MIN_FACE_SIZE=80

# Server port (default: 5000)
PORT=5000
```

---

## 📊 Model Options

### **Face Recognition Models:**

| Model | Accuracy | Speed | Recommended |
|-------|----------|-------|-------------|
| VGG-Face | 98.95% | Slow | ❌ |
| Facenet | 99.20% | Medium | ⚠️ |
| Facenet512 | 99.63% | Medium | ⚠️ |
| **ArcFace** | **99.86%** | **Fast** | **✅** |
| Dlib | 99.38% | Fast | ⚠️ |

### **Face Detector Backends:**

| Detector | Accuracy | Speed | Recommended |
|----------|----------|-------|-------------|
| opencv | ~85% | Very Fast | ❌ |
| ssd | ~90% | Fast | ⚠️ |
| dlib | ~95% | Medium | ⚠️ |
| mtcnn | ~97% | Slow | ⚠️ |
| **retinaface** | **~99%** | **Medium** | **✅** |

---

## 🔒 Security Features

### **1. Liveness Detection**
- Anti-spoofing model untuk detect foto/video palsu
- Texture analysis untuk additional validation
- Confidence threshold: 0.7 (adjustable)

### **2. Quality Validation**
- **Brightness:** 50-230 (optimal range)
- **Blur:** Laplacian variance > 100
- **Face Size:** Minimal 80x80 pixels
- **Face Count:** Exactly 1 face

### **3. Face Detection**
- `enforce_detection=True` (MUST have face)
- Multiple face detection
- Face alignment

---

## 🧪 Testing

### **Test dengan cURL:**

```bash
# Health check
curl http://localhost:5000/health

# Register face (dummy)
curl -X POST http://localhost:5000/face/register \
  -H "Content-Type: application/json" \
  -d '{"images": ["base64_1", "base64_2", "base64_3"]}'

# Verify face (dummy)
curl -X POST http://localhost:5000/face/verify \
  -H "Content-Type: application/json" \
  -d '{"image": "base64_image", "type": "image"}'
```

### **Test dengan Postman:**

1. Import collection dari `postman_collection.json` (jika ada)
2. Atau buat request manual sesuai dokumentasi di atas

---

## 📈 Performance

### **Expected Performance:**

| Operation | Time | Notes |
|-----------|------|-------|
| Face Detection | ~50-100ms | RetinaFace |
| Embedding Extraction | ~100-200ms | ArcFace |
| Liveness Check | ~50-100ms | Anti-spoofing |
| **Total (Register)** | **~500-900ms** | Per image |
| **Total (Verify)** | **~200-400ms** | Single image |

### **Optimization Tips:**

1. **Use GPU** untuk inference (10x faster)
   ```bash
   # Install tensorflow-gpu instead of tensorflow-cpu
   pip uninstall tensorflow-cpu
   pip install tensorflow-gpu==2.14.0
   ```

2. **Increase workers** untuk production
   ```bash
   gunicorn face_recognition_server:app \
     -w 4 \
     -k sync \
     --bind 0.0.0.0:5000 \
     --timeout 120
   ```

3. **Add caching** untuk embeddings (Redis)

---

## 🐛 Troubleshooting

### **Problem: Models not downloading**

```bash
# Solution: Manual download atau check internet
# DeepFace will auto-download on first use
# Models akan disimpan di ~/.deepface/weights/
```

### **Problem: Slow inference**

```bash
# Solution 1: Use GPU
pip install tensorflow-gpu

# Solution 2: Reduce image size di Flutter
# Compress image ke max 800px width

# Solution 3: Use faster model
# Change MODEL_NAME=Facenet (faster but less accurate)
```

### **Problem: Liveness detection error**

```bash
# Solution: Check if model downloaded
# Model akan auto-download saat pertama kali digunakan
# Jika gagal, server akan fallback (allow all)
```

---

## 📝 Changelog

### **v2.0.0 - Complete Upgrade**
- ✅ Added liveness detection (anti-spoofing)
- ✅ Added quality validation (brightness, blur, face size)
- ✅ Upgraded detector to RetinaFace
- ✅ Upgraded model to ArcFace
- ✅ Updated endpoints untuk match Flutter
- ✅ Better error handling
- ✅ Clean code & documentation

### **v1.0.0 - Initial Release**
- Basic face recognition
- Facenet512 model
- OpenCV detector

---

## 📞 Support

For issues or questions:
1. Check this README
2. Check `UPGRADE_PLAN.md` for migration details
3. Check `COMPARISON.md` for feature comparison
4. Contact development team

---

## 🎉 Credits

- **DeepFace:** Face recognition library
- **Silent Face Anti-Spoofing:** Liveness detection
- **Flask:** Web framework
- **OpenCV:** Image processing

---

**Happy Coding! 🚀**
