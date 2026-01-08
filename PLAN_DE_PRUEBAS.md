# 🧪 Plan de Pruebas - Roomier App

## 📅 Fecha: 8 de Enero de 2026

---

## 📋 Funcionalidades a Probar

1. Filtrado de usuarios por edad
2. Filtrado de usuarios por género
3. Mensaje "escribiendo..." en chat
4. Confirmación de lectura ("Visto")
5. Envío de imágenes por chat
6. Selección de género al crear cuenta
7. Actualización de pantalla de likes recibidos

---

## 1. 🔢 FILTRADO DE USUARIOS POR EDAD

### Objetivo
Verificar que el sistema filtre correctamente los usuarios según las preferencias de edad configuradas.

### Pre-requisitos
- Al menos 3 usuarios registrados con diferentes edades (ej: 20, 25, 30 años)
- Usuario de prueba con preferencias de edad configuradas

### Casos de Prueba

#### Test 1.1: Filtrado básico de edad
**Pasos:**
1. Usuario A configura preferencias de edad: 22-28 años
2. Ir a la página de matches/swipe
3. Observar los perfiles mostrados

**Resultado Esperado:**
- ✅ Solo se muestran usuarios entre 22 y 28 años
- ❌ No aparecen usuarios menores de 22 ni mayores de 28

**Evidencia:**
- Screenshot de preferencias configuradas
- Screenshot de perfiles mostrados

---

#### Test 1.2: Límite inferior de edad
**Pasos:**
1. Usuario A (25 años) configura preferencias: 18-23 años
2. Usuario B (22 años) existe en el sistema
3. Usuario C (17 años) existe en el sistema
4. Verificar perfiles visibles

**Resultado Esperado:**
- ✅ Usuario B aparece (22 años está en rango)
- ❌ Usuario C NO aparece (menor de 18, ilegal)

**Verificación:**
```
Usuario B: edad 22 → DEBE APARECER
Usuario C: edad 17 → NO DEBE APARECER
```

---

#### Test 1.3: Límite superior de edad
**Pasos:**
1. Usuario A configura preferencias: 25-35 años
2. Verificar que usuarios con 35 años aparezcan
3. Verificar que usuarios con 36 años NO aparezcan

**Resultado Esperado:**
- El límite superior es inclusivo (35 años SÍ aparece)
- Usuarios mayores al límite no aparecen

---

#### Test 1.4: Sin preferencias de edad configuradas
**Pasos:**
1. Usuario nuevo que no configuró preferencias
2. Intentar ver matches

**Resultado Esperado:**
- Sistema usa rango por defecto (ej: ±5 años)
- O solicita configurar preferencias antes de mostrar matches

---

## 2. 👥 FILTRADO DE USUARIOS POR GÉNERO

### Objetivo
Verificar que el filtro de género funcione correctamente según las preferencias configuradas.

### Pre-requisitos
- Usuarios registrados de diferentes géneros: Hombre, Mujer, No binario, Prefiero no decir
- Usuario de prueba con preferencias de género configuradas

### Casos de Prueba

#### Test 2.1: Filtrado por género específico
**Pasos:**
1. Usuario A (Hombre) busca roommate: Solo Mujeres
2. Ir a página de matches
3. Observar perfiles

**Resultado Esperado:**
- ✅ Solo aparecen perfiles de mujeres
- ❌ No aparecen hombres ni otros géneros

**Verificación:**
```
Preferencia: "Solo Mujeres"
Perfiles mostrados: [Mujer 1], [Mujer 2], [Mujer 3]
NO mostrados: [Hombre 1], [No binario 1]
```

---

#### Test 2.2: Filtrado "Sin preferencia"
**Pasos:**
1. Usuario A configura: "Sin preferencia de género"
2. Ver matches disponibles

**Resultado Esperado:**
- ✅ Aparecen usuarios de TODOS los géneros
- No hay filtrado por género

---

#### Test 2.3: Múltiples géneros seleccionados
**Pasos:**
1. Usuario A selecciona: "Mujer" y "No binario"
2. Verificar matches

**Resultado Esperado:**
- ✅ Aparecen mujeres
- ✅ Aparecen personas no binarias
- ❌ NO aparecen hombres

---

#### Test 2.4: Verificación bidireccional
**Pasos:**
1. Usuario A (Hombre) busca: Solo Mujeres
2. Usuario B (Mujer) busca: Solo Mujeres
3. Verificar si A puede ver a B

