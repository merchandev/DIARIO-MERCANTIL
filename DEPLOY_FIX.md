# Solución para Despliegue en Vercel

El problema principal es que en local (`localhost`) tu frontend se configura para redirigir las llamadas `/api` al backend mediante un proxy de Vite, pero en **Vercel** esta configuración de proxy no existe en producción. 

Como resultado, cuando tu app en Vercel intenta llamar a `/api/auth/login`, en realidad le está pidiendo a Vercel esa ruta. Vercel, al no tener el backend, devuelve el `index.html` (tu app React), lo que causa errores de "Unexpected token <" (porque esperaba JSON y recibió HTML).

## Pasos para Solucionar

### 1. Despliegue del Backend
Tu backend (PHP + SQLite) **no se está desplegando en Vercel** bajo la configuración actual (Vercel está sirviendo solo el frontend estático).

Tienes dos opciones:
1. **Opción Recomendada (VPS/Hosting PHP)**: Despliega la carpeta `backend` en un hosting PHP tradicional (como Hostinger, DigitalOcean, un VPS, etc.) o un servicio compatible (Railway, Heroku).
2. **Opción Vercel (Solo Frontend)**: Mantén el frontend en Vercel y conecta con tu backend externo.

*(Nota: SQLite no es persistente en Vercel Serverless Functions, por lo que si logras desplegar PHP en Vercel, perderás los datos en cada reinicio. Es mejor usar un hosting externo o cambiar a MySQL/PostgreSQL)*.

### 2. Configurar Variables de Entorno en Vercel
Una vez tengas tu backend online (ej. `https://api.midominio.com`), ve a tu proyecto en **Vercel > Settings > Environment Variables** y agrega:

- **Key**: `VITE_BACKEND_URL`
- **Value**: `https://api.midominio.com` (sin barra al final, ej. `https://mi-api.com` o `http://mi-vps-ip/backend/public`)

### 3. Cambios Realizados en el Código
Ya he aplicado los siguientes parches necesarios:

1. **Frontend (`api.ts`)**: Ahora lee `VITE_BACKEND_URL`. Si existe, todas las llamadas a la API se harán a esa URL completa. Si no existe (local), sigue funcionando como antes.
2. **Backend (`index.php`)**: He corregido los encabezados CORS para permitir credenciales correctamente. Ahora el backend aceptará peticiones desde tu dominio de Vercel.

### 4. Verificar
Después de configurar la variable de entorno en Vercel, **re-despliega** tu proyecto (Redeploy) para que la nueva variable surta efecto en el build.

Tu app debería funcionar correctamente conectándose a tu backend externo.

# Solución para Error en Railway (Script start.sh not found)

El error `Script start.sh not found` y `Railpack could not determine how to build the app` ocurre porque estás desplegando la carpeta raíz (`/`) del repositorio, donde Railway no encuentra archivos que identifiquen el lenguaje (como `package.json` o `composer.json` en la raíz).

Al tener un **monorepo** (carpetas separadas `backend` y `frontend`), debes indicar a Railway qué carpeta desplegar.

## Pasos para Corregir en Railway

1. Ve a tu proyecto en **Railway Dashboard**.
2. Selecciona el servicio que está fallando (probablemente el Backend).
3. Ve a la pestaña **Settings** (Configuración).
4. Busca la sección **Service** > **Root Directory**.
5. Cambia el valor de `/` a `/backend`.
6. Guarda los cambios. Railway debería iniciar un nuevo despliegue automáticamente.

### ¿Por qué funciona esto?
Al cambiar el directorio raíz a `/backend`, Railway encontrará el archivo `Dockerfile` que ya existe allí. Esto le indicará exactamente cómo construir y ejecutar tu backend (usando PHP 8.2 y el servidor interno en el puerto 8000), ignorando el error de "Railpack".

### Nota sobre el Frontend
Si también deseas desplegar el frontend en Railway:
1. Crea un **Nuevo Servicio** dentro del mismo proyecto (conectado al mismo repo).
2. En Settings > Root Directory, pon `/frontend`.
3. Railway detectará el `package.json` del frontend y lo construirá correctamente (normalmente usando `npm run build`).
