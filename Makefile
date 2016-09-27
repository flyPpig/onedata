# distro for package building (oneof: wily, fedora-23-x86_64)
DISTRIBUTION        ?= none
DOCKER_RELEASE      ?= development
DOCKER_REG_NAME     ?= "docker.onedata.org"
DOCKER_REG_USER     ?= ""
DOCKER_REG_PASSWORD ?= ""

ifeq ($(strip $(ONEPROVIDER_VERSION)),)
ONEPROVIDER_VERSION     := $(shell git describe --tags --always)
endif
ifeq ($(strip $(CLUSTER_MANAGER_VERSION)),)
CLUSTER_MANAGER_VERSION := $(shell git -C cluster_manager describe --tags --always)
endif
ifeq ($(strip $(OP_WORKER_VERSION)),)
OP_WORKER_VERSION       := $(shell git -C op_worker describe --tags --always)
endif
ifeq ($(strip $(OP_PANEL_VERSION)),)
OP_PANEL_VERSION        := $(shell git -C onepanel describe --tags --always)
endif
ifeq ($(strip $(ONECLIENT_VERSION)),)
ONECLIENT_VERSION       := $(shell git -C oneclient describe --tags --always)
endif

ONEPROVIDER_VERSION     := $(shell echo ${ONEPROVIDER_VERSION} | tr - .)
CLUSTER_MANAGER_VERSION := $(shell echo ${CLUSTER_MANAGER_VERSION} | tr - .)
OP_WORKER_VERSION       := $(shell echo ${OP_WORKER_VERSION} | tr - .)
OP_PANEL_VERSION        := $(shell echo ${OP_PANEL_VERSION} | tr - .)
ONECLIENT_VERSION       := $(shell echo ${ONECLIENT_VERSION} | tr - .)

ONEPROVIDER_BUILD       ?= 1

ifdef IGNORE_XFAIL
TEST_RUN := ./test_run.py --ignore-xfail
else
TEST_RUN := ./test_run.py
endif

ifdef VERBOSE
TEST_RUN := $(TEST_RUN) -v
endif

GIT_URL := $(shell git config --get remote.origin.url | sed -e 's/\(\/[^/]*\)$$//g')
GIT_URL := $(shell if [ "${GIT_URL}" = "file:/" ]; then echo 'ssh://git@git.plgrid.pl:7999/vfs'; else echo ${GIT_URL}; fi)
ONEDATA_GIT_URL := $(shell if [ "${ONEDATA_GIT_URL}" = "" ]; then echo ${GIT_URL}; else echo ${ONEDATA_GIT_URL}; fi)
export ONEDATA_GIT_URL

.PHONY: docker package.tar.gz

all: build

##
## Macros
##

NO_CACHE :=  $(shell if [ "${NO_CACHE}" != "" ]; then echo "--no-cache"; fi)

