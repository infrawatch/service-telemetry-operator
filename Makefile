.PHONY: all oc-create-build oc-start-build
BUILD_DIR = ./build
ROOTDIR = $(realpath .)
NAME = $(notdir $(ROOTDIR))

all: oc-create-build oc-start-build

oc-create-build:
	@oc new-build --name service-telemetry-operator --dockerfile - < $(BUILD_DIR)/Dockerfile

oc-start-build:
	@oc start-build service-telemetry-operator --wait --from-dir .
