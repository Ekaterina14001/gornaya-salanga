$src = 'C:\Users\AN\.cursor\projects\c-Users-AN-gornaya-salanga\assets'
$dstIcons = 'C:\Users\AN\gornaya-salanga\mobile\assets\icons'
$dstBanners = 'C:\Users\AN\gornaya-salanga\mobile\assets\banners'
New-Item -ItemType Directory -Force -Path $dstIcons, $dstBanners | Out-Null

function Copy-ByPattern($pattern, $destName, $destDir) {
  $f = Get-ChildItem $src -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $pattern } | Select-Object -First 1
  if ($f) {
    Copy-Item $f.FullName (Join-Path $destDir $destName) -Force
    Write-Host "OK $destName"
  } else {
    Write-Host "MISSING $pattern"
  }
}

Copy-ByPattern '*Dom-*' 'home.png' $dstIcons
Copy-ByPattern '*Bonusi_2-*' 'bonus_active.png' $dstIcons
Copy-ByPattern '*Bonusi-83*' 'bonus.png' $dstIcons
Copy-ByPattern '*Katalog-*' 'catalog.png' $dstIcons
Copy-ByPattern '*Bronirovanie-*' 'book_room.png' $dstIcons
Copy-ByPattern '*Pogoda-*' 'weather.png' $dstIcons
Copy-ByPattern '*Obratnaya_svyazy-*' 'contact.png' $dstIcons
Copy-ByPattern '*Lichniy_kabinet-*' 'profile.png' $dstIcons
Copy-ByPattern '*Logo_GS-*' 'logo_gs.png' $dstIcons
Copy-ByPattern '*Videonabludenie-*' 'webcams.png' $dstIcons
Copy-ByPattern '*Trassi-*' 'trails.png' $dstIcons
Copy-ByPattern '*Strelka-*' 'chevron.png' $dstIcons
Copy-ByPattern '*qr-code-*' 'qr.png' $dstIcons
Copy-ByPattern '*Vetka-*' 'branch.png' $dstIcons
Copy-ByPattern '*9208_x-*' 'banner_welcome.jpg' $dstBanners
Copy-ByPattern '*9207_x-*' 'banner_chalet.jpg' $dstBanners

$notif = 'C:\Users\AN\Downloads\Uvedomleniya.svgz'
if (Test-Path $notif) {
  Copy-Item $notif (Join-Path $dstIcons 'notifications.svgz') -Force
  Write-Host 'OK notifications.svgz'
} else {
  Write-Host 'MISSING Uvedomleniya.svgz'
}

Get-ChildItem $dstIcons, $dstBanners | Format-Table Name, Length
