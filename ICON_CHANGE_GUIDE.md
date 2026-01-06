# Guía de Cambio de Íconos de la App - Roomier

## 📋 Resumen
Se ha configurado el cambio de íconos de Flutter por el logo de Roomier en:
- ✅ Ícono del menú del teléfono (launcher icon)
- ✅ Ícono de splash screen (al abrir la app)
- ✅ Ícono de notificaciones push

## 🎯 Archivos Configurados

### 1. Configuración de Íconos de Launcher

**Archivo**: `pubspec.yaml`

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

# Configuración de íconos de la app
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/R.jpg"
  # Para notificaciones en Android (debe ser monocromo)
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/R.jpg"
```

**Comando ejecutado**:
```bash
flutter pub run flutter_launcher_icons
```

Esto generó automáticamente:
- ✅ Íconos para Android en todas las densidades (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- ✅ Íconos para iOS en todos los tamaños requeridos
- ✅ Adaptive icons para Android (API 26+)

### 2. Ícono de Notificaciones (Android)

**Archivo**: `android/app/src/main/AndroidManifest.xml`

```xml
<!-- Icono de notificación (debe ser drawable monocromo) -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />

<!-- Color del icono de notificación -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />
```

**Archivo creado**: `android/app/src/main/res/drawable/ic_notification.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <!-- R estilizada para Roomier -->
    <path
        android:fillColor="@android:color/white"
        android:pathData="M8,6 L8,18 M8,6 L14,6 C15.66,6 17,7.34 17,9 C17,10.66 15.66,12 14,12 L8,12 M14,12 L17,18"/>
</vector>
```

**Archivo modificado**: `android/app/src/main/res/values/colors.xml`
```xml
<color name="notification_color">#2196F3</color>
```

## 🖼️ Logo Utilizado

**Ubicación**: `assets/R.jpg`

**Requisitos del logo para mejores resultados**:
- ✅ Formato: PNG o JPG
- ✅ Tamaño mínimo: 1024x1024 px (recomendado)
- ✅ Fondo: Preferiblemente transparente (PNG) o blanco
- ✅ Logo centrado con márgenes adecuados

## 📱 Plataformas Soportadas

### Android
- **Launcher Icon**: ✅ Configurado
  - Generados para todas las densidades (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
  - Adaptive icons para Android 8.0+ (API 26+)
  
- **Notification Icon**: ✅ Configurado
  - Ícono vectorial monocromo
  - Color azul (#2196F3) cuando aparece en notificaciones
  
- **Splash Screen**: ✅ Usa el launcher icon automáticamente

### iOS
- **App Icon**: ✅ Configurado
  - Generados todos los tamaños requeridos por Apple
  - Incluye íconos para iPhone, iPad, App Store
  
- **Notification Icon**: ✅ iOS usa el app icon automáticamente
  
- **Launch Screen**: ✅ Usa el app icon en el storyboard

## 🔧 Cómo Cambiar el Logo en el Futuro

### Opción 1: Cambiar el archivo actual
1. Reemplaza `assets/R.jpg` con tu nuevo logo
2. Asegúrate de que mantenga el mismo nombre: `R.jpg`
3. Ejecuta:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

### Opción 2: Usar un archivo diferente
1. Agrega el nuevo logo a `assets/` (ej: `logo_nuevo.png`)
2. Modifica `pubspec.yaml`:
   ```yaml
   flutter_launcher_icons:
     image_path: "assets/logo_nuevo.png"
   ```
3. Ejecuta:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

## 🎨 Personalización Avanzada

### Cambiar el ícono de notificación

Si quieres un ícono diferente para notificaciones, edita:
`android/app/src/main/res/drawable/ic_notification.xml`

Ejemplo de íconos alternativos:

**Ícono de casa**:
```xml
<path
    android:fillColor="@android:color/white"
    android:pathData="M10,20v-6h4v6h5v-8h3L12,3 2,12h3v8z"/>
```

**Ícono de chat**:
```xml
<path
    android:fillColor="@android:color/white"
    android:pathData="M20,2H4c-1.1,0-1.99,0.9-1.99,2L2,22l4-4h14c1.1,0,2-0.9,2-2V4c0-1.1-0.9-2-2-2zM6,9h12v2H6V9zm8,5H6v-2h8v2zm4-6H6V6h12v2z"/>
```

### Cambiar el color de notificación

Edita `android/app/src/main/res/values/colors.xml`:
```xml
<!-- Azul actual -->
<color name="notification_color">#2196F3</color>

