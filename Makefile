BUNDLE_NAME = ColdHarbor.saver
INSTALL_PATH = ~/Library/Screen\ Savers
BUILD_DIR = build
CC = clang
CFLAGS = -fobjc-arc -Wall -Werror
LDFLAGS = -framework Cocoa -framework ScreenSaver
OBJECTS = ColdHarborView.o
RESOURCES = Orbitron-Regular.ttf

all: $(BUILD_DIR)/$(BUNDLE_NAME)

$(BUILD_DIR)/$(BUNDLE_NAME): $(OBJECTS)
	@mkdir -p $(BUILD_DIR)/$(BUNDLE_NAME)/Contents/MacOS
	@mkdir -p $(BUILD_DIR)/$(BUNDLE_NAME)/Contents/Resources
	$(CC) $(CFLAGS) $(LDFLAGS) -bundle -o $(BUILD_DIR)/$(BUNDLE_NAME)/Contents/MacOS/ColdHarbor $(OBJECTS)
	cp Info.plist $(BUILD_DIR)/$(BUNDLE_NAME)/Contents/
	cp $(RESOURCES) $(BUILD_DIR)/$(BUNDLE_NAME)/Contents/Resources/

%.o: %.m
	$(CC) $(CFLAGS) -c $< -o $@

install: $(BUILD_DIR)/$(BUNDLE_NAME)
	@mkdir -p $(INSTALL_PATH)
	cp -R $(BUILD_DIR)/$(BUNDLE_NAME) $(INSTALL_PATH)/

clean:
	rm -rf $(BUILD_DIR) $(OBJECTS)

.PHONY: all install clean 