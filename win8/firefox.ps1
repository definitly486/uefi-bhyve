
Remove-Item -Path "D:\app\firefox-151.0.2.en-US.win32.installer\core\profile" -Recurse -Force -ErrorAction SilentlyContinue

7z x "D:\profile.tar.xz" -aoa;7z x "D:\profile.tar" -aoa
Copy-Item -Path "D:\profile" -Destination "D:\app\firefox-151.0.2.en-US.win32.installer\core\profile" -Recurse -Force

