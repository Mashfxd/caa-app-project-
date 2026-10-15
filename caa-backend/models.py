from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    grid_rows = Column(Integer, default=4)
    grid_cols = Column(Integer, default=5)
    high_contrast = Column(Boolean, default=False)

    boards = relationship("BoardItem", back_populates="user")

class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    icon_url = Column(String, nullable=True)

    pictograms = relationship("Pictogram", back_populates="category")

class Pictogram(Base):
    __tablename__ = "pictograms"

    id = Column(Integer, primary_key=True, index=True)
    palabra = Column(String, index=True)
    parte_de_la_palabra = Column(String)
    is_core = Column(Boolean, default=False)
    image_url = Column(String)
    
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    category = relationship("Category", back_populates="pictograms")

    board_items = relationship("BoardItem", back_populates="pictogram")

class BoardItem(Base):
    __tablename__ = "board_items"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    pictogram_id = Column(Integer, ForeignKey("pictograms.id"))
    position_x = Column(Integer, nullable=False)
    position_y = Column(Integer, nullable=False)
    is_hidden = Column(Boolean, default=False)

    user = relationship("User", back_populates="boards")
    pictogram = relationship("Pictogram", back_populates="board_items")