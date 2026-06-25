Set-Location $env:TEMP

if (-not (Test-Path "$env:TEMP\firefox.tar.xz.enc")) {
    Invoke-WebRequest `
        -Uri "https://github.com/definitly486/definitly486/releases/download/firefox.enc/firefox.tar.xz.enc" `
        -OutFile "firefox.tar.xz.enc"
}

openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -d `
    -in "firefox.tar.xz.enc" `
    -out "firefox.tar.xz"

tar -xJf "firefox.tar.xz"