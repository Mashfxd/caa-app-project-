from fastapi import FastAPI,Depends
from sqlalchemy.orm import Session
import models
from database import engine, get_db

app = FastAPI(
    tittle="CAA Backend API",
    description="API para la aplicación de Comunicación Aumentativa y Alternativa (CAA)",
    version="1.0.0",
)
@app.get("/")
def read_root():
    return {"message": "Bienvenido a la API de CAA funcionando y en linea!"}
@app.get("/user/{user_id}/board")
def get_user_board(user_id: int, db: Session = Depends(get_db)):
    board = db.query(models.BoardItem).filter(models.BoardItem.user_id == user_id).all()

    if not board:
        return {"message": "No se encontraron elementos del tablero para el usuario especificado."}
    return board