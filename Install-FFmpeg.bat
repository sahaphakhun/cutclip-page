@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText('%~f0',[Text.Encoding]::UTF8);$m='#'+'CUTAI_PS1';$i=$s.LastIndexOf($m);$p=Join-Path $env:TEMP 'CutAI-install.ps1';[IO.File]::WriteAllText($p,$s.Substring($i+$m.Length),(New-Object Text.UTF8Encoding $true));& $p"
echo.
pause
exit /b
#CUTAI_PS1
# ติดตั้ง ffmpeg ให้โปรแกรมตัดคลิป AI (Windows) — ดับเบิลคลิก Install-FFmpeg.bat ไฟล์เดียวจบ
# 1) มี ffmpeg ใช้งานได้อยู่แล้ว → บอกแล้วจบ  2) winget (Gyan.FFmpeg รุ่น full)  3) ไม่มี winget/ล้ม → โหลด zip จาก gyan.dev ลง C:\ffmpeg\bin
# ทดสอบ: $env:CUTAI_FF_FORCE_ZIP=1 (ข้าม winget) · $env:CUTAI_FF_DEST=<โฟลเดอร์> (ลงที่อื่นแทน C:\ffmpeg\bin) · $env:CUTAI_FF_ZIP_URL
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }
$Dest = "C:\ffmpeg\bin"
if ($env:CUTAI_FF_DEST) { $Dest = $env:CUTAI_FF_DEST }
$ZipUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
if ($env:CUTAI_FF_ZIP_URL) { $ZipUrl = $env:CUTAI_FF_ZIP_URL }

function Say($m)  { Write-Host "`n== $m ==" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [!]  $m" -ForegroundColor Yellow }

# ที่ที่โปรแกรมตัดคลิป AI ค้นหา ffmpeg (ตรงกับ plat.py _extra_dirs)
function Find-FF {
    $dirs = @($Dest, "C:\ffmpeg\bin", (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"), (Join-Path $env:ProgramFiles "WinGet\Links"))
    foreach ($root in @((Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"), (Join-Path $env:ProgramFiles "WinGet\Packages"))) {
        if (Test-Path -LiteralPath $root) {
            $dirs += @(Get-ChildItem -LiteralPath $root -Directory -Filter "Gyan.FFmpeg*" -ErrorAction SilentlyContinue |
                ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName "bin" } })
        }
    }
    foreach ($d in $dirs) {
        $p = Join-Path $d "ffmpeg.exe"
        if (Test-Path -LiteralPath $p) {
            try { $v = (& $p -hide_banner -version 2>$null | Select-Object -First 1); if ($v) { return @{ Path = $p; Version = "$v" } } } catch { }
        }
    }
    $c = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($c) { try { $v = (& $c.Source -hide_banner -version 2>$null | Select-Object -First 1); if ($v) { return @{ Path = $c.Source; Version = "$v" } } } catch { } }
    return $null
}

Write-Host ""
Write-Host "ติดตั้งเครื่องมือตัดวิดีโอ (ffmpeg) ให้โปรแกรมตัดคลิป AI" -ForegroundColor Cyan
Write-Host "ใช้เวลาประมาณ 1-5 นาที อย่าปิดหน้าต่างนี้จนกว่าจะขึ้นว่าเสร็จแล้ว"

if (-not $env:CUTAI_FF_FORCE_ZIP) {
    Say "1/3 ตรวจว่ามี ffmpeg อยู่แล้วหรือไม่"
    $f = Find-FF
    if ($f) {
        Ok "มี ffmpeg ใช้งานได้อยู่แล้ว: $($f.Path)"
        Write-Host "  $($f.Version)"
        Write-Host "`nถ้าโปรแกรมยังขึ้นว่าหา ffmpeg ไม่เจอ ให้ปิดโปรแกรมตัดคลิป AI แล้วเปิดใหม่อีกครั้ง" -ForegroundColor Green
        return
    }
    Warn "ยังไม่พบ ffmpeg ในเครื่อง"

    Say "2/3 ติดตั้งผ่าน winget"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            & winget install --id Gyan.FFmpeg -e --silent --accept-package-agreements --accept-source-agreements
        } catch { Warn "winget ล้ม: $($_.Exception.Message)" }
        $f = Find-FF
        if ($f) {
            Ok "ติดตั้งสำเร็จ: $($f.Path)"
            Write-Host "  $($f.Version)"
            Write-Host "`nเสร็จแล้ว! ปิดโปรแกรมตัดคลิป AI แล้วเปิดใหม่อีกครั้ง" -ForegroundColor Green
            return
        }
        Warn "winget ติดตั้งแล้วแต่ยังไม่พบไฟล์ — จะโหลดแบบ zip แทน"
    } else {
        Warn "เครื่องนี้ไม่มี winget — จะโหลดแบบ zip แทน"
    }
}

Say "3/3 โหลด zip จาก gyan.dev แล้วแตกไฟล์"
$tmp = Join-Path $env:TEMP ("cutai_ffmpeg_" + (Get-Date -Format "HHmmss"))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    $zip = Join-Path $tmp "ffmpeg.zip"
    Write-Host "  กำลังโหลด (ประมาณ 80 MB) ..."
    Invoke-WebRequest -Uri $ZipUrl -OutFile $zip -UseBasicParsing
    Write-Host "  กำลังแตกไฟล์ ..."
    Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $tmp "x") -Force
    $exe = Get-ChildItem -LiteralPath (Join-Path $tmp "x") -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
    $probe = Get-ChildItem -LiteralPath (Join-Path $tmp "x") -Recurse -Filter "ffprobe.exe" | Select-Object -First 1
    if (-not $exe -or -not $probe) { throw "ในไฟล์ zip ไม่มี ffmpeg.exe / ffprobe.exe" }
    New-Item -ItemType Directory -Force -Path $Dest | Out-Null
    Copy-Item -LiteralPath $exe.FullName -Destination (Join-Path $Dest "ffmpeg.exe") -Force
    Copy-Item -LiteralPath $probe.FullName -Destination (Join-Path $Dest "ffprobe.exe") -Force
    $f = Find-FF
    if (-not $f) { throw "คัดลอกแล้วแต่เปิด ffmpeg ไม่ได้" }
    Ok "ติดตั้งสำเร็จ: $($f.Path)"
    Write-Host "  $($f.Version)"
    Write-Host "`nเสร็จแล้ว! ปิดโปรแกรมตัดคลิป AI แล้วเปิดใหม่อีกครั้ง" -ForegroundColor Green
} catch {
    Write-Host "`n[X] ติดตั้งไม่สำเร็จ: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  - เช็คว่าต่ออินเทอร์เน็ตอยู่ และปิด VPN/แอนตี้ไวรัสชั่วคราว แล้วดับเบิลคลิกไฟล์นี้ใหม่"
    Write-Host "  - ถ้ายังไม่ได้ ถ่ายภาพหน้าจอนี้ส่งให้ทีมงานทางไลน์"
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