**Resultado Esperado:**
- Usuario A (Hombre) puede ver a Usuario B (Mujer) ✅
- Pero B NO puede ver a A (porque B busca solo mujeres) ❌
- El match solo ocurre si AMBOS cumplen las preferencias del otro

**IMPORTANTE:** Verificar si la lógica es:
- ¿Mostrar solo si ambos cumplen preferencias? ← Más restrictivo
- ¿O mostrar si al menos YO cumplo SUS preferencias? ← Más flexible

---

#### Test 2.5: Usuario sin género especificado
**Pasos:**
1. Usuario C no especificó su género ("Prefiero no decir")
2. Usuario A busca "Solo Hombres"
3. Verificar si C aparece

**Resultado Esperado:**
- Definir comportamiento: ¿Usuario C aparece o no?
- Documentar decisión de negocio

---

## 3. 💬 MENSAJE "ESCRIBIENDO..." EN CHAT

### Objetivo
Verificar que el indicador de escritura funcione en tiempo real en dos lugares:
1. Dentro del chat individual
2. En la lista de chats

### Pre-requisitos
- Dos usuarios con match mutuo
- Chat iniciado entre ambos
- Conexión WebSocket activa

### Casos de Prueba

#### Test 3.1: Indicador en chat individual
**Pasos:**
1. Usuario A abre chat con Usuario B
2. Usuario B empieza a escribir (sin enviar)
3. Observar pantalla de Usuario A

**Resultado Esperado:**
- ✅ Aparece "escribiendo..." debajo del nombre del chat
- Texto en gris/azul italic
- Aparece en máximo 1-2 segundos

**Timing:**
```
T=0s: Usuario B empieza a escribir
T=1s: Usuario A ve "escribiendo..."
T=2s: Usuario B deja de escribir
T=4s: "escribiendo..." desaparece
```

---

#### Test 3.2: Indicador en lista de chats
**Pasos:**
1. Usuario A está en la pantalla de lista de chats (NO dentro del chat)
2. Usuario B abre el chat y empieza a escribir
3. Observar la lista de chats de Usuario A

**Resultado Esperado:**
- ✅ El subtítulo del chat cambia a "escribiendo..."
- Texto en azul italic
- Se actualiza en tiempo real

**Visual:**
```
Antes:  [Avatar] Usuario B
        "Último mensaje..."

Durante: [Avatar] Usuario B
         "escribiendo..." (azul, italic)
```

---

#### Test 3.3: Desaparición del indicador
**Pasos:**
1. Usuario B escribe algo
2. Usuario B envía el mensaje
3. Observar indicador

**Resultado Esperado:**
- ✅ "escribiendo..." desaparece inmediatamente al enviar
- Muestra el nuevo mensaje enviado

---

#### Test 3.4: Timeout del indicador
**Pasos:**
1. Usuario B empieza a escribir
2. Usuario B deja de escribir (sin enviar ni borrar)
3. Esperar 2-3 segundos

**Resultado Esperado:**
- ✅ "escribiendo..." desaparece después de 2-3 segundos
- No se queda pegado

---

#### Test 3.5: Múltiples usuarios escribiendo
**Pasos:**
1. Usuario A tiene chats con B y C
2. Ambos B y C escriben al mismo tiempo
3. Observar lista de chats de A

**Resultado Esperado:**
- ✅ Ambos chats muestran "escribiendo..." independientemente
- No hay interferencia entre chats

---

## 4. ✅ CONFIRMACIÓN DE LECTURA ("VISTO")

### Objetivo
Verificar que las confirmaciones de lectura (doble check) funcionen correctamente.

### Pre-requisitos
- Dos usuarios con match mutuo
- Chat activo
- WebSocket funcionando

### Casos de Prueba

#### Test 4.1: Check gris al enviar
**Pasos:**
1. Usuario A envía mensaje a Usuario B
2. Usuario B NO ha abierto el chat
3. Observar el mensaje en la pantalla de Usuario A

**Resultado Esperado:**
- ✅ Aparece doble check (✓✓) en color GRIS
- Indica: "enviado pero no leído"

---

#### Test 4.2: Check azul al leer
**Pasos:**
1. Usuario A envió mensaje (check gris)
2. Usuario B abre el chat y ve el mensaje
3. Observar pantalla de Usuario A

**Resultado Esperado:**
- ✅ Doble check cambia de GRIS a AZUL
- Cambio en tiempo real (1-2 segundos)
- Indica: "leído"

