<# :
@echo off
setlocal
chcp 65001 >nul
:: Validar que se reciba al menos la carpeta
if "%~1"=="" (
    echo Error: Debes especificar el nombre de la carpeta.
    exit /b 1
)
:: Ejecutar el bloque PowerShell inferior pasando TODOS los argumentos (%*)
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([ScriptBlock]::Create((Get-Content '%~f0' -Raw)))" %*
exit /b %errorlevel%
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 1. Parseo de Argumentos
$sourceDir = ""
$onlyExts = @()
$excludeExts = @()
$treeOnly = $false

foreach ($arg in $args) {
    if ($arg -match "^--only=(.+)") {
        $onlyExts = $matches[1] -split "," | ForEach-Object { $_.Trim().ToLower() -replace '^\.', '' }
    } elseif ($arg -match "^--exclude=(.+)") {
        $excludeExts = $matches[1] -split "," | ForEach-Object { $_.Trim().ToLower() -replace '^\.', '' }
    } elseif ($arg -eq "--tree") {
        $treeOnly = $true
    } elseif ($sourceDir -eq "") {
        $sourceDir = $arg
    }
}

if (-not (Test-Path $sourceDir)) {
    Write-Host "Error: La carpeta '$sourceDir' no existe." -ForegroundColor Red
    exit
}

# 2. Rutas y Carpetas
$normalizedPath = (Resolve-Path $sourceDir).Path
$folderName = (Get-Item $normalizedPath).Name
$currentPath = (Get-Location).Path
$destDir = Join-Path $currentPath "${folderName}_md"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
}

