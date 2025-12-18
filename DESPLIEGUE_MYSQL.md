# 🐬 Despliegue con MySQL y phpMyAdmin

Esta actualización migra el backend de SQLite a MySQL 8.0 e integra phpMyAdmin para la gestión visual.

## 🚀 Instrucciones de Despliegue

### 1. Actualizar Código
```powershell
git add .
git commit -m "feat: migrar a mysql y organizar archivos"
git push origin main
```

### 2. Desplegar en Histinger
Al hacer push, Hostinger debería reconstruir los contenedores. Si no, fuerza el re-deploy.

### 3. Crear Base de Datos
Al iniciar MySQL por primera vez, estará vacía. Debemos ejecutar el script de inicialización SQL.

#### Opción A: Vía phpMyAdmin (Recomendado)
1. Accede a: `http://72.61.77.167:8081`
   - **Servidor:** `db`
   - **Usuario:** `mercantil_user`
   - **Clave:** `secure_password_2025`
2. Selecciona la base de datos `diario_mercantil` a la izquierda.
3. Clic en pestaña **"Importar"**.
4. Sube el archivo `backend/migrations/init.sql` (tienes que tenerlo en tu PC, o copiar su contenido).
   - *Alternativa:* Ve a la pestaña **SQL** y pega el contenido de `backend/migrations/init.sql`.

#### Opción B: Vía Consola (SSH)
```bash
# Copiar el script al contenedor db (si el volumen no lo mapea directo, usamos cat)
# Lo más fácil es ejecutarlo desde el backend que tiene acceso al código
docker exec dashboard-backend php scripts/seed_users.php
# Nota: Los seeders actuales están diseñados para insertar usuarios, pero NO crean las tablas.
# Primero debemos crear las tablas.
```

**Comando para crear tablas desde el backend:**
He preparado un script rápido que puedes pegar en la terminal SSH para inicializar la DB si phpMyAdmin falla:

```bash
docker exec -i dashboard-db mysql -u mercantil_user -psecure_password_2025 diario_mercantil < backend/migrations/init.sql
```
*(Nota: Esto requiere que backend/migrations/init.sql esté accesible en el host o contenedor. Si no, usa phpMyAdmin).*

### 4. Crear Usuarios (Seed)
Una vez creadas las tablas (paso 3), crea el admin:

```bash
docker exec dashboard-backend php scripts/add_merchandev_user.php
```

---

## 📁 Nueva Organización de Archivos

Los archivos subidos ahora se guardarán automáticamente en carpetas por fecha:
`storage/uploads/2025/12/17/archivo.pdf`

## 🛠 Credenciales Nuevas

### MySQL
- **User:** `mercantil_user`
- **Pass:** `secure_password_2025`
- **Root Pass:** `root_secure_password_2025`

### phpMyAdmin
- **URL:** `http://72.61.77.167:8081`
- **Server:** `db`

---

## ✅ Verificación

1. Entra a phpMyAdmin.
2. Verifica que las tablas `users`, `files`, etc. existen.
3. Sube un archivo en el dashboard.
4. Verifica en phpMyAdmin tabla `files` que la columna `path` tenga un valor como `2025/12/17/...`.