**Timing:**
```
T=0s: Usuario A envía mensaje → ✓✓ gris
T=10s: Usuario B abre chat
T=11s: ✓✓ cambia a azul en pantalla de Usuario A
```

---

#### Test 4.3: Múltiples mensajes
**Pasos:**
1. Usuario A envía 5 mensajes seguidos
2. Todos muestran ✓✓ gris
3. Usuario B abre el chat
4. Verificar todos los mensajes

**Resultado Esperado:**
- ✅ TODOS los mensajes cambian a ✓✓ azul
- El cambio es atómico (todos juntos)

---

#### Test 4.4: Solo en mensajes propios
**Pasos:**
1. Usuario A envía mensaje
2. Usuario B envía respuesta
3. Ambos observan sus pantallas

**Resultado Esperado:**
- ✅ Usuario A ve ✓✓ solo en SU mensaje
- ✅ Usuario B ve ✓✓ solo en SU mensaje
- ❌ No se muestran checks en mensajes recibidos

**Visual (pantalla Usuario A):**
```
[Usuario B]: "Hola"        ← Sin checks
[Usuario A]: "Hola" ✓✓     ← Con checks
```

---

#### Test 4.5: Reconexión de WebSocket
**Pasos:**
1. Usuario A envía mensaje (✓✓ gris)
2. Usuario A cierra la app
3. Usuario B lee el mensaje
4. Usuario A vuelve a abrir la app

**Resultado Esperado:**
- ✅ Al reabrir, el mensaje muestra ✓✓ azul
- El estado de lectura se persiste en base de datos

---

## 5. 📷 ENVÍO DE IMÁGENES POR CHAT

### Objetivo
Verificar que el envío y visualización de imágenes funcione correctamente.

### Pre-requisitos
- Dos usuarios con match mutuo
- Permisos de galería concedidos
- Imágenes de prueba en el dispositivo

### Casos de Prueba

#### Test 5.1: Selección de imagen
**Pasos:**
1. Usuario A abre chat con Usuario B
2. Presionar botón de imagen (📷)
3. Seleccionar imagen de la galería

**Resultado Esperado:**
- ✅ Se abre el selector de galería del sistema
- ✅ Solo se pueden seleccionar imágenes (no videos/otros)
- ✅ Aparece indicador de carga al seleccionar

---

#### Test 5.2: Upload y envío exitoso
**Pasos:**
1. Seleccionar imagen de 2 MB
2. Esperar el upload
3. Observar ambas pantallas (A y B)

**Resultado Esperado:**
- ✅ Indicador de carga mientras sube
- ✅ Imagen aparece en el chat de Usuario A
- ✅ Imagen aparece en el chat de Usuario B (tiempo real)
- ✅ Imagen se muestra con buena calidad
- ⏱️ Tiempo de upload: < 5 segundos

**Visual esperado:**
```
[Usuario A]: [Imagen 200x200px preview]
             10:30 ✓✓
```

---

#### Test 5.3: Optimización de imagen
**Pasos:**
1. Seleccionar imagen grande (8 MB, 4000x3000 px)
2. Enviar
3. Verificar en servidor/Cloudinary

**Resultado Esperado:**
- ✅ Imagen se comprime automáticamente
- ✅ Tamaño reducido a ~200-400 KB
- ✅ Dimensiones máximas 800x800px
- ✅ Calidad aceptable

**Verificación técnica:**
```bash
# Revisar en Cloudinary
# Transformación aplicada: w_800,h_800,c_limit,q_auto:good
```

---

#### Test 5.4: Ver imagen en pantalla completa
**Pasos:**
1. Hacer tap en la imagen en el chat
2. Observar el visor de imagen

**Resultado Esperado:**
- ✅ Imagen se abre en pantalla completa
- ✅ Fondo negro
- ✅ Botón de cerrar visible
- ✅ Se puede hacer zoom (pinch)
- ✅ Se puede mover (pan)

---

#### Test 5.5: Límite de tamaño
**Pasos:**
1. Intentar subir imagen de 15 MB

**Resultado Esperado:**
- ❌ El sistema rechaza la imagen
- ✅ Mensaje de error claro: "Imagen muy grande (máx 10MB)"

---

#### Test 5.6: Tipo de archivo inválido
**Pasos:**
1. Intentar subir un PDF o video

**Resultado Esperado:**
- ❌ Solo se muestran imágenes en el selector
- O se muestra error: "Solo se permiten imágenes"

