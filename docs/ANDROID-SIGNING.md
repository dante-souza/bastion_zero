# Android CI signing — preserving local saves

Debug APKs built by GitHub Actions require a stable keystore to permit `adb install -r` updates without uninstalling and deleting saved progress.

## Current security model

The workflow accepts an optional repository Actions **secret** named `BASTION_DEBUG_KEYSTORE_BASE64`. It must contain the Base64 text of a dedicated Android **debug-only** keystore with alias `androiddebugkey`, keystore password `android` and key password `android`. When the secret is absent, a temporary keystore is generated and the CI run logs a warning. Do not use this debug keystore for production signing. Do not commit the keystore or its Base64 representation to git.

### Generate a dedicated local keystore in PowerShell

```powershell
keytool -genkeypair -noprompt -keystore .\bastion-m1r-debug.keystore `
  -storepass android -alias androiddebugkey -keypass android `
  -keyalg RSA -keysize 3072 -validity 10000 `
  -dname "CN=Bastion Zero CI Debug,O=Bastion Zero,C=BR"

[Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path .\bastion-m1r-debug.keystore))) |
  Set-Content -NoNewline .\bastion-m1r-debug.keystore.base64.txt
```

Store `bastion-m1r-debug.keystore` securely outside the repository. In the repo open **Settings → Secrets and variables → Actions → New repository secret** and paste the contents of the Base64 text file under the name `BASTION_DEBUG_KEYSTORE_BASE64`. Delete the temporary .base64.txt text file afterward.

After setup, the next CI APK will be signed with the stable debug key. One final uninstall may be required to replace APKs signed with the previous temporary key; afterward ordinary `adb install -r` should work.

The production Play Store app must use a separately protected release/upload signing identity and AAB that includes ARM64.
