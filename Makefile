.PHONY: help install build deploy watch clean all check-env

# Load environment variables from .env if it exists
ifneq (,$(wildcard .env))
    include .env
    export
endif

# Plugin name from manifest
PLUGIN_NAME ?= obsidian-paste-image-rename

# Default values (can be overridden by .env)
OBSIDIAN_PLUGINS_DIR ?=

# Build output directory
BUILD_DIR = build

# Source files
SRC_DIR = src
SRC_FILES = $(wildcard $(SRC_DIR)/*.ts) $(SRC_DIR)/styles.css
CONFIG_FILES = tsconfig.json esbuild.config.mjs package.json package-lock.json manifest.json

# Build artifact files
BUILD_FILES = $(BUILD_DIR)/main.js $(BUILD_DIR)/styles.css
DEPLOY_FILES = $(BUILD_FILES) manifest.json

help:
	@echo "Obsidian Plugin Build & Deploy"
	@echo ""
	@echo "Available targets:"
	@echo "  make install    - Install dependencies"
	@echo "  make build      - Build the plugin"
	@echo "  make deploy     - Deploy plugin to Obsidian plugins directory"
	@echo "  make watch      - Watch and rebuild on changes"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make all        - Install, build, and deploy"
	@echo ""
	@echo "Configuration:"
	@echo "  Copy .env.example to .env and set OBSIDIAN_PLUGINS_DIR"

node_modules/.installed: package.json package-lock.json
	@echo "Installing dependencies..."
	npm install
	@touch node_modules/.installed

install: node_modules/.installed
	@echo "Dependencies already installed"

# Build targets with proper dependencies
$(BUILD_DIR)/main.js $(BUILD_DIR)/styles.css: $(SRC_FILES) $(CONFIG_FILES) node_modules/.installed
	@echo "Building plugin..."
	npm run build

build: $(BUILD_FILES)

deploy: check-env $(DEPLOY_FILES)
	@echo "Deploying to $(OBSIDIAN_PLUGINS_DIR)/$(PLUGIN_NAME)..."
	@mkdir -p "$(OBSIDIAN_PLUGINS_DIR)/$(PLUGIN_NAME)"
	@cp $(DEPLOY_FILES) "$(OBSIDIAN_PLUGINS_DIR)/$(PLUGIN_NAME)/"
	@touch "$(OBSIDIAN_PLUGINS_DIR)/$(PLUGIN_NAME)/.hotreload"
	@echo "Deployment complete!"

watch: check-env build
	@echo "Starting watch mode..."
	@npm run start & \
	while true; do \
		inotifywait -e modify,create $(BUILD_DIR)/main.js 2>/dev/null || fswatch -1 $(BUILD_DIR)/main.js 2>/dev/null || sleep 2; \
		make deploy; \
	done

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR) node_modules/.installed
	@echo "Clean complete!"

all: install build deploy

check-env:
ifndef OBSIDIAN_PLUGINS_DIR
	@echo "Error: OBSIDIAN_PLUGINS_DIR is not set"
	@echo "Please create a .env file with OBSIDIAN_PLUGINS_DIR defined"
	@echo "Example: cp .env.example .env"
	@exit 1
endif