---

#### Test 5.7: Confirmación de lectura en imágenes
**Pasos:**
1. Usuario A envía imagen
2. Usuario B NO abre el chat
3. Verificar checks en imagen

**Resultado Esperado:**
- ✅ Imagen muestra ✓✓ gris
- Cuando B abre el chat: ✓✓ azul
- Funciona igual que mensajes de texto

---

#### Test 5.8: Error de conexión
**Pasos:**
1. Desactivar internet/WiFi
2. Intentar enviar imagen
3. Reactivar conexión

**Resultado Esperado:**
- ✅ Mensaje de error claro
- ✅ No se pierde la imagen seleccionada
- ✅ Opción de reintentar

---

#### Test 5.9: Múltiples imágenes consecutivas
**Pasos:**
1. Enviar 3 imágenes seguidas
2. Observar el chat

**Resultado Esperado:**
- ✅ Las 3 imágenes se muestran correctamente
- ✅ Cada una con su timestamp y checks
- ✅ Se cargan de forma independiente

---

## 6. 🚹🚺 SELECCIÓN DE GÉNERO AL CREAR CUENTA

### Objetivo
Verificar que el proceso de selección de género durante el registro funcione correctamente.

### Pre-requisitos
- Acceso a la pantalla de registro
- Flujo de registro limpio

### Casos de Prueba

#### Test 6.1: Opciones de género disponibles
**Pasos:**
1. Iniciar proceso de registro
2. Llegar a la página de selección de género
3. Observar opciones disponibles

**Resultado Esperado:**
- ✅ Opciones visibles:
  - Hombre
  - Mujer
  - No binario
  - Prefiero no decir
  - Otro (con campo de texto opcional)

**Visual:**
```
○ Hombre
○ Mujer
○ No binario
○ Prefiero no decir
○ Otro: [_________]
```

---

#### Test 6.2: Selección simple
**Pasos:**
1. Seleccionar "Mujer"
2. Continuar al siguiente paso
3. Volver atrás

**Resultado Esperado:**
- ✅ Opción "Mujer" queda marcada
- ✅ Solo se puede seleccionar UNA opción
- ✅ Al volver, la selección se mantiene

---

#### Test 6.3: Opción "Otro" con texto
**Pasos:**
1. Seleccionar "Otro"
2. Escribir "Género fluido" en el campo
3. Continuar

**Resultado Esperado:**
- ✅ Se habilita el campo de texto
- ✅ Se guarda el texto personalizado
- ✅ Validación: mínimo 2 caracteres

---

#### Test 6.4: Validación de campo requerido
**Pasos:**
1. NO seleccionar ningún género
2. Intentar continuar

**Resultado Esperado:**
- ❌ No permite avanzar
- ✅ Mensaje de error: "Por favor selecciona tu género"

---

#### Test 6.5: Persistencia en base de datos
**Pasos:**
1. Completar registro con género "Hombre"
2. Verificar en base de datos (MongoDB)

**Resultado Esperado:**
```json
{
  "username": "usuario_test",
  "gender": "Hombre",
  // ...
}
```

---

#### Test 6.6: Visualización en perfil
**Pasos:**
1. Completar registro con género seleccionado
2. Ir al perfil propio
3. Verificar que el género se muestre

**Resultado Esperado:**
- ✅ El género aparece en la sección de información personal
- ✅ Icono apropiado (♂️ ♀️ ⚧)

---

#### Test 6.7: Edición posterior
**Pasos:**
1. Usuario ya registrado
2. Ir a editar perfil
3. Cambiar género de "Hombre" a "No binario"
4. Guardar

**Resultado Esperado:**
- ✅ Cambio se guarda correctamente
- ✅ Se refleja en el perfil
- ✅ Afecta el filtrado de matches

---

#### Test 6.8: Privacidad del género
**Pasos:**
1. Usuario selecciona "Prefiero no decir"
2. Otro usuario ve su perfil

**Resultado Esperado:**
- ✅ El campo de género no se muestra públicamente
- O muestra: "Prefiero no especificar"

---

## 7. 💝 ACTUALIZACIÓN DE PANTALLA DE LIKES RECIBIDOS

### Objetivo
Verificar que la pantalla de "Quién te dio like" se actualice automáticamente cuando alguien da like o cuando se crea un match.

### Pre-requisitos
- Al menos 3 usuarios registrados
- Acceso a la pantalla de "Likes recibidos" / "Quién te dio like"
- WebSocket funcionando