# 3. Configuración de Codificación (Win1252 -> UTF8)
try {
    $win1252Encoding = [System.Text.Encoding]::GetEncoding(1252)
} catch {
    [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
    $win1252Encoding = [System.Text.Encoding]::GetEncoding(1252)
}
$utf8Encoding = New-Object System.Text.UTF8Encoding($false)

# 4. Obtener y Filtrar Archivos
$allFiles = @(Get-ChildItem -Path $sourceDir -File -Recurse)
$filesToProcess = @()
$omittedFiles = @()

foreach ($file in $allFiles) {
    $ext = $file.Extension.ToLower() -replace '^\.', ''
    $include = $true

    if ($onlyExts.Count -gt 0 -and $ext -notin $onlyExts) {
        $include = $false
    }
    if ($excludeExts.Count -gt 0 -and $ext -in $excludeExts) {
        $include = $false
    }

    if ($include) {
        $filesToProcess += $file
    } else {
        $omittedFiles += $file
    }
}

$totalFiles = $filesToProcess.Count
$basePath = $normalizedPath.TrimEnd('\')
$successCount = 0
$errorCount = 0

Write-Host "Analizando $($allFiles.Count) archivos totales... ($totalFiles pasaron los filtros)" -ForegroundColor Cyan

# 5. Crear Índice del Árbol (En formato Markdown)
$indexFile = Join-Path $destDir "_00_arbol_indice.md"
$treeOutput = & tree.com $normalizedPath /F /A
$treeContent = "# ÍNDICE DEL DIRECTORIO (Contexto Estructural)`r`n`r`n"
$treeContent += "**Proyecto:** $folderName  `r`n"
$treeContent += "**Nota:** Este es el árbol original del proyecto. Más abajo se detallan los archivos excluidos.`r`n`r`n"
$treeContent += "```text`r`n"
$treeContent += ($treeOutput -join "`r`n")
$treeContent += "`r`n````r`n"

if ($omittedFiles.Count -gt 0) {
    $treeContent += "`r`n## ARCHIVOS OMITIDOS DEL CONTEXTO`r`n"
    $treeContent += "(Filtrados por reglas --only o --exclude)`r`n`r`n"
    foreach ($omitted in $omittedFiles) {
        $rel = $omitted.FullName.Substring($basePath.Length) -replace '\\', '/'
        $treeContent += "- `/$folderName$rel``r`n"
    }
}
[System.IO.File]::WriteAllText($indexFile, $treeContent, $utf8Encoding)

if ($treeOnly) {
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host " MODO --tree: Solo se genero el arbol de directorio" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host " Origen  : $folderName"
    Write-Host " Destino : ${folderName}_md/_00_arbol_indice.md"
    Write-Host "=================================================" -ForegroundColor Cyan
    exit
}

# 6. Estrategia de Agrupación (Límite NotebookLM = 300 fuentes)
$maxStandalone = 250
$chunkSize = 40
$standaloneFiles = @()
$groupedFiles = @()

if ($totalFiles -gt 290) {
    $sortedFiles = $filesToProcess | Sort-Object Length -Descending
    $standaloneFiles = $sortedFiles | Select-Object -First $maxStandalone
    $groupedFiles = $sortedFiles | Select-Object -Skip $maxStandalone
} else {
    $standaloneFiles = $filesToProcess
}

# 7. Procesar Archivos Individuales (Ahora como .md)
foreach ($file in $standaloneFiles) {
    $relPath = $file.FullName.Substring($basePath.Length) -replace '\\', '/'
    $fullRelPath = "/$folderName$relPath"
    $ext = $file.Extension.ToLower() -replace '^\.', ''
    
    $destFileName = $file.BaseName + ".md"
    $destFile = Join-Path $destDir $destFileName
    $counter = 1
    while (Test-Path $destFile) {
        $destFile = Join-Path $destDir ($file.BaseName + "_$counter.md")
        $counter++
    }

    $header = "### Archivo: $fullRelPath`r`n`r`n"
    $header += "``````$ext`r`n"
    $footer = "`r`n```````r`n"

    try {
        $content = [System.IO.File]::ReadAllText($file.FullName, $win1252Encoding)
        [System.IO.File]::WriteAllText($destFile, $header + $content + $footer, $utf8Encoding)
        $successCount++
    } catch {
        Write-Host "  -> Error/Binario omitido en procesamiento: $($file.Name)" -ForegroundColor DarkYellow
        $errorCount++
    }
}

# 8. Procesar Archivos Agrupados (Ahora como .md)
$groupCount = 0
if ($groupedFiles.Count -gt 0) {
    $chunks = [math]::Ceiling($groupedFiles.Count / $chunkSize)
    
    for ($i = 0; $i -lt $chunks; $i++) {
        $groupCount++
        $chunkFiles = $groupedFiles | Select-Object -Skip ($i * $chunkSize) -First $chunkSize
        
        $destFile = Join-Path $destDir "_01_archivos_agrupados_$groupCount.md"
        $combinedContent = "# ARCHIVOS AGRUPADOS (Parte $groupCount)`r`n`r`n"

        foreach ($file in $chunkFiles) {
            $relPath = $file.FullName.Substring($basePath.Length) -replace '\\', '/'
            $fullRelPath = "/$folderName$relPath"
            $ext = $file.Extension.ToLower() -replace '^\.', ''
            
            $combinedContent += "---`r`n"
            $combinedContent += "### Archivo: $fullRelPath`r`n`r`n"
            $combinedContent += "``````$ext`r`n"
            
            try {
                $content = [System.IO.File]::ReadAllText($file.FullName, $win1252Encoding)
                $combinedContent += $content + "`r`n"
                $combinedContent += "```````r`n`r`n"
                $successCount++
            } catch {
                $combinedContent += "// [ERROR: Archivo omitido por formato ilegible o binario]`r`n"
                $combinedContent += "```````r`n`r`n"
                $errorCount++
            }
        }
        [System.IO.File]::WriteAllText($destFile, $combinedContent, $utf8Encoding)
    }
}

$totalGeneratedFiles = 1 + $standaloneFiles.Count + $groupCount

# --- FEEDBACK Y ESTADÍSTICAS FINALES ---
Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " REPORTE DE CONVERSIÓN (MODO MARKDOWN LLM)"       -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " Origen  : $folderName"
Write-Host " Destino : ${folderName}_md (Contiene archivos .md)"
Write-Host "-------------------------------------------------"
Write-Host " Archivos en la carpeta   : $($allFiles.Count)"
Write-Host " Excluidos por filtros    : $($omittedFiles.Count)" -ForegroundColor DarkYellow
Write-Host " Archivos a procesar      : $totalFiles"
Write-Host " Transformados con éxito  : $successCount" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host " Fallos lectura (Binarios): $errorCount" -ForegroundColor Red
}
Write-Host "-------------------------------------------------"
Write-Host " RESUMEN DE SALIDA (Máximo permitido: 300)"
Write-Host " - Índice de árbol y log  : 1"
Write-Host " - Archivos individuales  : $($standaloneFiles.Count)"
Write-Host " - Archivos combinados    : $groupCount"
if ($totalGeneratedFiles -le 300) {
    Write-Host " TOTAL ARCHIVOS CREADOS   : $totalGeneratedFiles (OK)" -ForegroundColor Green
} else {
    Write-Host " TOTAL ARCHIVOS CREADOS   : $totalGeneratedFiles (ALERTA)" -ForegroundColor Red
}
Write-Host "=================================================" -ForegroundColor Cyan