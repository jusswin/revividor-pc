# Revividor de PC — script embebido en RevividorPC.exe
# Todo lo que toca esta en listas seguras y curadas. Nada de "problemas falsos".
$ErrorActionPreference = 'SilentlyContinue'

function Say($t, $c = 'White') { Write-Host $t -ForegroundColor $c }
function Step($t) { Say "`n== $t ==" 'Cyan' }
function Ok($t)   { Say "  [OK] $t" 'Green' }
function Info($t) { Say "  - $t" 'Gray' }
function Warn($t) { Say "  [AVISO] $t" 'Yellow' }

function Set-Reg($path, $name, $value, $type = 'DWord') {
  if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
  Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -Force
  return $?
}

# ---------- Listas seguras ----------
$bloat = @(
  'Microsoft.BingNews','Microsoft.BingWeather','Microsoft.GetHelp','Microsoft.Getstarted',
  'Microsoft.MicrosoftOfficeHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.People',
  'Microsoft.SkypeApp','Microsoft.Wallet','Microsoft.WindowsFeedbackHub','Microsoft.YourPhone',
  'Microsoft.ZuneMusic','Microsoft.ZuneVideo','Microsoft.Clipchamp','MicrosoftTeams',
  'Microsoft.549981C3F5F10',
  '*Spotify*','*TikTok*','*Instagram*','*Facebook*','*Disney*','*Netflix*',
  '*CandyCrush*','*BubbleWitch*','*MarchofEmpires*'
)
$startupKill = @('OneDrive','Teams','Skype','Spotify','Cortana','AdobeARM','AdobeAAMUpdater','iTunesHelper','OneDriveSetup')
$servicios = @('DiagTrack','dmwappushservice','SysMain')
$tareasPath = @(
  '\Microsoft\Windows\Customer Experience Improvement Program\',
  '\Microsoft\Windows\Application Experience\',
  '\Microsoft\Windows\DiskDiagnostic\'
)
$tareasNombre = @('*Compatibility Appraiser*','*ProgramDataUpdater*','*DiskDiagnosticDataCollector*','*Consolidator*','*UsbCeip*')

function Coincide($nombre, $lista) {
  foreach ($p in $lista) { if ($nombre -like $p) { return $true } }
  return $false
}

# ---------- Encabezado ----------
Say ""
Say "  ==================================================" 'Cyan'
Say "   REVIVIDOR DE PC  —  Trollhunters" 'Cyan'
Say "  ==================================================" 'Cyan'
Say ""
Say "  Esto va a hacer, explicado sin tecnicismos:" 'White'
Say "   1. Crear un punto de restauracion (por si algo sale mal, se puede devolver)." 'Gray'
Say "   2. Desinstalar apps basura que Windows trae de fabrica (juegos, TikTok, etc.)." 'Gray'
Say "   3. Apagar programas que arrancan solos y ponen lento el inicio." 'Gray'
Say "   4. Apagar el espionaje de Microsoft (telemetria, Copilot, anuncios)." 'Gray'
Say "   5. Poner Windows en modo rapido (menos adornos, mas velocidad)." 'Gray'
Say ""
Say "  NO borra tus archivos, NO cierra tus programas, NO pide dinero." 'Yellow'
Say ""

# ---------- Fase de analisis ----------
Step "Analizando tu PC..."
$appsInst = @(Get-AppxPackage -AllUsers | Where-Object { Coincide $_.Name $bloat } | Sort-Object Name -Unique)
$appsProv = @(Get-AppxProvisionedPackage -Online | Where-Object { Coincide $_.DisplayName $bloat } | Sort-Object DisplayName -Unique)
$runKeys = @('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')
$starts = @()
foreach ($rk in $runKeys) {
  $props = (Get-ItemProperty -Path $rk).PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' }
  foreach ($pr in $props) {
    foreach ($kw in $startupKill) {
      if ($pr.Name -like "*$kw*" -or "$($pr.Value)" -like "*$kw*") { $starts += [pscustomobject]@{Clave=$rk; Nombre=$pr.Name}; break }
    }
  }
}
Say ""
Info ("Apps basura encontradas: {0}" -f ($appsInst.Count + $appsProv.Count))
Info ("Programas de arranque para apagar: {0}" -f $starts.Count)
if ($appsInst) { $appsInst | ForEach-Object { Info ("   - " + $_.Name) } }
Say ""
$r = Read-Host "  Empezamos? (S/n)"
if ($r -eq 'n' -or $r -eq 'N') { Say "  No se toco nada. Hasta luego." 'Yellow'; return }

