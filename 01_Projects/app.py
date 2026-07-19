"""
FastAPI — базовый каркас. Версия 1.0.
"""
from fastapi import FastAPI
import uvicorn

app = FastAPI(title="coli-dev API")


@app.get("/")
def root():
    return {"message": "FastAPI работает!", "status": "ok"}


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000, reload=True)
