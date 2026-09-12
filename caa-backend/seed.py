from database import SessionLocal, engine
import models

def seed_data():
    # Creamos las tablas si no existen
    models.Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()

    try:
        if db.query(models.User).first():
            print("La base de datos ya tiene datos. Abortando seed.")
            return

        print("Iniciando la carga de datos de prueba...")

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

        # 2. Crear Pictogramas (¡Actualizado a tus campos en español!)
        pictograms_data = [
            {"palabra": "Yo", "parte_de_la_palabra": "pronombre", "is_core": True, "image_url": "https://ejemplo.com/yo.png"},
            {"palabra": "Quiero", "parte_de_la_palabra": "verbo", "is_core": True, "image_url": "https://ejemplo.com/quiero.png"},
            {"palabra": "Comer", "parte_de_la_palabra": "verbo", "is_core": True, "image_url": "https://ejemplo.com/comer.png"},
            {"palabra": "Manzana", "parte_de_la_palabra": "sustantivo", "is_core": False, "image_url": "https://ejemplo.com/manzana.png"},
            {"palabra": "Jugar", "parte_de_la_palabra": "verbo", "is_core": True, "image_url": "https://ejemplo.com/jugar.png"},
        ]

        db_pictograms = []
        for pic_data in pictograms_data:
            pic = models.Pictogram(**pic_data)
            db.add(pic)
            db.commit() # Hacemos commit individual para asegurar que se genere el ID
            db.refresh(pic)
            db_pictograms.append(pic)

        # 3. Asignar posiciones
        board_items_data = [
            models.BoardItem(user_id=test_user.id, pictogram_id=db_pictograms[0].id, position_x=0, position_y=0, is_hidden=False),
            models.BoardItem(user_id=test_user.id, pictogram_id=db_pictograms[1].id, position_x=0, position_y=1, is_hidden=False),
            models.BoardItem(user_id=test_user.id, pictogram_id=db_pictograms[2].id, position_x=0, position_y=2, is_hidden=False),
            models.BoardItem(user_id=test_user.id, pictogram_id=db_pictograms[3].id, position_x=1, position_y=2, is_hidden=False),
            models.BoardItem(user_id=test_user.id, pictogram_id=db_pictograms[4].id, position_x=0, position_y=3, is_hidden=True),
        ]

        db.add_all(board_items_data)
        db.commit()

        print("¡Datos de prueba insertados con éxito!")

    except Exception as e:
        print(f"Ocurrió un error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_data()