from database import SessionLocal, engine
import models

def seed_data():
    models.Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # Limpiamos datos anteriores para asegurar una carga limpia
        db.query(models.BoardItem).delete()
        db.query(models.Pictogram).delete()
        db.query(models.Category).delete()
        db.query(models.User).delete()
        db.commit()

        print("Insertando datos actualizados (Mamá y Agua)...")

        # 1. Crear Usuario
        test_user = models.User(
            nombre="Usuario de Prueba", 
            grid_rows=4, 
            grid_cols=5, 
            high_contrast=False
        )
        db.add(test_user)
        db.commit()
        db.refresh(test_user)

        # 2. Crear Categorías (Carpeta)
        cat_comida = models.Category(nombre="Comida y Bebida", icon_url="https://cdn-icons-png.flaticon.com/512/1046/1046784.png")
        db.add(cat_comida)
        db.commit()
        db.refresh(cat_comida)

        # 3. Crear Pictogramas (Núcleo y Específicos)
        pictograms_data = [
            {"palabra": "Yo", "parte_de_la_palabra": "pronombre", "is_core": True, "image_url": "https://cdn-icons-png.flaticon.com/512/1077/1077114.png", "category_id": None},
            {"palabra": "Quiero", "parte_de_la_palabra": "verbo", "is_core": True, "image_url": "https://cdn-icons-png.flaticon.com/512/3289/3289395.png", "category_id": None},
            {"palabra": "Mamá", "parte_de_la_palabra": "sustantivo", "is_core": True, "image_url": "https://cdn-icons-png.flaticon.com/512/4140/4140047.png", "category_id": None},
            {"palabra": "Comida", "parte_de_la_palabra": "sustantivo", "is_core": False, "image_url": "https://cdn-icons-png.flaticon.com/512/1046/1046784.png", "category_id": cat_comida.id}, # Acceso a carpeta
            {"palabra": "Agua", "parte_de_la_palabra": "sustantivo", "is_core": False, "image_url": "https://cdn-icons-png.flaticon.com/512/3105/3105807.png", "category_id": cat_comida.id}, # Dentro de carpeta
            {"palabra": "Manzana", "parte_de_la_palabra": "sustantivo", "is_core": False, "image_url": "https://cdn-icons-png.flaticon.com/512/415/415733.png", "category_id": cat_comida.id}, # Dentro de carpeta
        ]

        db_pictograms = []
        for pic_data in pictograms_data:
            pic = models.Pictogram(**pic_data)
            db.add(pic)
            db.commit()
            db.refresh(pic)
            db_pictograms.append(pic)

        # 4. Asignar posiciones al Tablero Principal (Coordenadas X, Y)
        board_items_data = [
            models.BoardItem(user_id=test_user.id, pictogram_id=db_pictograms[0].id, position_x=0, position_y=0, is_hidden=False), # Yo
            models.BoardItem(user_id=test_user.id, pictogram_id=db_pictograms[1].id, position_x=0, position_y=1, is_hidden=False), # Quiero
            models.BoardItem(user_id=test_user.id, pictogram_id=db_pictograms[2].id, position_x=0, position_y=2, is_hidden=False), # Mamá
            models.BoardItem(user_id=test_user.id, pictogram_id=db_pictograms[3].id, position_x=1, position_y=0, is_hidden=False), # Carpeta Comida
        ]

        db.add_all(board_items_data)
        db.commit()

        print("¡Base de datos poblada con éxito!")

    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_data()