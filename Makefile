project=Ola.xcodeproj
scheme=Ola
sdk=iphonesimulator

all: clean build

clean:
	-rm -rf build

debug:
	xcodebuild -configuration Debug build

release:
	xcodebuild

bump:
	agvtool bump

build: release bump

.PHONY: all clean debug release bump
