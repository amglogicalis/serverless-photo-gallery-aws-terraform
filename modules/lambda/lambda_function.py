import json
import os
import boto3
import uuid
import base64
import time

dynamodb = boto3.resource("dynamodb")
s3 = boto3.client("s3")

TABLE_NAME = os.environ["TABLE_NAME"]
BUCKET_NAME = os.environ["BUCKET_NAME"]

table = dynamodb.Table(TABLE_NAME)

ALLOWED_EXT = {"png", "jpg", "jpeg"}

CONTENT_TYPES = {
    "png": "image/png",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg"
}


# ---------------- ENTRYPOINT ----------------

def lambda_handler(event, context):
    print("EVENT:", event)

    path = event.get("path", "/")
    method = event.get("httpMethod", "GET")

    if path == "/" and method == "GET":
        return login_page()

    if path == "/register" and method == "POST":
        return register(event)

    if path == "/login" and method == "POST":
        return login(event)

    if path == "/home" and method == "GET":
        return home_page()

    if path == "/upload" and method == "POST":
        return upload_photo(event)

    if path == "/photos" and method == "GET":
        return get_photos()

    if path == "/delete-photo" and method == "POST":
        return delete_photo(event)

    return response(404, {"error": "not found"})


# ---------------- LOGIN PAGE (SIN CAMBIOS) ----------------

def login_page():
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "text/html"},
        "body": """
<!DOCTYPE html>
<html>
<head>
<title>Login</title>
<style>
body {
    margin: 0;
    font-family: Arial;
    background: linear-gradient(135deg, #74ebd5, #9face6);
    height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
}

.card {
    background: white;
    padding: 30px;
    border-radius: 15px;
    width: 320px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.2);
    text-align: center;
}

h1 {
    margin-bottom: 20px;
    color: #333;
}

input {
    width: 90%;
    padding: 12px;
    margin: 8px 0;
    border: 1px solid #ddd;
    border-radius: 8px;
}

button {
    width: 95%;
    padding: 12px;
    margin-top: 10px;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    font-weight: bold;
}

.login-btn {
    background: #4a90e2;
    color: white;
}

.register-btn {
    background: #50c878;
    color: white;
}

button:hover {
    opacity: 0.9;
}

#msg {
    margin-top: 10px;
    color: #333;
}
</style>
</head>
<body>

<div class="card">
    <h1>Welcome</h1>

    <input id="user" placeholder="username">
    <input id="pass" type="password" placeholder="password">

    <label style="font-size: 12px;">
        <input type="checkbox" onclick="togglePassword()">
        Show password
</label>

    <button class="login-btn" onclick="login()">Login</button>
    <button class="register-btn" onclick="register()">Register</button>

    <p id="msg"></p>
</div>

<script>
async function login(){
    const r = await fetch("/login", {
        method:"POST",
        headers: {"Content-Type":"application/json"},
        body: JSON.stringify({
            username: user.value,
            password: pass.value
        })
    });

    const d = await r.json();

    if(d.ok){
        localStorage.setItem("user", user.value);
        window.location.href = "/home";
    } else {
        msg.innerText = "Login failed";
    }
}

async function register(){
    const r = await fetch("/register", {
        method:"POST",
        headers: {"Content-Type":"application/json"},
        body: JSON.stringify({
            username: user.value,
            password: pass.value
        })
    });

    const d = await r.json();
    msg.innerText = d.message;
}

function togglePassword() {
    const pass = document.getElementById("pass");

    if (pass.type === "password") {
        pass.type = "text";
    } else {
        pass.type = "password";
    }
}

</script>

</body>
</html>
"""
    }


# ---------------- REGISTER ----------------

def register(event):
    body = json.loads(event.get("body") or "{}")

    username = body.get("username")
    password = body.get("password")

    if not username or not password:
        return response(400, {"message": "empty fields"})

    table.put_item(
        Item={
            "id": str(uuid.uuid4()),
            "type": "user",
            "username": username,
            "password": password
        }
    )

    return response(200, {"message": "registered ok"})


# ---------------- LOGIN ----------------

def login(event):
    body = json.loads(event.get("body") or "{}")

    username = body.get("username")
    password = body.get("password")

    items = table.scan().get("Items", [])

    for u in items:
        if u.get("type") == "user" and u["username"] == username and u["password"] == password:
            return response(200, {"ok": True})

    return response(401, {"ok": False})


# ---------------- HOME PAGE (SIN CAMBIOS) ----------------

