#############################################################################
#  Description:
#
#  Copyright (c) 2021 Nokia
#############################################################################

SDK_VERSION := 6.5.22
BCMSDK_URL := https://github.com/Broadcom-Network-Switching-Software/OpenBCM.git
bcm_objpath := sdk/build/xgs/unix-user/x86-smp_generic_64-2_6
GIT_CLONE_SDK = ( \
  git init && \
  git remote add -f origin $(BCMSDK_URL) && \
  git config core.sparseCheckout true && \
  echo "Legal/" > .git/info/sparse-checkout && \
  echo "sdk-$(SDK_VERSION)/" >> .git/info/sparse-checkout && \
  git pull origin master)

BLDCONFIG := xgs

.bcmsdk-clone:
	mkdir -p openbcm && cd openbcm && \
	( [ -d sdk-$(SDK_VERSION) ] || $(GIT_CLONE_SDK) ) && \
	cd - && ln -sf openbcm/sdk-$(SDK_VERSION) sdk
	touch $@

.bcmsdk-patch: .bcmsdk-clone
	cd sdk && \
	  patch -p1 -i $(this_dir)/bcm/0000-greyhound-port-config.patch && \
	  patch -p1 -i $(this_dir)/bcm/0001-sdk-build-fast.patch && \
	  patch -p1 -i $(this_dir)/bcm/0002-sdk-bde-create.patch
	touch $@

# For bcmsdk targets where, word2 is one of (all,build,clean)
.PHONY: bcmsdk_%
bcmsdk_%: .bcmsdk-patch
	echo "****** Begin $@  ******"
	export MAKE_LOCAL=$(this_dir)bcm/Make.xgs.local ; \
          export MAKEFLAGS=-j$(JOBS) ; \
          export BLDCONFIG=$(BLDCONFIG) ; \
          $(MAKE) -C sdk/systems/linux/user/x86-smp_generic_64-2_6 $(word2)
	echo "****** Complete $@ ******"

libbcmsdk.so.1.debug: bcmsdk_build
	$(CC) -fPIC -shared -Wl,-soname,libbcmsdk.so -o $@ \
	-L$(bcm_objpath) \
	-Wl,--whole-archive $(bcm_libraries) -Wl,--no-whole-archive \
	$(bcm_extra_objs)

libbcmsdk.so.1: libbcmsdk.so.1.debug
	strip --strip-unneeded -o $@ $<

print:
	echo $(bcm_libraries)

bcm_extra_objs = \
  $(bcm_objpath)/platform_defines.o \
  $(bcm_objpath)/version.o

bcm_libraries = $(subst .a,,$(subst lib,-l,$(notdir $(wildcard $(bcm_objpath)/*.a))))

sdk_cfgflags = -D_REENTRANT -DLINUX -D_DEFAULT_SOURCE -DBCM_MONOTONIC_TIME -DBCM_PORT_DEFAULT_DISABLE -DCOMPILER_OVERRIDE_NO_INLINE -DCOMPILER_OVERRIDE_NO_STATIC -DVENDOR_CALHOUN  -DVENDOR_GAMMA  -DVENDOR_BROADCOM -DLONGS_ARE_64BITS -DPTRS_ARE_64BITS -DPHYS_ADDRS_ARE_64BITS -DSAL_SPL_LOCK_ON_IRQ -DSYS_BE_PIO=0 -DSYS_BE_PACKET=0 -DSYS_BE_OTHER=0 -DLE_HOST=1 -DBCM_PLATFORM_STRING=\"X86\" -DSAL_BDE_DMA_MEM_DEFAULT=16 -DNO_BCM_5675_A0 -DNO_BCM_56504_A0 -DNO_BCM_56504_B0 -DNO_BCM_56314_A0 -DNO_BCM_56112_A0 -DNO_BCM_56304_B0 -DNO_BCM_56102_A0 -DNO_BCM_56580_A0 -DNO_BCM_56700_A0 -DNO_BCM_56800_A0 -DNO_BCM_56218_A0 -DNO_BCM_56514_A0 -DNO_BCM_56624_A0 -DNO_BCM_56680_A0 -DNO_BCM_56680_B0 -DNO_BCM_56224_A0 -DNO_BCM_56224_B0 -DNO_BCM_56820_A0 -DNO_BCM_53314_A0 -DNO_BCM_56725_A0 -DNO_BCM_56624_B0 -DNO_BCM_56634_A0 -DNO_BCM_56634_B0 -DNO_BCM_56524_A0 -DNO_BCM_56524_B0 -DNO_BCM_56685_A0 -DNO_BCM_56685_B0 -DNO_BCM_56334_A0 -DNO_BCM_56334_B0 -DNO_BCM_56840_A0 -DNO_BCM_56840_B0 -DNO_BCM_56142_A0 -DNO_BCM_53324_A0 -DNO_BCM_88732_A0 -DNO_BCM_56440_A0 -DNO_BCM_56440_B0 -DNO_BCM_56640_A0 -DNO_BCM_56850_A0 -DNO_BCM_56450_A0 -DNO_BCM_56450_B0 -DNO_BCM_56450_B1 -DNO_BCM_56340_A0 -DNO_BCM_56150_A0 -DNO_BCM_56960_A0 -DNO_BCM_56860_A0 -DNO_BCM_56560_A0 -DNO_BCM_56260_A0 -DNO_BCM_56260_B0 -DNO_BCM_56160_A0 -DNO_BCM_56560_B0 -DNO_BCM_56270_A0 -DNO_BCM_56965_A0 -DNO_BCM_56970_A0 -DNO_BCM_56980_A0 -DNO_BCM_56980_B0 -DNO_BCM_53570_A0 -DNO_BCM_56870_A0 -DNO_BCM_53570_B0 -DNO_BCM_53540_A0 -DNO_BCM_56670_A0 -DNO_BCM_56370_A0 -DNO_BCM_56770_A0 -DNO_BCM_56670_B0 -DNO_BCM_56275_A0 -DNO_BCM_56470_A0 -DNO_BCM_56070_A0 -DNO_BCM_56670_C0 -DUSE_SCACHE_DIRTY_BIT  -DINCLUDE_MEM_SCAN  -DINCLUDE_EDITLINE  -DINCLUDE_CUSTOMER  -DINCLUDE_TELNET  -DINCLUDE_DRIVERS  -DINCLUDE_CINT  -DBCM_RPC_SUPPORT  -DBCM_ESW_SUPPORT -DINCLUDE_LIB_CPUDB -DINCLUDE_LIB_CPUTRANS -DINCLUDE_LIB_DISCOVER -DINCLUDE_LIB_STKTASK -DDISCOVER_APP_DATA_BOARDID -DINCLUDE_LIB_CINT -DCINT_CONFIG_INCLUDE_SDK_SAL=1 -DCINT_CONFIG_INCLUDE_PARSER=1 -DCINT_CONFIG_INCLUDE_CINT_LOAD=0 -DBCM_API_VERBOSE_LOGGING=0  -DINCLUDE_PHY_EMPTY -DINCLUDE_LONGREACH -DNO_BCM_88732_A0 -DLE_HOST=1 -D__BSD_SOURCE -DUNIX

# sdk default target is "build" (not "all"), so we handle it here
bcmsdk_all: libbcmsdk.so.1
	echo "****** Complete $@ ******"

bcmsdk_clobber:
	rm -fr sdk/build


$(V).SILENT:
