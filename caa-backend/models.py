from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, index=True)
    grid_rows = Column(String, default= 4)
    grid_cols = Column(Integer, default= 5)
    high_contrast = Column(Boolean, default=True)

    board_items = relationship("BoardItem", back_populates="user")

class Pictogram(Base):
    __tablename__ = "pictograms"

    id = Column(Integer, primary_key=True, index=True)
    palabra = Column(String,index=True)
    parte_de_la_palabra = Column(String)
    is_core = Column(Boolean, default=False)
    image_url = Column(String)

class BoardItem(Base):
    __tablename__ = "user_boards"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    pictogram_id = Column(Integer, ForeignKey("pictograms.id"))

    position_x = Column(Integer, default=0)
    position_y = Column(Integer, default=0)

    is_hidden = Column(Boolean, default=False)

    user = relationship("User", back_populates="board_items")
    pictogram = relationship("Pictogram")