# Draws the app icon (all mipmap densities) and the leanback banner
# using System.Drawing. Output goes to .\res so build.ps1 can aapt2-compile it.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = $PSScriptRoot
$res  = Join-Path $root 'res'
Remove-Item -Recurse -Force $res -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force `
  "$res\mipmap-mdpi","$res\mipmap-hdpi","$res\mipmap-xhdpi","$res\mipmap-xxhdpi","$res\mipmap-xxxhdpi",
  "$res\drawable-nodpi", "$root\art" | Out-Null

function Rounded-Path([float]$x,[float]$y,[float]$w,[float]$h,[float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x,        $y,        $d, $d, 180, 90)
    $p.AddArc($x + $w-$d, $y,        $d, $d, 270, 90)
    $p.AddArc($x + $w-$d, $y + $h-$d, $d, $d, 0,   90)
    $p.AddArc($x,        $y + $h-$d, $d, $d, 90,  90)
    $p.CloseFigure()
    $p
}

# Bluetooth rune polyline, unit coords from the official glyph geometry
function Glyph-Points([float]$cx,[float]$cy,[float]$s) {
    $uv = @(@(0.25,0.2917), @(0.75,0.7083), @(0.5,0.9167), @(0.5,0.0833), @(0.75,0.2917), @(0.25,0.7083))
    $uv | ForEach-Object {
        New-Object System.Drawing.PointF ([float]($cx + ($_[0] - 0.5) * $s), [float]($cy + ($_[1] - 0.5) * $s))
    }
}

function Draw-Glyph([System.Drawing.Graphics]$g, [float]$cx, [float]$cy, [float]$s) {
    $pts = @(Glyph-Points $cx $cy $s)
    $g.SmoothingMode = 'AntiAlias'
    # soft glow passes, then solid stroke
    foreach ($spec in @(@(2.6, 28), @(1.7, 60), @(1.0, 255))) {
        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb($spec[1], 255, 255, 255)), ([float]($s * 0.07 * $spec[0]))
        $pen.StartCap = 'Round'; $pen.EndCap = 'Round'; $pen.LineJoin = 'Round'
        $g.DrawLines($pen, $pts)
        $pen.Dispose()
    }
}

function New-Bitmap([int]$W,[int]$H) {
    $bmp = New-Object System.Drawing.Bitmap $W, $H
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.InterpolationMode = 'HighQualityBicubic'
    return @($bmp, $g)
}

# ---------- app icon ----------
function Make-Icon([int]$size) {
    $bmp, $g = New-Bitmap $size $size
    $r = [float]($size * 0.22)
    $path = Rounded-Path 0 0 $size $size $r
    $brush = New-Object System.Drawing.Drawing2D.PathGradientBrush($path)
    $brush.CenterColor    = [System.Drawing.Color]::FromArgb(255, 33, 99, 187)  # #2163BB
    $brush.SurroundColors = [System.Drawing.Color[]]@([System.Drawing.Color]::FromArgb(255, 6, 21, 45))
    $brush.CenterPoint    = New-Object System.Drawing.PointF ([float]($size/2)), ([float]($size*0.42))
    $g.FillRectangle([System.Drawing.Brushes]::Transparent, 0, 0, $size, $size)
    $g.FillPath($brush, $path)
    # faint ring for polish
    $ring = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(35, 255, 255, 255)), ([float][Math]::Max(1, $size*0.008))
    $g.DrawArc($ring, [float]$r, [float]$r, [float]($size-2*$r), [float]($size-2*$r), -90, 360)
    Draw-Glyph $g ([float]($size/2)) ([float]($size/2)) ([float]($size*0.58))
    return @($bmp, $g, $path, $brush, $ring)
}

foreach ($d in @(@('mdpi',48), @('hdpi',72), @('xhdpi',96), @('xxhdpi',144), @('xxxhdpi',192))) {
    $bmp, $g, $path, $brush, $ring = Make-Icon $d[1]
    $g.Dispose()
    $bmp.Save("$res\mipmap-$($d[0])\ic_launcher.png", [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose(); $path.Dispose(); $brush.Dispose(); $ring.Dispose()
}
# big preview for review
$bmp, $g, $path, $brush, $ring = Make-Icon 512
$g.Dispose()
$bmp.Save("$root\art\icon_512.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose(); $path.Dispose(); $brush.Dispose(); $ring.Dispose()

# ---------- leanback banner 720x405 ----------
$W = 720; $H = 405
$bmp, $g = New-Bitmap $W $H
$lg = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
    (New-Object System.Drawing.Rectangle 0,0,$W,$H),
    ([System.Drawing.Color]::FromArgb(255, 6, 21, 45)),
    ([System.Drawing.Color]::FromArgb(255, 33, 99, 187)),
    25.0)
$g.FillRectangle($lg, 0, 0, $W, $H)
# diagonal light streak
$st = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
    (New-Object System.Drawing.Rectangle 0,0,$W,$H),
    ([System.Drawing.Color]::FromArgb(0, 255,255,255)),
    ([System.Drawing.Color]::FromArgb(22, 255,255,255)),
    35.0)
$g.FillRectangle($st, 0, 0, $W, $H)
Draw-Glyph $g ([float]($W*0.72)) ([float]($H/2)) ([float]($H*0.62))
$g.Dispose()
$bmp.Save("$res\drawable-nodpi\tv_banner.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose(); $lg.Dispose(); $st.Dispose()

# banner preview copy
Copy-Item "$res\drawable-nodpi\tv_banner.png" "$root\art\banner_preview.png" -Force
Write-Host "art generated"
