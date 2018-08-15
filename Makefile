VERSION=`cut -d '"' -f2 $BUILDDIR/../version.js`
GREEN=\033[0;32m
CLOSECOLOR=\033[0m

ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

UNAME := $(shell uname)

ifeq ($(UNAME), Linux)
  SHELLCMD := bash
endif

ifeq ($(UNAME), Darwin)
  SHELLCMD := sh
endif

prepare-dev:
	$(SHELLCMD) devbuilds/prepare-dev.sh live

prepare-dev-tn:
	$(SHELLCMD) devbuilds/prepare-dev.sh testnet
	@echo "$(GREEN)Generating testnet configuration...$(CLOSECOLOR)"
	$(SHELLCMD) devbuilds/testnetify.sh
	@echo "$(GREEN)Done. You can start wallet now. $(CLOSECOLOR)"

prepare-package:
	$(SHELLCMD) devbuilds/prepare-package.sh live

prepare-package-tn:
	$(SHELLCMD) devbuilds/prepare-package.sh testnet

# prepares .deb package for live
prepare-package-deb:
	$(SHELLCMD) devbuilds/prepare-package-deb.sh live

# prepares .deb package for testnet
prepare-package-deb-tn:
	$(SHELLCMD) devbuilds/prepare-package-deb.sh testnet

ios-prod:
	cordova/build.sh IOS dagcoin --clear live
	cd ../byteballbuilds/project-IOS && cordova build ios

ios-debug:
	cordova/build.sh IOS dagcoin --dbgjs testnet
	cd ../byteballbuilds/project-IOS  && cordova build ios
	open ../byteballbuilds/project-IOS/platforms/ios/Dagcoin.xcodeproj

android-prod:
	cordova/build.sh ANDROID dagcoin-wallet --clear live
	cd ../byteballbuilds/project-ANDROID  && cordova build --release android
#   keytool -genkey -v -keystore <keystore_name>.keystore -alias <keystore alias> -keyalg RSA -keysize 2048 -validity 10000
	jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore dagcoin.jks -tsa http://sha256timestamp.ws.symantec.com/sha256/timestamp -signedjar ../byteballbuilds/project-ANDROID/platforms/android/build/outputs/apk/android-release-signed.apk  ../byteballbuilds/project-ANDROID/platforms/android/build/outputs/apk/android-release-unsigned.apk dagcoin
	$(ANDROID_HOME)/build-tools/25.0.3/zipalign -v 4 ../byteballbuilds/project-ANDROID/platforms/android/build/outputs/apk/android-release-signed.apk ../byteballbuilds/project-ANDROID/platforms/android/build/outputs/apk/android-release-signed-aligned.apk

android-prod-tn:
	cordova/build.sh ANDROID dagcoin-wallet --clear testnet
	cd ../byteballbuilds/project-ANDROID  && cordova build --release android
	jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore dagcoin.jks -tsa http://sha256timestamp.ws.symantec.com/sha256/timestamp -signedjar ../byteballbuilds/project-ANDROID/platforms/android/build/outputs/apk/android-release-signed.apk  ../byteballbuilds/project-ANDROID/platforms/android/build/outputs/apk/android-release-unsigned.apk dagcoin
	$(ANDROID_HOME)/build-tools/25.0.3/zipalign -v 4 ../byteballbuilds/project-ANDROID/platforms/android/build/outputs/apk/android-release-signed.apk ../byteballbuilds/project-ANDROID/platforms/android/build/outputs/apk/android-release-signed-aligned.apk

android-debug-fast:
	cordova/build.sh ANDROID dagcoin-wallet --clear live
#	cp ./etc/beep.ogg ./cordova/project/plugins/phonegap-plugin-barcodescanner/src/android/LibraryProject/res/raw/beep.ogg
	cd ../byteballbuilds/project-ANDROID && cordova run android --device
#	cd ../byteballbuilds/project-ANDROID && cordova build android

android-package-tn:
	cordova/build.sh ANDROID dagcoin-wallet-tn --dbgjs testnet

android-debug-fast-tn:
	cordova/build.sh ANDROID dagcoin-wallet-tn --dbgjs testnet
	cd ./cordova/project-ANDROID && cordova run android --device
#	cd ../byteballbuilds/project-ANDROID && cordova build android

android-debug-fast-emulator-tn:
	cordova/build.sh ANDROID dagcoin-wallet-tn --dbgjs testnet
	cd ../byteballbuilds/project-ANDROID && cordova emulate android

docker-image-ubuntu:
	docker build -t pillow/ubuntutools -f devbuilds/ubuntu.dockerfile devbuilds/

docker-image-android:
	docker build -t pillow/androidtools -f devbuilds/android.dockerfile devbuilds/

ubuntu-%:
	docker run -it --volume=$(ROOT_DIR):/root/wallet --workdir="/root/wallet" --memory=8g --memory-swap=8g --memory-swappiness=0 --entrypoint=/bin/bash -v ~/.ssh:/root/.ssh -e CI=true pillow/ubuntutools -c make $(subst ubuntu-,,$@)

docker-%:
	docker run -it --volume=$(ROOT_DIR):/root/wallet --workdir="/root/wallet" --memory=8g --memory-swap=8g --memory-swappiness=0 --entrypoint=/bin/bash -v ~/.ssh:/root/.ssh -e CI=true pillow/androidtools -c make $(subst docker-,,$@)
