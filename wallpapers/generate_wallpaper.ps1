; ============================================================
; OpenRUS - Cyberpunk Wallpaper Generator
; Creates a cyberpunk-style wallpaper using PowerShell + .NET
; ============================================================

Add-Type -AssemblyName System.Drawing

function New-CyberpunkWallpaper {
    param(
        [int]$Width = 1920,
        [int]$Height = 1080,
        [string]$OutputPath = "C:\OpenRUS\wallpapers\cyberpunk_bear.jpg"
    )
    
    # Ensure directory exists
    $dir = Split-Path $OutputPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    
    $bitmap = New-Object System.Drawing.Bitmap($Width, $Height)
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # === Background gradient (dark blue-black) ===
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point(0, 0)),
        (New-Object System.Drawing.Point($Width, $Height)),
        [System.Drawing.Color]::FromArgb(255, 5, 5, 20),
        [System.Drawing.Color]::FromArgb(255, 15, 0, 30)
    )
    $g.FillRectangle($bgBrush, 0, 0, $Width, $Height)
    
    # === Grid lines (cyberpunk grid) ===
    $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(30, 0, 255, 255), 1)
    
    # Vertical lines
    for ($x = 0; $x -lt $Width; $x += 80) {
        $g.DrawLine($gridPen, $x, 0, $x, $Height)
    }
    # Horizontal lines  
    for ($y = 0; $y -lt $Height; $y += 80) {
        $g.DrawLine($gridPen, 0, $y, $Width, $y)
    }
    
    # === Perspective grid (bottom) ===
    $perspPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 0, 200, 255), 1)
    $horizonY = $Height * 0.6
    $centerX = $Width / 2
    
    for ($i = -15; $i -le 15; $i++) {
        $startX = $centerX + ($i * 200)
        $g.DrawLine($perspPen, $startX, $horizonY, $centerX + ($i * 50), $Height)
    }
    for ($row = 0; $row -le 10; $row++) {
        $y = $horizonY + (($Height - $horizonY) * ($row / 10.0))
        $spread = ($y - $horizonY) / ($Height - $horizonY)
        $lineW = $Width * $spread
        $startX = $centerX - ($lineW / 2)
        $g.DrawLine($perspPen, $startX, $y, $startX + $lineW, $y)
    }
    
    # === Glow circles (abstract bear silhouette area) ===
    $bearCenterX = $Width / 2
    $bearCenterY = $Height * 0.4
    
    # Outer glow
    for ($r = 300; $r -ge 10; $r -= 20) {
        $alpha = [Math]::Max(0, [int](5 * (1 - $r / 300.0)))
        $glowBrush = New-Object System.Drawing.SolidBrush(
            [System.Drawing.Color]::FromArgb($alpha, 0, 255, 255)
        )
        $g.FillEllipse($glowBrush, 
            $bearCenterX - $r, 
            $bearCenterY - $r, 
            $r * 2, $r * 2)
        $glowBrush.Dispose()
    }
    
    # === Bear head (geometric) ===
    $cyanPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 0, 255, 255), 2)
    $purplePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 191, 0, 255), 2)
    $orangePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 255, 100, 0), 1)
    
    # Bear body outline (hexagonal/geometric)
    $headSize = 120
    $hx = $bearCenterX
    $hy = $bearCenterY
    
    # Main head hexagon
    $headPoints = @(
        [System.Drawing.Point]::new($hx, $hy - $headSize),           # top
        [System.Drawing.Point]::new($hx + $headSize * 0.87, $hy - $headSize * 0.5),  # top-right
        [System.Drawing.Point]::new($hx + $headSize * 0.87, $hy + $headSize * 0.5),  # bot-right
        [System.Drawing.Point]::new($hx, $hy + $headSize),           # bottom
        [System.Drawing.Point]::new($hx - $headSize * 0.87, $hy + $headSize * 0.5),  # bot-left
        [System.Drawing.Point]::new($hx - $headSize * 0.87, $hy - $headSize * 0.5)   # top-left
    )
    $g.DrawPolygon($cyanPen, $headPoints)
    
    # Ears
    $earL = @(
        [System.Drawing.Point]::new($hx - 70, $hy - $headSize + 20),
        [System.Drawing.Point]::new($hx - 110, $hy - $headSize - 40),
        [System.Drawing.Point]::new($hx - 130, $hy - $headSize + 10)
    )
    $g.DrawPolygon($cyanPen, $earL)
    
    $earR = @(
        [System.Drawing.Point]::new($hx + 70, $hy - $headSize + 20),
        [System.Drawing.Point]::new($hx + 110, $hy - $headSize - 40),
        [System.Drawing.Point]::new($hx + 130, $hy - $headSize + 10)
    )
    $g.DrawPolygon($cyanPen, $earR)
    
    # Eyes (glowing diamonds)
    $eyeSize = 20
    $eyeLX = $hx - 45
    $eyeRX = $hx + 45
    $eyeY = $hy - 10
    
    $eyeLPoints = @(
        [System.Drawing.Point]::new($eyeLX, $eyeY - $eyeSize),
        [System.Drawing.Point]::new($eyeLX + $eyeSize, $eyeY),
        [System.Drawing.Point]::new($eyeLX, $eyeY + $eyeSize),
        [System.Drawing.Point]::new($eyeLX - $eyeSize, $eyeY)
    )
    $eyeLBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 255, 255))
    $g.FillPolygon($eyeLBrush, $eyeLPoints)
    $g.DrawPolygon($purplePen, $eyeLPoints)
    
    $eyeRPoints = @(
        [System.Drawing.Point]::new($eyeRX, $eyeY - $eyeSize),
        [System.Drawing.Point]::new($eyeRX + $eyeSize, $eyeY),
        [System.Drawing.Point]::new($eyeRX, $eyeY + $eyeSize),
        [System.Drawing.Point]::new($eyeRX - $eyeSize, $eyeY)
    )
    $eyeRBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 191, 0, 255))
    $g.FillPolygon($eyeRBrush, $eyeRPoints)
    $g.DrawPolygon($cyanPen, $eyeRPoints)
    
    # Circuit lines emanating from bear
    $circuitLines = @(
        @($hx + 100, $hy - 50, $hx + 300, $hy - 50, $hx + 300, $hy - 150, $hx + 500, $hy - 150),
        @($hx - 100, $hy - 50, $hx - 300, $hy - 50, $hx - 300, $hy - 150, $hx - 500, $hy - 150),
        @($hx + 50, $hy + 100, $hx + 50, $hy + 200, $hx + 200, $hy + 200),
        @($hx - 50, $hy + 100, $hx - 50, $hy + 200, $hx - 200, $hy + 200)
    )
    
    foreach ($line in $circuitLines) {
        for ($i = 0; $i -lt $line.Count - 2; $i += 2) {
            $g.DrawLine($orangePen, $line[$i], $line[$i+1], $line[$i+2], $line[$i+3])
        }
    }
    
    # === OpenRUS text ===
    $font = New-Object System.Drawing.Font("Consolas", 48, [System.Drawing.FontStyle]::Bold)
    $smallFont = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Regular)
    
    # Glow effect for text (draw multiple times with transparency)
    for ($i = 5; $i -ge 1; $i--) {
        $glowAlpha = 30 * $i
        $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($glowAlpha, 0, 255, 255))
        $g.DrawString("OpenRUS", $font, $glowBrush, 
            ($Width/2 - 130 + $i), ($Height * 0.72 + $i))
        $g.DrawString("OpenRUS", $font, $glowBrush, 
            ($Width/2 - 130 - $i), ($Height * 0.72 - $i))
        $glowBrush.Dispose()
    }
    
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0, 255, 255))
    $g.DrawString("OpenRUS", $font, $textBrush, ($Width/2 - 130), ($Height * 0.72))
    
    $subtextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 191, 0, 255))
    $g.DrawString("CYBERPUNK EDITION  //  v1.0", $smallFont, $subtextBrush, ($Width/2 - 140), ($Height * 0.72 + 60))
    
    # === Scan lines effect ===
    $scanPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(8, 0, 0, 0), 1)
    for ($y = 0; $y -lt $Height; $y += 4) {
        $g.DrawLine($scanPen, 0, $y, $Width, $y)
    }
    
    # Save
    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $g.Dispose()
    $bitmap.Dispose()
    
    Write-Host "[OK] Обои сохранены: $OutputPath"
}

# Generate wallpaper
New-CyberpunkWallpaper -OutputPath "C:\OpenRUS\wallpapers\cyberpunk_bear.jpg"
New-CyberpunkWallpaper -Width 1366 -Height 768 -OutputPath "C:\OpenRUS\wallpapers\cyberpunk_bear_1366.jpg"
New-CyberpunkWallpaper -Width 3840 -Height 2160 -OutputPath "C:\OpenRUS\wallpapers\cyberpunk_bear_4k.jpg"

Write-Host ""
Write-Host "[OK] Все обои OpenRUS созданы!"
Write-Host "Применяем обои..."

# Apply wallpaper
$regKey = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $regKey -Name "Wallpaper" -Value "C:\OpenRUS\wallpapers\cyberpunk_bear.jpg"
Set-ItemProperty -Path $regKey -Name "WallpaperStyle" -Value "10"  # Fill
Set-ItemProperty -Path $regKey -Name "TileWallpaper" -Value "0"

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
[Wallpaper]::SystemParametersInfo(20, 0, "C:\OpenRUS\wallpapers\cyberpunk_bear.jpg", 3)

Write-Host "[OK] Обои применены!"