<!-- Otras opciones -->
<color name="notification_color">#FF5722</color> <!-- Naranja -->
<color name="notification_color">#4CAF50</color> <!-- Verde -->
<color name="notification_color">#9C27B0</color> <!-- Morado -->
```

## 🧪 Verificación

### Android
1. **Launcher Icon**:
   ```bash
   flutter run
   ```
   - Verifica el ícono en el drawer de apps
   - Verifica el ícono en la pantalla de inicio después de instalar

2. **Notification Icon**:
   - Envía una notificación de prueba
   - Verifica que aparezca el ícono correcto en la barra de notificaciones

3. **Splash Screen**:
   - Cierra y vuelve a abrir la app
   - Verifica el logo durante el inicio

### iOS
1. **App Icon**:
   ```bash
   flutter run -d <ios-device>
   ```
   - Verifica el ícono en el Home Screen
   - Verifica en la App Library

2. **Launch Screen**:
   - Cierra y vuelve a abrir la app
   - Verifica el logo durante el inicio

## 📝 Notas Importantes

### Android
- ⚠️ **Notificaciones**: El ícono debe ser monocromo (solo silueta blanca)
- ⚠️ **Adaptive Icons**: En Android 8.0+, el sistema puede recortar o aplicar forma al ícono
- ⚠️ **Background color**: Asegúrate de que el color de fondo contraste con el logo

### iOS
- ⚠️ **Sin transparencia**: iOS no permite íconos con transparencia
- ⚠️ **Sin bordes redondeados**: El sistema los aplica automáticamente
- ⚠️ **Todos los tamaños**: Debe generarse para todos los dispositivos (iPhone, iPad)

## 🔄 Regenerar Íconos Después de Cambios

Si modificas el logo o la configuración:

```bash
# 1. Limpiar caché de Flutter
flutter clean

# 2. Obtener dependencias
flutter pub get

# 3. Regenerar íconos
flutter pub run flutter_launcher_icons

# 4. Reconstruir la app
flutter run
```

## 🚀 Despliegue

### Para Android (Play Store)
Los íconos generados cumplen con los requisitos de Google Play:
- ✅ Adaptive icon para Android 8.0+
- ✅ Íconos de alta resolución (xxxhdpi)
- ✅ Formato correcto

### Para iOS (App Store)
Los íconos generados cumplen con los requisitos de Apple:
- ✅ Todos los tamaños requeridos
- ✅ Sin transparencia
- ✅ Formato correcto

**Nota**: Adicionalmente, necesitarás un ícono de 1024x1024 px para el App Store. Este se genera automáticamente en `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.

## 🎨 Herramientas Recomendadas

Para crear/editar íconos de notificación:

1. **Android Asset Studio**: https://romannurik.github.io/AndroidAssetStudio/
2. **Figma**: Para diseñar vectores
3. **GIMP/Photoshop**: Para editar imágenes

Para convertir imágenes a vectores (XML):
1. **svg2android**: https://svg2android.com/
2. **Vector Asset Studio**: Integrado en Android Studio

## 📊 Estructura de Archivos Generados

```
android/app/src/main/res/
├── drawable/
│   └── ic_notification.xml          # Ícono de notificación
├── drawable-*/                       # Launcher background (varias densidades)
├── mipmap-anydpi-v26/
│   └── ic_launcher.xml               # Adaptive icon config
├── mipmap-hdpi/
│   └── ic_launcher.png               # 72x72
├── mipmap-mdpi/
│   └── ic_launcher.png               # 48x48
├── mipmap-xhdpi/
│   └── ic_launcher.png               # 96x96
├── mipmap-xxhdpi/
│   └── ic_launcher.png               # 144x144
├── mipmap-xxxhdpi/
│   └── ic_launcher.png               # 192x192
└── values/
    └── colors.xml                    # Colores (notification_color)

ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── Icon-App-20x20@1x.png
├── Icon-App-20x20@2x.png
├── Icon-App-29x29@1x.png
├── Icon-App-29x29@2x.png
├── Icon-App-40x40@1x.png
├── Icon-App-40x40@2x.png
├── Icon-App-60x60@2x.png
├── Icon-App-60x60@3x.png
├── Icon-App-76x76@1x.png
├── Icon-App-76x76@2x.png
├── Icon-App-83.5x83.5@2x.png
└── Icon-App-1024x1024@1x.png        # App Store
```

## 🐛 Problemas Comunes

### El ícono no cambia en Android
```bash
# Solución 1: Limpiar y reconstruir
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons
flutter run

# Solución 2: Desinstalar la app del dispositivo
adb uninstall com.example.rommier
flutter run
```

### El ícono de notificación aparece como cuadrado blanco
- ✅ Verifica que `ic_notification.xml` existe
- ✅ Asegúrate de que sea un vector drawable (XML)
- ✅ El color debe ser `@android:color/white`

### iOS no muestra el ícono correcto
```bash
# Limpiar build de iOS
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

---
**Última actualización**: 5 de enero de 2026
