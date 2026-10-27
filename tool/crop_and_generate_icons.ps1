Add-Type -AssemblyName System.Drawing

$srcPath = "C:\Users\kshat\.gemini\antigravity-ide\brain\4fd57e7a-8c98-4dc6-a28c-ada9d9131f28\g1care_app_icon_1787384968524.jpg"
$bmp = New-Object System.Drawing.Bitmap($srcPath)

# 1. Find bounding box of the medical symbol (excluding outer white background)
$minX = $bmp.Width
$maxX = 0
$minY = $bmp.Height
$maxY = 0

for ($y = 0; $y -lt $bmp.Height; $y += 2) {
    for ($x = 0; $x -lt $bmp.Width; $x += 2) {
        $c = $bmp.GetPixel($x, $y)
        # Non-white pixels
        if (($c.R + $c.G + $c.B) -lt 720) {
            if ($x -lt $minX) { $minX = $x }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}

$emblemW = $maxX - $minX
$emblemH = $maxY - $minY
Write-Host "Detected Symbol Bounds: Left=$minX, Top=$minY, Width=$emblemW, Height=$emblemH"

# Crop tightly to the symbol
$symbolCropRect = New-Object System.Drawing.Rectangle($minX, $minY, $emblemW, $emblemH)
$symbolBmp = $bmp.Clone($symbolCropRect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

# Function to render symbol centered on a clean white background square canvas
function Save-AppIconWithWhiteBackground($sourceSymbol, $targetPath, $targetSize) {
    $destBmp = New-Object System.Drawing.Bitmap($targetSize, $targetSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($destBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    
    # Fill clean white background
    $g.Clear([System.Drawing.Color]::White)
    
    # Calculate scale so symbol occupies ~88% of icon canvas (standard Android icon safe zone)
    $paddingRatio = 0.06
    $innerSize = [int]($targetSize * (1.0 - 2 * $paddingRatio))
    $scale = [Math]::Min($innerSize / $sourceSymbol.Width, $innerSize / $sourceSymbol.Height)
    
    $drawW = [int]($sourceSymbol.Width * $scale)
    $drawH = [int]($sourceSymbol.Height * $scale)
    $drawX = [int](($targetSize - $drawW) / 2)
    $drawY = [int](($targetSize - $drawH) / 2)
    
    $destRect = New-Object System.Drawing.Rectangle($drawX, $drawY, $drawW, $drawH)
    $g.DrawImage($sourceSymbol, $destRect, 0, 0, $sourceSymbol.Width, $sourceSymbol.Height, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    
    $dir = [System.IO.Path]::GetDirectoryName($targetPath)
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    
    $destBmp.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destBmp.Dispose()
    Write-Host "Generated App Icon: $targetPath ($targetSize x $targetSize)"
}

# Function to generate notification icon (crisp symbol on clean background)
function Save-NotificationIcon($sourceSymbol, $targetPath, $targetSize) {
    $destBmp = New-Object System.Drawing.Bitmap($targetSize, $targetSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($destBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    
    $innerSize = [int]($targetSize * 0.90)
    $scale = [Math]::Min($innerSize / $sourceSymbol.Width, $innerSize / $sourceSymbol.Height)
    $drawW = [int]($sourceSymbol.Width * $scale)
    $drawH = [int]($sourceSymbol.Height * $scale)
    $drawX = [int](($targetSize - $drawW) / 2)
    $drawY = [int](($targetSize - $drawH) / 2)
    
    $destRect = New-Object System.Drawing.Rectangle($drawX, $drawY, $drawW, $drawH)
    $g.DrawImage($sourceSymbol, $destRect, 0, 0, $sourceSymbol.Width, $sourceSymbol.Height, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    
    $dir = [System.IO.Path]::GetDirectoryName($targetPath)
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    
    $destBmp.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destBmp.Dispose()
    Write-Host "Generated Notification Icon: $targetPath ($targetSize x $targetSize)"
}

# 1. Update App Logo and Android Launcher mipmaps with clean white background and centered medical symbol
Save-AppIconWithWhiteBackground $symbolBmp "assets/images/logo.png" 512
Save-AppIconWithWhiteBackground $symbolBmp "android/app/src/main/res/mipmap-mdpi/ic_launcher.png" 48
Save-AppIconWithWhiteBackground $symbolBmp "android/app/src/main/res/mipmap-hdpi/ic_launcher.png" 72
Save-AppIconWithWhiteBackground $symbolBmp "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png" 96
Save-AppIconWithWhiteBackground $symbolBmp "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png" 144
Save-AppIconWithWhiteBackground $symbolBmp "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" 192

# 2. Update Android Notification Drawable resources
Save-NotificationIcon $symbolBmp "android/app/src/main/res/drawable/ic_stat_g1care.png" 96
Save-NotificationIcon $symbolBmp "android/app/src/main/res/drawable-mdpi/ic_stat_g1care.png" 24
Save-NotificationIcon $symbolBmp "android/app/src/main/res/drawable-hdpi/ic_stat_g1care.png" 36
Save-NotificationIcon $symbolBmp "android/app/src/main/res/drawable-xhdpi/ic_stat_g1care.png" 48
Save-NotificationIcon $symbolBmp "android/app/src/main/res/drawable-xxhdpi/ic_stat_g1care.png" 72
Save-NotificationIcon $symbolBmp "android/app/src/main/res/drawable-xxxhdpi/ic_stat_g1care.png" 96

$symbolBmp.Dispose()
$bmp.Dispose()
Write-Host "All G1Care App Icons and Notification Icons generated successfully!"
