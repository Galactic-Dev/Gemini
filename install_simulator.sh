clear
set -e

make -f MakeSim

THEOS_OBJ_DIR=./.theos/obj/iphone_simulator/debug

#install tweak into simject folder

rm -rf /opt/simject/Gemini.plist ||:
cp -rfv ./Gemini.plist /opt/simject
rm -rf /opt/simject/Gemini.dylib ||:
cp -rfv $THEOS_OBJ_DIR/Gemini.dylib /opt/simject

resim
