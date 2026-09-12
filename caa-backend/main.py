from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import models
from database import engine, get_db

models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="CAA App API",
    description="Backend MVP para Sistema de Comunicación Aumentativa",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

@app.get("/")
def read_root():
    return {"message": "¡API de CAA en línea y funcionando!"}

@app.get("/users/{user_id}/board")
def get_user_board(user_id: int, db: Session = Depends(get_db)):
    # Verificamos si el usuario existe
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    # Consultamos los elementos del tablero haciendo un JOIN con los pictogramas
    board_items = db.query(models.BoardItem).filter(models.BoardItem.user_id == user_id).all()
    
    if not board_items:
        return {"message": "No se encontraron elementos del tablero para el usuario especificado."}

    # Armamos una respuesta limpia y directa para Flutter
    response_data = []
    for item in board_items:
        response_data.append({
            "position_x": item.position_x,
            "position_y": item.position_y,
            "is_hidden": item.is_hidden,
            "palabra": item.pictogram.palabra,
            "parte_de_la_palabra": item.pictogram.parte_de_la_palabra,
            "is_core": item.pictogram.is_core,
            "image_url": item.pictogram.image_url
        })

    return {
        "user_id": user.id,
        "nombre": user.nombre,
        "grid_rows": user.grid_rows,
        "grid_cols": user.grid_cols,
        "board": response_data
    }