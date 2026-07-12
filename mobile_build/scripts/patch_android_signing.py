#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit('usage: patch_android_signing.py <app-dir>')
app=Path(sys.argv[1])
kts=app/'android/app/build.gradle.kts'
groovy=app/'android/app/build.gradle'
if kts.exists():
    s=kts.read_text()
    marker='// ASTRIDE_RELEASE_SIGNING'
    if marker not in s:
        header='''import java.util.Properties\nimport java.io.FileInputStream\n\nval astrideKeyProperties = Properties()\nval astrideKeyPropertiesFile = rootProject.file("key.properties")\nif (astrideKeyPropertiesFile.exists()) {\n    astrideKeyProperties.load(FileInputStream(astrideKeyPropertiesFile))\n}\n// ASTRIDE_RELEASE_SIGNING\n'''
        s=header+s
        needle='    buildTypes {'
        block='''    signingConfigs {\n        create("release") {\n            if (astrideKeyPropertiesFile.exists()) {\n                keyAlias = astrideKeyProperties["keyAlias"] as String\n                keyPassword = astrideKeyProperties["keyPassword"] as String\n                storeFile = file(astrideKeyProperties["storeFile"] as String)\n                storePassword = astrideKeyProperties["storePassword"] as String\n            }\n        }\n    }\n\n'''
        if needle not in s: raise SystemExit('Unable to find buildTypes in build.gradle.kts')
        s=s.replace(needle, block+needle, 1)
        s=s.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("release")')
        kts.write_text(s)
elif groovy.exists():
    s=groovy.read_text()
    marker='// ASTRIDE_RELEASE_SIGNING'
    if marker not in s:
        header='''def astrideKeyProperties = new Properties()\ndef astrideKeyPropertiesFile = rootProject.file('key.properties')\nif (astrideKeyPropertiesFile.exists()) { astrideKeyProperties.load(new FileInputStream(astrideKeyPropertiesFile)) }\n// ASTRIDE_RELEASE_SIGNING\n'''
        s=header+s
        needle='    buildTypes {'
        block='''    signingConfigs {\n        release {\n            if (astrideKeyPropertiesFile.exists()) {\n                keyAlias astrideKeyProperties['keyAlias']\n                keyPassword astrideKeyProperties['keyPassword']\n                storeFile file(astrideKeyProperties['storeFile'])\n                storePassword astrideKeyProperties['storePassword']\n            }\n        }\n    }\n\n'''
        if needle not in s: raise SystemExit('Unable to find buildTypes in build.gradle')
        s=s.replace(needle, block+needle, 1)
        s=s.replace('signingConfig signingConfigs.debug', 'signingConfig signingConfigs.release')
        groovy.write_text(s)
else:
    raise SystemExit('Android Gradle app file not found; bootstrap first')
print(f'Android release signing patched for {app}')
