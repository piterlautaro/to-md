# 🛠️ TO-MD CLI (`tomd.bat`)
> **Modo Markdown LLM:** Herramienta automatizada en entorno Windows para empaquetar, estructurar y optimizar el código fuente de módulos específicos en archivos `.md` perfectamente digeribles por Inteligencias Artificiales.

Este script híbrido (Batch/PowerShell) toma un directorio de origen, filtra su contenido según extensiones permitidas o prohibidas, remueve ruido y genera salidas limpias optimizadas para no saturar las ventanas de contexto de los LLMs (como Gemini, Claude o ChatGPT).

---

## 🚀 Características Principales

- **Filtros Flexibles:** Permite incluir (`--only`) o excluir (`--exclude`) tipos de archivos específicos de manera rápida.
- **Estructuración Semántica:** Genera bloques de código con sintaxis Markdown nativa que la IA parsea de forma nativa.
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