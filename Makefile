project=Ola.xcodeproj
scheme=Ola
sdk=iphonesimulator

all: clean debug

clean:
	-rm -rf build

debug:
	xcodebuild -configuration Debug build

release:
	xcodebuild

.PHONY: all clean debug release
