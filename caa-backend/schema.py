from pydantic import BaseModel, ConfigDict
from typing import Optional

class CategoryBase(BaseModel):
    id: int
    nombre: str 
    icono_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class PictogramSchema(BaseModel):
    id: int
    palabra: str
    parte_de_la_palabra: Optional[str] = None
    is_core: str
    image_url: str
    categoria_id: Optional[int] = None
   

    model_config = ConfigDict(from_attributes=True)

class BoardItemResponseSchema(BaseModel):
    id: int
    position_x: int
    position_y: int
    is_hidden: bool
    pictogram: PictogramSchema

    model_config = ConfigDict(from_attributes=True)