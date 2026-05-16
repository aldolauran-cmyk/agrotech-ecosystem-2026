from fastapi import FastAPI
from backend.app.core.database import Base, engine
from backend.app.routers import user

app = FastAPI()

Base.metadata.create_all(bind=engine)

app.include_router(user.router)

@app.get("/")
def root():
    return {"message": "API AgroTech funcionando 🚜"}