### Casos de Prueba

#### Test 7.1: Recibir like en tiempo real
**Pasos:**
1. Usuario A abre la pantalla de "Likes recibidos"
2. Usuario B da like a Usuario A (desde otra pantalla/dispositivo)
3. Observar pantalla de Usuario A

**Resultado Esperado:**
- ✅ La tarjeta de Usuario B aparece AUTOMÁTICAMENTE
- ✅ Sin necesidad de refrescar o salir/entrar
- ✅ Aparece en máximo 2-3 segundos
- ✅ Se muestra con toda la información (foto, nombre, compatibilidad)

**Timing:**
```
T=0s: Usuario B da like
T=1-2s: Notificación WebSocket
T=2-3s: Tarjeta aparece en pantalla de Usuario A
```

---

#### Test 7.2: Múltiples likes consecutivos
**Pasos:**
1. Usuario A está en pantalla de likes recibidos
2. Usuario B da like a Usuario A
3. Usuario C da like a Usuario A
4. Usuario D da like a Usuario A
5. Observar pantalla de Usuario A

**Resultado Esperado:**
- ✅ Las 3 tarjetas aparecen una por una
- ✅ Orden correcto (más reciente primero o al final según diseño)
- ✅ No hay duplicados
- ✅ Todas las tarjetas son clickeables

---

#### Test 7.3: Like que genera match
**Pasos:**
1. Usuario B ya dio like a Usuario A
2. Usuario A está en pantalla de likes recibidos
3. Usuario A ve a Usuario B y le da like (genera match mutuo)
4. Observar ambas pantallas

**Resultado Esperado:**
- ✅ Aparece modal/mensaje de "¡Es un match!"
- ✅ Usuario B desaparece de la lista de likes recibidos
- ✅ Aparece en la lista de matches/chats
- ✅ Usuario A puede ir directo al chat

**Pantalla Usuario A:**
```
Antes:  [Likes recibidos: B, C, D]
Da like a B → ¡Match!
Después: [Likes recibidos: C, D]
         [Matches: B]
```

---

#### Test 7.4: Actualización al salir y volver
**Pasos:**
1. Usuario A está en pantalla de inicio/swipe
2. Usuario B da like a Usuario A
3. Usuario A navega a pantalla de likes recibidos

**Resultado Esperado:**
- ✅ El badge/contador de likes aumenta (ej: 2 → 3)
- ✅ Al entrar, Usuario B está en la lista
- ✅ Badge se actualiza en tiempo real (sin entrar)

**Visual:**
```
Tab "Likes" 
[Badge: 2] → Usuario B da like → [Badge: 3]
```

---

#### Test 7.5: Unlike (si está implementado)
**Pasos:**
1. Usuario B dio like a Usuario A
2. Usuario A ve a B en likes recibidos
3. Usuario B cambia de opinión y da "unlike" (desliza izquierda en su pantalla)
4. Observar pantalla de Usuario A

**Resultado Esperado:**
- ✅ Usuario B desaparece de la lista de A
- ✅ Badge disminuye (3 → 2)
- ✅ Sin errores ni tarjetas vacías

**Nota:** Verificar si la app permite "deshacer like" o no.

---

#### Test 7.6: Reconexión de WebSocket
**Pasos:**
1. Usuario A abre pantalla de likes recibidos
2. Usuario A pierde conexión (modo avión)
3. Usuario B da like a Usuario A
4. Usuario A recupera conexión
5. Observar pantalla

**Resultado Esperado:**
- ✅ Al reconectar, la lista se actualiza
- ✅ Aparece el like de Usuario B
- ✅ Puede requerir pull-to-refresh o automático

---

#### Test 7.7: Estado vacío vs con likes
**Pasos:**
1. Usuario A (nuevo) sin likes recibidos
2. Verificar pantalla de likes recibidos
3. Usuario B da like
4. Observar cambio

**Resultado Esperado:**
- ✅ Estado inicial: mensaje "Aún no has recibido likes"
- ✅ Al recibir like: mensaje desaparece
- ✅ Aparece la tarjeta de Usuario B

**Visual:**
```
Antes:  [💔 "Aún no has recibido likes"]

Después: [Usuario B]
         [Compatibilidad: 85%]
```

---

#### Test 7.8: Dar like desde pantalla de likes recibidos
**Pasos:**
1. Usuario A entra a likes recibidos
2. Ve perfil de Usuario B (que le dio like)
3. Da like desde ahí (genera match)
4. Observar comportamiento