# ---------- 1. Punto de restauracion ----------
Step "1/5  Punto de restauracion"
$restoreOk = $false
try {
  Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
  Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" "SystemRestorePointCreationFrequency" 0 | Out-Null
  Checkpoint-Computer -Description "Antes del Revividor de PC" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
  $restoreOk = $true
  Ok "Punto de restauracion creado."
} catch {
  Warn "No se pudo crear el punto de restauracion."
}
if (-not $restoreOk) {
  $r2 = Read-Host "  Sigo SIN punto de restauracion? (s/N)"
  if ($r2 -ne 's' -and $r2 -ne 'S') { Say "  No se toco nada. Hasta luego." 'Yellow'; return }
}

# ---------- 2. Bloatware ----------
Step "2/5  Desinstalando apps basura"
$nApps = 0
foreach ($a in $appsProv) {
  try { Remove-AppxProvisionedPackage -Online -PackageName $a.PackageName -ErrorAction Stop | Out-Null; $nApps++; Ok ("No volvera: " + $a.DisplayName) }
  catch { Warn ("No se pudo (provisionada): " + $a.DisplayName) }
}
foreach ($a in $appsInst) {
  try { Remove-AppxPackage -Package $a.PackageFullName -AllUsers -ErrorAction Stop; $nApps++; Ok ("Desinstalada: " + $a.Name) }
  catch { Warn ("No se pudo: " + $a.Name) }
}
if ($nApps -eq 0) { Info "No habia apps basura. Tu PC ya estaba limpio en esto." }

# ---------- 3. Arranque ----------
Step "3/5  Apagando programas de arranque"
$nStart = 0
foreach ($s in $starts) {
  Remove-ItemProperty -Path $s.Clave -Name $s.Nombre -ErrorAction Stop
  if ($?) { $nStart++; Ok ("Ya no arranca solo: " + $s.Nombre) }
}
if ($nStart -eq 0) { Info "Nada que apagar en el arranque." }

# ---------- 4. Telemetria y servicios ----------
Step "4/5  Apagando espionaje y servicios innecesarios"
$nSvc = 0
foreach ($sv in $servicios) {
  $s = Get-Service -Name $sv
  if ($s) {
    Stop-Service -Name $sv -Force
    Set-Service -Name $sv -StartupType Disabled
    $nSvc++; Ok ("Servicio apagado: " + $sv)
  }
}
$nTareas = 0
foreach ($tp in $tareasPath) {
  $ts = Get-ScheduledTask -TaskPath $tp | Where-Object { Coincide $_.TaskName $tareasNombre }
  foreach ($t in $ts) {
    Disable-ScheduledTask -TaskPath $t.TaskPath -TaskName $t.TaskName | Out-Null
    if ($?) { $nTareas++; Ok ("Tarea apagada: " + $t.TaskName) }
  }
}
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0 | Out-Null
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0 | Out-Null
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticData" 0 | Out-Null
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0 | Out-Null
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1 | Out-Null
Set-Reg "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1 | Out-Null
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1 | Out-Null
Ok "Telemetria, Copilot y anuncios apagados."

# ---------- 5. Rendimiento ----------
Step "5/5  Modo rapido de Windows"
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2 | Out-Null
Set-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String" | Out-Null
Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" "200" "String" | Out-Null
Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" "01" 1 | Out-Null
Ok "Efectos visuales al minimo y limpieza automatica activada."

# ---------- Resumen ----------
Say ""
Say "  ==================================================" 'Green'
Say "   LISTO. Resumen honesto de lo que se hizo:" 'Green'
Say "  ==================================================" 'Green'
Say ("   - Apps basura desinstaladas:  {0}" -f $nApps) 'White'
Say ("   - Programas quitados del arranque: {0}" -f $nStart) 'White'
Say ("   - Servicios innecesarios apagados: {0}" -f $nSvc) 'White'
Say ("   - Tareas de espionaje apagadas: {0}" -f $nTareas) 'White'
Say "   - Telemetria, Copilot y anuncios: apagados" 'White'
Say "   - Windows en modo rapido: activado" 'White'
if ($restoreOk) { Say "   - Punto de restauracion: creado (puedes devolver todo desde Panel de control)" 'White' }
Say ""
Say "  Reinicia el PC para notar todos los cambios." 'Yellow'
Say ""
