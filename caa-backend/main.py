from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
import models
import schema
from database import engine, get_db

models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="CAA App API",
    description="Backend MVP para Sistema de Comunicación Aumentativa",
    version="1.0.0"
)

# Configuración de CORS para permitir conexiónes vercel y movil
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {"status": " ok"}

@app.get("/board",response_model=List[schema.BoardItemResponseSchema])
def get_board(db: Session = Depends(get_db)):
    items = db.query(models.BoardItem).filter(models.BoardItem.is_hidden == False).all()
    return items

   
@app.get("/categories/{category_id}/pictograms", response_model=List[schemas.PictogramSchema])
def get_category_pictograms(category_id: int, db: Session = Depends(get_db)):
    pictograms = db.query(models.Pictogram).filter(models.Pictogram.category_id == category_id).all()
    return pictograms

@app.get("/sync")
def sync_catalog(db: Session = Depends(get_db)):
    """Devuelve todo el catálogo para sincronizar la base de datos local SQLite en el dispositivo."""
    categories = db.query(models.Category).all()
    pictograms = db.query(models.Pictogram).all()
    board_items = db.query(models.BoardItem).all()
    return {
        "categories": [schema.CategorySchema.model_validate(c) for c in categories],
        "pictograms": [schema.PictogramSchema.model_validate(p) for p in pictograms],
        "board_items": [
            {
                "id": b.id,
                "pictogram_id": b.pictogram_id,
                "position_x": b.position_x,
                "position_y": b.position_y,
                "is_hidden": b.is_hidden
            }
            for b in board_items
        ]
    }