# 🗣️ Comunicador CAA (Comunicación Aumentativa y Alternativa)

Aplicación híbrida y de alto rendimiento diseñada bajo estándares clínicos (Vocabulario Núcleo / Fitzgerald Key) para asistir a personas con necesidades complejas de comunicación. El sistema implementa una arquitectura **Offline-First** optimizada para dispositivos móviles Android y accesibilidad web.

---

## 🏗️ Arquitectura del Repositorio

El proyecto está estructurado como un *monorepo* limpio:

* **`caa-backend/`**: API REST desarrollada en **FastAPI** con **SQLAlchemy** y SQLite/PostgreSQL. Gestiona el catálogo de pictogramas, categorías y la estructura del tablero.
* **`caa_frontend/`**: Aplicación multiplataforma desarrollada en **Flutter**. Utiliza almacenamiento local persistente (`sqflite`) para funcionamiento completamente offline y llamadas HTTP con respaldo en memoria para despliegue web.
* **`.github/workflows/`**: Automatización con **GitHub Actions** para compilar el APK de Android de manera nativa en la nube sin requerir SDKs locales pesados.

---

## 🚀 Características Principales

* **Offline-First:** Funciona sin conexión a internet en dispositivos Android gracias a su base de datos local SQLite.
* **Síncrono y Híbrido:** Capacidad de sincronizar el vocabulario local con el servidor mediante el endpoint `/sync`.
* **Motor de Voz Adaptativo:** Integración con `flutter_tts` con manejo de colisiones de audio para una reproducción fluida en navegadores y móviles.
* **Diseño Motor / Cuadrícula Estricta:** Respeta la planificación motora para usuarios con dificultades motoras o cognitivas.

---

## 🛠️ Requisitos e Instalación Local

### 1. Backend (FastAPI)
```bash
cd caa-backend
pip install -r requirements.txt
uvicorn main:app --reload
