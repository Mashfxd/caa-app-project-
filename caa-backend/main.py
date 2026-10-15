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

# Configuración de CORS para permitir conexión con Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "¡API de CAA en línea y funcionando!"}

@app.get("/users/{user_id}/board")
def get_user_board(user_id: int, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    board_items = db.query(models.BoardItem).filter(models.BoardItem.user_id == user_id).all()

    items_list = []
    for item in board_items:
        pic = item.pictogram
        items_list.append({
            "id": pic.id,
            "palabra": pic.palabra,
            "parte_de_la_palabra": pic.parte_de_la_palabra,
            "is_core": pic.is_core,
            "image_url": pic.image_url,
            "category_id": pic.category_id,
            "position_x": item.position_x,
            "position_y": item.position_y,
            "is_hidden": item.is_hidden
        })

    return {
        "user_id": user.id,
        "nombre": user.nombre,
        "grid_rows": user.grid_rows,
        "grid_cols": user.grid_cols,
        "board": items_list
    }

@app.get("/categories/{category_id}/pictograms")
def get_category_pictograms(category_id: int, db: Session = Depends(get_db)):
    category = db.query(models.Category).filter(models.Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")
    
    return {
        "category_id": category.id,
        "nombre": category.nombre,
        "pictograms": [
            {
                "id": p.id,
                "palabra": p.palabra,
                "parte_de_la_palabra": p.parte_de_la_palabra,
                "image_url": p.image_url,
                "category_id": p.category_id
            } for p in category.pictograms
        ]
    }