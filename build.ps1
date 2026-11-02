# Builds BluetoothShortcut.apk with plain SDK build-tools (no Gradle).
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$java = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot'
$env:JAVA_HOME = $java
$env:Path      = "$java\bin;$env:Path"
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$bt  = "$sdk\build-tools\34.0.0"
$jar = "$sdk\platforms\android-34\android.jar"
$out = Join-Path $root 'out'

Remove-Item -Recurse -Force $out -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "$out\classes", "$out\dex" | Out-Null

Write-Host '==> javac'
& "$java\bin\javac.exe" -Xlint:-options -source 1.8 -target 1.8 -bootclasspath $jar `
    -d "$out\classes" (Get-ChildItem "$root\src" -Recurse -Filter *.java).FullName
if ($LASTEXITCODE) { throw 'javac failed' }

Write-Host '==> d8'
& "$bt\d8.bat" --release --min-api 21 --lib $jar --output "$out\dex" `
    (Get-ChildItem "$out\classes" -Recurse -Filter *.class).FullName
if ($LASTEXITCODE) { throw 'd8 failed' }

Write-Host '==> app art (icon + banner)'
& "$PSScriptRoot\make_art.ps1" 2>&1 | Out-Null
if ($LASTEXITCODE) { throw 'make_art failed' }
if (!(Test-Path "$root\res\mipmap-xxxhdpi\ic_launcher.png")) { throw 'icon not generated' }

Write-Host '==> aapt2 compile'
& "$bt\aapt2.exe" compile --dir "$root\res" -o "$out\res.zip"
if ($LASTEXITCODE) { throw 'aapt2 compile failed' }

Write-Host '==> aapt2 link'
& "$bt\aapt2.exe" link --manifest "$root\AndroidManifest.xml" -I $jar `
    -o "$out\unsigned.apk" "$out\res.zip" --auto-add-overlay
if ($LASTEXITCODE) { throw 'aapt2 failed' }

Write-Host '==> add classes.dex to apk'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open("$out\unsigned.apk", 'Update')
[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, "$out\dex\classes.dex", 'classes.dex') | Out-Null
$zip.Dispose()

Write-Host '==> zipalign'
& "$bt\zipalign.exe" -f 4 "$out\unsigned.apk" "$out\aligned.apk"
if ($LASTEXITCODE) { throw 'zipalign failed' }

Write-Host '==> apksigner (debug key)'
$ks = "$env:USERPROFILE\.android\debug.keystore"
if (!(Test-Path $ks)) {
    New-Item -ItemType Directory -Force "$env:USERPROFILE\.android" | Out-Null
    & "$java\bin\keytool.exe" -genkeypair -keystore $ks -storepass android -keypass android `
        -alias androiddebugkey -dname 'CN=Android Debug,O=Android,C=US' -keyalg RSA -keysize 2048 -validity 10000
    if ($LASTEXITCODE) { throw 'keytool failed' }
}
& "$bt\apksigner.bat" sign --ks $ks --ks-pass pass:android --key-pass pass:android `
    --out "$root\BluetoothShortcut.apk" "$out\aligned.apk"
if ($LASTEXITCODE) { throw 'apksigner failed' }

& "$bt\apksigner.bat" verify "$root\BluetoothShortcut.apk"
Write-Host "==> OK: $root\BluetoothShortcut.apk"