def home_page():
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "text/html"},
        "body": """
<!DOCTYPE html>
<html>
<head>
<title>Home</title>
<style>
body {
    margin: 0;
    font-family: Arial;
    background: #f5f7fb;
    color: #333;
}

.header {
    background: white;
    padding: 15px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.container {
    max-width: 900px;
    margin: auto;
    padding: 20px;
}

.upload-box {
    background: white;
    padding: 20px;
    border-radius: 12px;
    box-shadow: 0 5px 15px rgba(0,0,0,0.1);
    margin-bottom: 20px;
}

button {
    background: #4a90e2;
    color: white;
    padding: 10px 15px;
    border: none;
    border-radius: 8px;
    cursor: pointer;
}

button:hover {
    opacity: 0.9;
}

.gallery {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
    gap: 15px;
}

.card {
    background: white;
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 5px 12px rgba(0,0,0,0.1);
}

.card img {
    width: 100%;
    height: 180px;
    object-fit: cover;
}

.card p {
    margin: 10px;
    font-size: 14px;
}
</style>
</head>
<body>

<div class="header">
    <h3>Photo App</h3>
    <div id="user"></div>
</div>

<div class="container">

    <div class="upload-box">
        <input type="file" id="file">
        <button onclick="upload()">Upload image</button>
    </div>

    <div class="gallery" id="gallery"></div>

</div>

<script>

document.getElementById("user").innerText =
"User: " + localStorage.getItem("user");

async function upload(){
    const f = document.getElementById("file").files[0];

    const base64 = await toBase64(f);

    await fetch("/upload", {
        method:"POST",
        headers: {"Content-Type":"application/json"},
        body: JSON.stringify({
            filename: f.name,
            file: base64,
            user: localStorage.getItem("user")
        })
    });

    loadPhotos();
}

function toBase64(file){
    return new Promise((resolve,reject)=>{
        const r = new FileReader();
        r.readAsDataURL(file);
        r.onload = () => resolve(r.result);
        r.onerror = err => reject(err);
    });
}

async function loadPhotos(){
    const r = await fetch("/photos");
    const data = await r.json();

    const g = document.getElementById("gallery");
    g.innerHTML = "";

    data.forEach(p => {
        g.innerHTML += `
        <div class="card">
            <img src="${p.url}">
            <p>${p.user}</p>

            ${p.user === localStorage.getItem("user") ? `
                <button onclick="deletePhoto('${p.id}', '${p.key}')">Delete</button>
            ` : ""}
        </div>
        `;
    });
}

    loadPhotos();

    async function deletePhoto(id, key){
        await fetch("/delete-photo", {
            method: "POST",
            headers: {"Content-Type":"application/json"},
            body: JSON.stringify({
                id: id,
                key: key,
                user: localStorage.getItem("user")
        })
    });

    loadPhotos();
}
</script>

</body>
</html>
"""
    }


# ---------------- UPLOAD (FIXADO) ----------------

def upload_photo(event):
    try:
        body = json.loads(event.get("body") or "{}")

        file_data = body.get("file")
        filename = body.get("filename")
        user = body.get("user")

        if not file_data or not filename:
            return response(400, {"error": "missing file"})

        if "." not in filename:
            return response(400, {"error": "invalid filename"})

        if not file_data.startswith("data:image/"):
            return response(400, {"error": "only images allowed"})

        ext = filename.rsplit(".", 1)[1].lower()

        if ext not in ALLOWED_EXT:
            return response(400, {"error": "only png/jpg/jpeg allowed"})

        if "," in file_data:
            file_data = file_data.split(",")[1]

        image_bytes = base64.b64decode(file_data)

# ---------------- VALIDACIÓN REAL ----------------

        def is_jpeg(data):
            return data.startswith(b"\xff\xd8\xff")

        def is_png(data):
            return data.startswith(b"\x89PNG\r\n\x1a\n")

        # SOLO JPG / JPEG / PNG
        if not (is_jpeg(image_bytes) or is_png(image_bytes)):
            return response(400, {"error": "only jpg, jpeg, png allowed"})

        key = f"{uuid.uuid4()}.{ext}"

        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=key,
            Body=image_bytes,
            ContentType=CONTENT_TYPES[ext]
        )

        url = s3.generate_presigned_url(
            ClientMethod="get_object",
            Params={"Bucket": BUCKET_NAME, "Key": key},
            ExpiresIn=604800
        )

        now = int(time.time())
        ttl = now + 604800
        table.put_item(
            Item={
                "id": str(uuid.uuid4()),
                "type": "photo",
                "user": user,
                "key": key,
                "url": url,
                "ttl": ttl
            }
        )

        return response(200, {"ok": True})

    except Exception as e:
        print("UPLOAD ERROR:", str(e))
        return response(500, {"error": "upload failed"})


# ---------------- GET PHOTOS (FIX RESIDUOS) ----------------

def get_photos():
    try:
        items = table.scan().get("Items", [])

        photos = [x for x in items if x.get("type") == "photo"]

        result = []

        for p in photos:
            print("DEBUG PHOTO:", p)  # <-- importante para ver qué hay en Dynamo

            result.append({
                "id": p.get("id", ""),   # fallback seguro
                "url": p.get("url", ""),
                "key": p.get("key", ""),
                "user": p.get("user", "")
            })

        return response(200, result)

    except Exception as e:
        print("GET PHOTOS ERROR:", str(e))
        return response(500, {"error": "failed"})


# ---------------- RESPONSE ----------------

def response(status, body):
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps(body)
    }

def delete_photo(event):
    body = json.loads(event.get("body") or "{}")

    photo_id = body.get("id")
    key = body.get("key")
    user = body.get("user")

    print("DELETE REQUEST:", photo_id, user)

    items = table.scan().get("Items", [])

    for item in items:
        if str(item.get("id")) == str(photo_id) and item.get("type") == "photo":

            print("FOUND ITEM:", item)

            # 🔐 seguridad
            if item.get("user") != user:
                return response(403, {"error": "not allowed"})

            # 🧹 borrar S3
            print("DELETING S3:", item["key"])
            s3.delete_object(
                Bucket=BUCKET_NAME,
                Key=item["key"]
            )

            # 🧹 borrar DynamoDB
            print("DELETING DDB:", photo_id)
            table.delete_item(
                Key={"id": photo_id}
            )

            return response(200, {"ok": True})

    return response(404, {"error": "not found"})