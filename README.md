# Portal documental con QR — GitHub Pages + Supabase

## Qué hace
- Panel privado `admin.html`: usuario autorizado sube un PDF (hasta 20 MB), completa número, identificación, fecha y emisor; obtiene enlace y código QR PNG.
- Consulta pública `index.html`: al escanear el QR, muestra número, identificación y fecha y permite descargar una copia del PDF mediante URL temporal (60 s).
- Lista administrativa de hasta 100 informes, con opción de activar/desactivar.
- Consulta pública también por número de informe, si este se conoce.
- Diseño inspirado en distribución de la referencia compartida, **con marca independiente**. No emite certificaciones ni sustituye verificación del laboratorio emisor.

## 1. Crear proyecto en Supabase
1. En https://supabase.com crea un proyecto.
2. Abre **SQL Editor** y ejecuta todo `supabase/schema.sql`.
3. En **Authentication → Users → Add user** crea tu cuenta con email y contraseña segura. Copia su **User UID**.
4. En **SQL Editor** ejecuta, reemplazando por su UUID real:
   ```sql
   insert into public.portal_admins(user_id) values ('UUID-DEL-USUARIO');
   ```
5. En **Project Settings → API Keys** obtiene la URL del proyecto y la clave **publishable** o **anon** (NUNCA uses `service_role` en archivos de la página).
6. Edita `assets/config.js` y pega los dos valores.

## 2. Publicar función segura
Instala Supabase CLI (consulta https://supabase.com/docs/guides/local-development/cli/getting-started) y ejecuta desde la carpeta raíz:
```bash
supabase login
supabase link --project-ref TU_PROJECT_REF
supabase functions deploy consulta-informe --no-verify-jwt
```
La función usa automáticamente las variables reservadas `SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` del proyecto de Supabase; jamás deben publicarse en GitHub ni en el HTML.

## 3. Publicar en GitHub
1. Crea un repositorio y sube `index.html`, `admin.html` y `assets/` (la carpeta `supabase/` puede estar en el repositorio, **no contiene secretos**).
2. En GitHub **Settings → Pages → Deploy from a branch → main → /(root)**.
3. Abre `https://TUUSUARIO.github.io/TUREPOSITORIO/admin.html`, inicia sesión y sube tu primer PDF.
4. El sistema genera un enlace usando la ruta donde está publicado el sitio: un QR por informe. Guarda el QR como PNG.
5. Para usar un subdominio, en GitHub Pages configura **Custom domain** (p. ej. `informes.tudominio.cloud`). En Namecheap añade `CNAME` host `informes` hacia `TUUSUARIO.github.io`. Activa HTTPS. **Configura el dominio antes de generar QR definitivos**, porque los ya generados apuntarán a la URL anterior.

## Importante: privacidad y autenticidad
- El documento se guarda en Storage **privado**; solo se descarga mediante enlace firmado temporal. **Sin embargo, cualquiera que tenga el QR o enlace puede consultarlo y descargarlo**. Por tanto, no lo uses con documentos confidenciales sin añadir autenticación del destinatario.
- La consulta por número permite descubrir informes activos si se conocen sus números. Deshabilita la RPC `find_public_report` y su formulario público si necesitas privacidad.
- Es un **portal independiente de copias**. No use marcas de Confience/Hidrolab, no se presente como validador oficial y no altere firmas, códigos de validación ni QR originales. Para documentos de terceros, obtenga autorización para publicarlos. Para emitir informes nuevos, use la identidad del emisor autorizado.
- Las cuentas administradoras se crean manualmente; el portal no ofrece alta pública.
- No publiques claves secretas en GitHub. El backend sí requiere la función Edge desplegada.
- Las extracciones automáticas de campos PDF **no están implementadas**: se introducen manualmente para garantizar exactitud.
- Se requiere conexión a internet para las bibliotecas JS (QR y Supabase) de CDN y para Supabase.
- En caso de incidencia con registros fallidos, revisa Storage para posibles PDF huérfanos.

## Archivos
- `index.html`: consulta.
- `admin.html`: administración.
- `assets/config.js`: configuración pública.
- `assets/*.js`: funcionalidad cliente.
- `supabase/schema.sql`: tablas, políticas y consulta por número.
- `supabase/functions/consulta-informe/index.ts`: consulta y descarga firmada.

## Prueba
1. Publica primero GitHub Pages + Supabase.
2. Sube un informe propio o autorizado, con datos de prueba. Accede al enlace y prueba QR con un móvil.
3. Desactiva el informe desde el administrador; el enlace deberá dejar de abrir la ficha/descarga cuando expire la URL firmada previa.

Este paquete no contiene resultados de laboratorio ni el PDF original de Hidrolab.