**Resultado Esperado:**
- ✅ Modal de match aparece
- ✅ Usuario B se quita de la lista inmediatamente
- ✅ Opción de "Ir al chat" funcional
- ✅ Badge de likes disminuye

---

#### Test 7.9: Notificación push (si está implementado)
**Pasos:**
1. Usuario A tiene la app cerrada
2. Usuario B da like a Usuario A
3. Verificar notificación

**Resultado Esperado:**
- ✅ Notificación push: "Usuario B te dio like"
- ✅ Al abrir desde la notif: va a pantalla de likes recibidos
- ✅ La tarjeta de B está ahí

---

#### Test 7.10: Performance con muchos likes
**Pasos:**
1. Usuario A tiene 50+ likes recibidos
2. Usuario nuevo da like
3. Scroll en la lista

**Resultado Esperado:**
- ✅ Lista scrolleable sin lag
- ✅ Nuevo like aparece sin afectar performance
- ✅ Lazy loading funcional (si está implementado)

---

## 📊 RESUMEN DE PRUEBAS

| Funcionalidad | Tests | Prioridad | Estado |
|---------------|-------|-----------|--------|
| Filtrado por edad | 4 | 🔴 Alta | ⏳ Pendiente |
| Filtrado por género | 5 | 🔴 Alta | ⏳ Pendiente |
| "Escribiendo..." | 5 | 🟡 Media | ⏳ Pendiente |
| Visto (✓✓) | 5 | 🟡 Media | ⏳ Pendiente |
| Envío de imágenes | 9 | 🔴 Alta | ⏳ Pendiente |
| Selección de género | 8 | 🔴 Alta | ⏳ Pendiente |
| Likes recibidos | 10 | 🔴 Alta | ⏳ Pendiente |
| **TOTAL** | **46** | | |

---

## 🎯 PLAN DE EJECUCIÓN

### Fase 1: Pruebas Críticas (Día 1)
1. ✅ Filtrado por edad (Tests 1.1, 1.2)
2. ✅ Filtrado por género (Tests 2.1, 2.2)
3. ✅ Selección de género (Tests 6.1, 6.2, 6.4)
4. ✅ Likes recibidos (Tests 7.1, 7.3, 7.4)

### Fase 2: Funcionalidades de Chat (Día 2)
1. ✅ Envío de imágenes (Tests 5.1-5.5)
2. ✅ "Escribiendo..." (Tests 3.1, 3.2)
3. ✅ Visto (Tests 4.1, 4.2)

### Fase 3: Casos Edge (Día 3)
1. ✅ Tests de timeout y reconexión
2. ✅ Tests de errores y validaciones
3. ✅ Tests de múltiples usuarios simultáneos
4. ✅ Likes recibidos con reconexión (Test 7.6)
5. ✅ Performance con muchos likes (Test 7.10)

---

## 📝 FORMATO DE REPORTE

Para cada test ejecutado, documentar:

```markdown
### Test X.Y: [Nombre]
**Fecha:** DD/MM/YYYY
**Ejecutado por:** [Nombre]
**Resultado:** ✅ Pasó / ❌ Falló / ⚠️ Parcial

**Observaciones:**
- [Detalle de lo observado]

**Screenshots:**
- [Adjuntar capturas]

**Issues encontrados:**
- [Si aplica, describir bugs]
```

---

## 🐛 CRITERIOS DE ACEPTACIÓN

✅ **PASA** si:
- Funciona como se describe en "Resultado Esperado"
- Sin crashes ni errores de consola
- Performance aceptable (< 3 segundos)

❌ **FALLA** si:
- No funciona como se espera
- Causa crash o error
- Experiencia de usuario deficiente

⚠️ **PARCIAL** si:
- Funciona pero con issues menores
- Performance mejorable
- UX puede optimizarse

---

## 🚀 ENTORNO DE PRUEBAS

**Backend:**
- URL: https://roomier-production.up.railway.app
- MongoDB: Atlas M0

**App:**
- Android: Versión X.X.X
- iOS: Versión X.X.X (si aplica)

**Usuarios de prueba:**
```
Usuario 1: test_user_1 / password123
Usuario 2: test_user_2 / password123
Usuario 3: test_user_3 / password123
```

---

**Próxima Actualización:** Después de ejecutar Fase 1 de pruebas
**Responsable:** [Nombre del QA/Desarrollador]
