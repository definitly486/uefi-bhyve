<#
    clean_graphics.ps1

    Удаляет из папки с драйвером Intel Graphics (igdlh64.inf) все файлы,
    которые больше не нужны после урезания inf (без Control Panel/трея,
    Vulkan, OpenCL, WiDi/Miracast, кодеков Media SDK, HDCP/HECI-служб,
    мобильных вариантов OpenGL и демо-роликов).

    По умолчанию скрипт работает в режиме DRY-RUN — только показывает,
    что было бы удалено, ничего не трогая. Чтобы реально удалить файлы,
    запустите с ключом -Delete.

    Использование:
        .\clean_graphics.ps1 -Path "C:\путь\к\Graphics"
        .\clean_graphics.ps1 -Path "C:\путь\к\Graphics" -Delete
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [switch]$Delete
)

if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    Write-Error "Папка не найдена: $Path"
    exit 1
}

# Файлы, необходимые урезанному igdlh64.inf (ядро драйвера + coinstaller +
# базовый OpenGL), плюс сам inf и каталог подписи.
$Keep = @(
    'igdlh64.inf'
    'igdlh.cat'
    'difx64.exe'
    'displayaudiox64.cab'
    'ig9icd32.dll'
    'ig9icd64.dll'
    'iga32.dll'
    'iga64.dll'
    'igc32.dll'
    'igc64.dll'
    'igd10idpp32.dll'
    'igd10idpp64.dll'
    'igd10iumd32.dll'
    'igd10iumd64.dll'
    'igd11dxva32.dll'
    'igd11dxva64.dll'
    'igd12umd32.dll'
    'igd12umd64.dll'
    'igdail32.dll'
    'igdail64.dll'
    'igdde32.dll'
    'igdde64.dll'
    'igdkmd64.sys'
    'igdmd32.dll'
    'igdmd64.dll'
    'igdumdim32.dll'
    'igdumdim64.dll'
    'igdusc32.dll'
    'igdusc64.dll'
    'igfx11cmrt32.dll'
    'igfx11cmrt64.dll'
    'igfxcmjit32.dll'
    'igfxcmjit64.dll'
    'igfxcmrt32.dll'
    'igfxcmrt64.dll'
    'iglhcp32.dll'
    'iglhsip32.dll'
    'igxpco64.dll'
    'igxpun.exe'
    'intelcphdcpsvc.exe'
    'intelcphecisvc.exe'
)
$KeepSet = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]($Keep | ForEach-Object { $_.ToLowerInvariant() })
)

# Папка Lang (локализация панели управления, которую мы вырезали) удаляется целиком
$LangDir = Join-Path $Path 'Lang'

$toDelete = Get-ChildItem -LiteralPath $Path -File |
    Where-Object { -not $KeepSet.Contains($_.Name.ToLowerInvariant()) }

Write-Host "Папка: $Path"
Write-Host "Файлов оставить: $($KeepSet.Count) (некоторых может не быть в вашем наборе)"
Write-Host "Файлов на удаление: $($toDelete.Count)"
Write-Host ""

foreach ($f in $toDelete) {
    if ($Delete) {
        Remove-Item -LiteralPath $f.FullName -Force
        Write-Host "Удалён: $($f.Name)"
    } else {
        Write-Host "Будет удалён: $($f.Name)"
    }
}

if (Test-Path -LiteralPath $LangDir -PathType Container) {
    if ($Delete) {
        Remove-Item -LiteralPath $LangDir -Recurse -Force
        Write-Host "Удалена папка: Lang"
    } else {
        Write-Host "Будет удалена папка: Lang"
    }
}

if (-not $Delete) {
    Write-Host ""
    Write-Host "Это был просмотр (dry-run). Чтобы реально удалить файлы, запустите:"
    Write-Host "    .\clean_graphics.ps1 -Path `"$Path`" -Delete"
}
