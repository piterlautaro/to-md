# 🛠️ TO-MD CLI (`tomd.bat`)
> **Modo Markdown LLM:** Herramienta automatizada en entorno Windows para empaquetar, estructurar y optimizar el código fuente de módulos específicos en archivos `.md` perfectamente digeribles por Inteligencias Artificiales.

Este script híbrido (Batch/PowerShell) toma un directorio de origen, filtra su contenido según extensiones permitidas o prohibidas, remueve ruido y genera salidas limpias optimizadas para no saturar las ventanas de contexto de los LLMs (como Gemini, Claude, ChatGPT o DeepSeek).

---

## 🚀 Características Principales

- **Filtros Flexibles:** Permite incluir (`--only`) o excluir (`--exclude`) tipos de archivos específicos de manera rápida.
- **Estructuración Semántica:** Genera bloques de código con sintaxis Markdown nativa que la IA parsea a la perfección.
- **Árbol de Directorio Automatizado:** Adjunta de forma automática un índice visual de la estructura del módulo.
- **Control de Volumen:** Optimizado para segmentar o agrupar archivos evitando superar límites físicos o lógicos de almacenamiento en cargas por lotes (Límite sugerido: 300 archivos).
- **Reporte en Tiempo Real:** Feedback detallado en consola con códigos de color sobre el estado de la conversión.

---

## 📦 Instalación y Requisitos

1. **Requisitos:** Windows 10/11 con PowerShell habilitado.
2. **Instalación:** Coloca el archivo `tomd.bat` en la raíz de tu proyecto o añádelo a una variable de entorno `PATH` para poder ejecutarlo globalmente desde cualquier terminal (CMD o PowerShell).

---

## 📖 Modo de Uso y Sintaxis

La estructura básica del comando es:

```bash
tomd <carpeta_modulo> [opciones]
```

### Parámetros:
* `<carpeta_modulo>` *(Obligatorio)*: La ruta relativa o absoluta del módulo o subdirectorio que deseas procesar (Ej: `src/api` o `app/Http`).

### Opciones y Flags:
* `--only=ext1,ext2...` *(Opcional)*: Procesa **únicamente** las extensiones especificadas (separadas por comas).
* `--exclude=ext1,ext2...` *(Opcional)*: Ignora y salta por completo las extensiones indicadas.
* `--tree` *(Opcional)*: Genera **solamente** el archivo de árbol de directorio (`_00_arbol_indice.md`) sin procesar ni convertir ningún archivo fuente. Útil para obtener una vista rápida de la estructura del proyecto.

---

## 💡 Ejemplos Prácticos

### 1. Conversión estándar (Todo un módulo)
Procesa todos los archivos legibles dentro de la carpeta del módulo seleccionado:
```bash
tomd src/controllers
```
*Crea una nueva estructura en el directorio resultante `src/controllers_md`.*

### 2. Filtrar solo lógica de programación (`--only`)
Ideal si solo quieres enviarle a la IA la lógica de negocio y controladores, ignorando estilos o consultas de bases de datos pesadas:
```bash
tomd app/Services --only=php,js,ts
```

### 3. Excluir formatos pesados o configuraciones (`--exclude`)
Ideal para evitar que archivos estáticos, configuraciones locales o documentación previa contaminen el contexto de la especificación:
```bash
tomd src/modules/auth --exclude=sql,md,json,lock
```

### 4. Combinando exclusión en rutas complejas
Si ejecutas el comando desde la raíz del proyecto apuntando a un submódulo profundo:
```bash
tomd src/components/billing --only=ts --exclude=spec.ts
```

### 5. Generar solo el árbol de directorio (`--tree`)
Cuando solo necesitas visualizar la estructura del proyecto sin convertir archivos:
```bash
tomd src/modules/auth --tree
```
*Genera únicamente `_00_arbol_indice.md` dentro de `auth_md/` con el árbol completo de carpetas y archivos.*

---

## 📊 Salida de Datos y Reporte

Al finalizar la ejecución con éxito, el comando generará una carpeta paralela llamada `<Nombre>_md` y desplegará en tu consola un reporte visual detallado:

```text
=================================================
 REPORTE DE CONVERSIÓN (MODO MARKDOWN LLM)
=================================================
 Origen  : src/controllers
 Destino : src/controllers_md (Contiene archivos .md)
-------------------------------------------------
 Archivos en la carpeta   : 42
 Excluidos por filtros    : 12
 Archivos a procesar      : 30
 Transformados con éxito  : 30
-------------------------------------------------
 RESUMEN DE SALIDA (Máximo permitido: 300)
 - Índice de árbol y log  : 1
 - Archivos individuales  : 29
 TOTAL ARCHIVOS CREADOS   : 30 (OK)
=================================================
```

---

## 🧠 Flujo de Trabajo Sugerido para Spec-Driven Development (SDD)

1. **Generar Contexto:** Ejecuta `tomd src/modules/auth --only=ts` para aislar el backend de tu módulo de autenticación.
2. **Alimentar a la IA:** Sube el archivo Markdown del árbol de directorio y los archivos críticos generados en el paso anterior a tu chat con la IA o agente de desarrollo.
3. **Contrastar con la Spec:** Provee tu documento de especificaciones (`Spec.md` o archivo OpenAPI) y dile al modelo: *"Basándote en el diseño actual del módulo provisto en estos archivos Markdown, implementa la nueva regla de negocio descrita en la Spec"*.