from fastapi import FastAPI

app = FastAPI()

latest_data = {
    "r": 0,
    "g": 0,
    "b": 0,
    "hex": "#000000"
}

@app.post("/color")
def receive_color(data: dict):
    global latest_data
    latest_data = data
    return {"status": "ok"}

@app.get("/color")
def get_color():
    return latest_data
