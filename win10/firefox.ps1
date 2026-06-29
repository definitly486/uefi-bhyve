#Set-Location $env:TEMP

#if (-not (Test-Path "$env:TEMP\firefox.tar.xz.enc")) {
#    Invoke-WebRequest `
#        -Uri "https://github.com/definitly486/definitly486/releases/download/firefox.enc/firefox.tar.xz.enc" `
#       -OutFile "firefox.tar.xz.enc"
#}

#openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -d `
#    -in "firefox.tar.xz.enc" `
#   -out "firefox.tar.xz"

#7z x "firefox.tar.xz" -aoa; 7z x "firefox.tar" -aoa; Remove-Item "firefox.tar"
#Copy-Item -Path "C:\Users\vcore\AppData\Local\Temp\firefox\lhmub5xq.default-release-1" -Destination "C:\app\Firefox Setup 152.0.2\core\profile" -Recurse -Force
7z x "C:\app\profile.tar.xz" -aoa;7z x "C:\app\profile.tar" -aoa
Copy-Item -Path "C:\app\profile" -Destination "C:\app\Firefox Setup 152.0.2\core\profile" -Recurse -Force