make = $(1)/make.py -s $(1) -r . $(NO_CACHE)
clean = $(call make, $(1)) clean
make_rpm = $(call make, $(1)) -e DISTRIBUTION=$(DISTRIBUTION) --privileged --group mock -i rpm_builder:$(DISTRIBUTION) $(2)
mv_rpm = mv $(1)/package/packages/*.src.rpm package/$(DISTRIBUTION)/SRPMS && \
	mv $(1)/package/packages/*.x86_64.rpm package/$(DISTRIBUTION)/x86_64
make_deb = $(call make, $(1)) -e DISTRIBUTION=$(DISTRIBUTION) --privileged --group sbuild -i deb_builder:$(DISTRIBUTION) $(2)
mv_deb = mv $(1)/package/packages/*.orig.tar.gz package/$(DISTRIBUTION)/source && \
	mv $(1)/package/packages/*.dsc package/$(DISTRIBUTION)/source && \
	mv $(1)/package/packages/*.diff.gz package/$(DISTRIBUTION)/source || \
	mv $(1)/package/packages/*.debian.tar.xz package/$(DISTRIBUTION)/source && \
	mv $(1)/package/packages/*_amd64.changes package/$(DISTRIBUTION)/source && \
	mv $(1)/package/packages/*_amd64.deb package/$(DISTRIBUTION)/binary-amd64
unpack = tar xzf $(1).tar.gz

##
## Submodules
##

branch = $(shell git rev-parse --abbrev-ref HEAD)
submodules:
	./onedata_submodules.sh init ${submodule}
ifeq ($(branch),develop)
	./onedata_submodules.sh update --remote ${submodule}
else
	./onedata_submodules.sh update ${submodule}
endif

##
## Build
##

build: build_appmock build_oz_worker build_oneclient build_op_worker \
    build_cluster_manager build_cluster_worker build_onepanel

build_appmock: submodules
	$(call make, appmock)

build_oz_worker: submodules
	$(call make, oz_worker)

build_oneclient: submodules
	$(call make, oneclient) deb-info

build_op_worker: submodules
	$(call make, op_worker)

build_cluster_manager: submodules
	$(call make, cluster_manager)

build_cluster_worker: submodules
	$(call make, cluster_worker)

build_onepanel: submodules
	$(call make, onepanel)

##
## Artifacts
##

artifact: artifact_appmock artifact_oneclient artifact_op_worker \
    artifact_oz_worker artifact_cluster_manager artifact_cluster_worker \
    artifact_onepanel

artifact_appmock:
	$(call unpack, appmock)

artifact_oneclient:
	$(call unpack, oneclient)

artifact_op_worker:
	$(call unpack, op_worker)

artifact_oz_worker:
	$(call unpack, oz_worker)

artifact_cluster_manager:
	$(call unpack, cluster_manager)

artifact_cluster_worker:
	$(call unpack, cluster_worker)

artifact_onepanel:
	$(call unpack, onepanel)

##
## Test
##

test_env_up:
	${TEST_RUN} --test-type env_up --test-dir tests/env_up

test_packaging:
	${TEST_RUN} --test-type packaging --test-dir tests/packaging -s

test:
	${TEST_RUN} --test-type acceptance --test-dir tests/acceptance/scenarios/${suite}

test_performance:
	${TEST_RUN} --test-type performance --test-dir tests/performance

test_gui:
	${TEST_RUN} --test-type gui --test-dir tests/gui -i onedata/gui_builder:latest --driver=Firefox --self-contained-html

test_profiling:
	${TEST_RUN} --test-type acceptance --test-dir tests/acceptance/profiling

##
## Clean
##

clean_all: clean_appmock clean_oz_worker clean_oneclient \
           clean_op_worker clean_onepanel clean_cluster_manager \
           clean_cluster_worker clean_packages

clean_appmock:
	$(call clean, appmock)

clean_onepanel:
	$(call clean, onepanel)

clean_oz_worker:
	$(call clean, oz_worker)

clean_op_worker:
	$(call clean, op_worker)

clean_oneclient:
	$(call clean, oneclient)

clean_cluster_manager:
	$(call clean, cluster_manager)

clean_cluster_worker:
	$(call clean, cluster_worker)

clean_packages:
	rm -rf oneprovider_meta/oneprovider.spec \
		oneprovider_meta/oneprovider/DEBIAN/control \
		oneprovider_meta/package package

##
## RPM packaging
##

rpm: rpm_oneprovider rpm_oneclient

rpm_oneprovider: rpm_op_panel rpm_op_worker rpm_cluster_manager
	cp -f oneprovider_meta/oneprovider.spec.template oneprovider_meta/oneprovider.spec
	sed -i 's/{{oneprovider_version}}/$(ONEPROVIDER_VERSION)/g' oneprovider_meta/oneprovider.spec
	sed -i 's/{{oneprovider_build}}/$(ONEPROVIDER_BUILD)/g' oneprovider_meta/oneprovider.spec
	sed -i 's/{{cluster_manager_version}}/$(CLUSTER_MANAGER_VERSION)/g' oneprovider_meta/oneprovider.spec
	sed -i 's/{{op_worker_version}}/$(OP_WORKER_VERSION)/g' oneprovider_meta/oneprovider.spec
	sed -i 's/{{op_panel_version}}/$(OP_PANEL_VERSION)/g' oneprovider_meta/oneprovider.spec

	bamboos/docker/make.py -i onedata/rpm_builder --privileged --group mock -c \
	        mock --buildsrpm --spec oneprovider_meta/oneprovider.spec \
	        --sources oneprovider_meta --root $(DISTRIBUTION) \
	        --resultdir oneprovider_meta/package/packages

	bamboos/docker/make.py -i onedata/rpm_builder --privileged --group mock -c \
	        mock --rebuild oneprovider_meta/package/packages/*.src.rpm \
	        --root $(DISTRIBUTION) --resultdir oneprovider_meta/package/packages

	$(call mv_rpm, oneprovider_meta)

rpm_op_panel: clean_onepanel rpmdirs
	$(call make_rpm, onepanel, package) -e PKG_VERSION=$(OP_PANEL_VERSION) -e REL_TYPE=oneprovider
	$(call mv_rpm, onepanel)

rpm_op_worker: clean_op_worker rpmdirs
	$(call make_rpm, op_worker, package) -e PKG_VERSION=$(OP_WORKER_VERSION)
	$(call mv_rpm, op_worker)

rpm_cluster_manager: clean_cluster_manager rpmdirs
	$(call make_rpm, cluster_manager, package) -e PKG_VERSION=$(CLUSTER_MANAGER_VERSION)
	$(call mv_rpm, cluster_manager)

rpm_oneclient: clean_oneclient rpmdirs
	$(call make_rpm, oneclient, rpm) -e PKG_VERSION=$(ONECLIENT_VERSION)
	$(call mv_rpm, oneclient)

rpmdirs:
	mkdir -p package/$(DISTRIBUTION)/SRPMS package/$(DISTRIBUTION)/x86_64

##
## DEB packaging
##

deb: deb_oneprovider deb_oneclient

deb_oneprovider: deb_op_panel deb_op_worker deb_cluster_manager
	cp -f oneprovider_meta/oneprovider/DEBIAN/control.template oneprovider_meta/oneprovider/DEBIAN/control
	sed -i 's/{{oneprovider_version}}/$(ONEPROVIDER_VERSION)/g' oneprovider_meta/oneprovider/DEBIAN/control
	sed -i 's/{{oneprovider_build}}/$(ONEPROVIDER_BUILD)/g' oneprovider_meta/oneprovider/DEBIAN/control
	sed -i 's/{{cluster_manager_version}}/$(CLUSTER_MANAGER_VERSION)/g' oneprovider_meta/oneprovider/DEBIAN/control
	sed -i 's/{{op_worker_version}}/$(OP_WORKER_VERSION)/g' oneprovider_meta/oneprovider/DEBIAN/control
	sed -i 's/{{op_panel_version}}/$(OP_PANEL_VERSION)/g' oneprovider_meta/oneprovider/DEBIAN/control

	bamboos/docker/make.py -s oneprovider_meta -r . -c 'dpkg-deb -b oneprovider'
	mv oneprovider_meta/oneprovider.deb package/$(DISTRIBUTION)/binary-amd64/oneprovider_$(ONEPROVIDER_VERSION)-$(ONEPROVIDER_BUILD)_amd64.deb

deb_op_panel: clean_onepanel debdirs
	$(call make_deb, onepanel, package) -e PKG_VERSION=$(OP_PANEL_VERSION) -e REL_TYPE=oneprovider
	$(call mv_deb, onepanel)

deb_op_worker: clean_op_worker debdirs
	$(call make_deb, op_worker, package) -e PKG_VERSION=$(OP_WORKER_VERSION)
	$(call mv_deb, op_worker)

deb_cluster_manager: clean_cluster_manager debdirs
	$(call make_deb, cluster_manager, package) -e PKG_VERSION=$(CLUSTER_MANAGER_VERSION)
	$(call mv_deb, cluster_manager)

deb_oneclient: clean_oneclient debdirs
	$(call make_deb, oneclient, deb) -e PKG_VERSION=$(ONECLIENT_VERSION)
	$(call mv_deb, oneclient)

debdirs:
	mkdir -p package/$(DISTRIBUTION)/source package/$(DISTRIBUTION)/binary-amd64

##
## Package artifact
##

package.tar.gz:
	tar -chzf package.tar.gz package

##
## Docker artifact
##

docker:
	$(MAKE) -C oneclient docker PKG_VERSION=$(ONECLIENT_VERSION)
	./docker_build.py --repository $(DOCKER_REG_NAME) --user $(DOCKER_REG_USER) \
                      --password $(DOCKER_REG_PASSWORD) \
                      --build-arg RELEASE=$(DOCKER_RELEASE) \
                      --build-arg OP_PANEL_VERSION=$(OP_PANEL_VERSION) \
                      --build-arg CLUSTER_MANAGER_VERSION=$(CLUSTER_MANAGER_VERSION) \
                      --build-arg OP_WORKER_VERSION=$(OP_WORKER_VERSION) \
                      --build-arg ONEPROVIDER_VERSION=$(ONEPROVIDER_VERSION) \
                      --name oneprovider \
                      --publish --remove docker
