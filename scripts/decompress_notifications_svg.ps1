Add-Type -AssemblyName System.IO.Compression
$inPath = 'C:\Users\AN\gornaya-salanga\mobile\assets\icons\notifications.svgz'
$outPath = 'C:\Users\AN\gornaya-salanga\mobile\assets\icons\notifications.svg'
$input = [System.IO.File]::OpenRead($inPath)
$gzip = New-Object System.IO.Compression.GZipStream($input, [System.IO.Compression.CompressionMode]::Decompress)
$reader = New-Object System.IO.StreamReader($gzip)
$text = $reader.ReadToEnd()
$reader.Close()
$gzip.Close()
$input.Close()
[System.IO.File]::WriteAllText($outPath, $text)
Write-Host "Wrote $outPath ($($text.Length) chars)"
