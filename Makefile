#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/version.mk

PKG_NAME:=opkg
PKG_REV:=9c97d5ecd795709c8584e972bfdf3aee3a5b846d
PKG_VERSION:=$(PKG_REV)
PKG_RELEASE:=7

PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=opkg-$(PKG_VERSION)
PKG_SOURCE_URL:=http://git.yoctoproject.org/git/opkg
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)
PKG_FIXUP:=autoreconf
PKG_REMOVE_FILES = autogen.sh aclocal.m4

PKG_LICENSE:=GPLv2
PKG_LICENSE_FILES:=COPYING

PKG_BUILD_PARALLEL:=1
HOST_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

define Package/apkg/Default
  SUBMENU:=Captive Portals
  SECTION:=net
  CATEGORY:=Network
  TITLE:=apkg package manager
  DEPENDS:=+libopenssl +libcurl
  MAINTAINER:=Jo-Philipp Wich <xm@subsignal.org>
  URL:=http://wiki.openmoko.org/wiki/Opkg
endef

define Package/apkg/Default/description
  Lightweight package management system
  opkg is the opkg Package Management System, for handling
  installation and removal of packages on a system. It can
  recursively follow dependencies and download all packages
  necessary to install a particular package.

  opkg knows how to install both .ipk and .deb packages.
endef

define Package/apkg
  $(call Package/apkg/Default)
  VARIANT:=unsigned
endef

define Package/apkg/description
  $(call Package/apkg/Default/description)
endef

define Package/apkg/conffiles
/etc/opkg.conf
endef


TARGET_CFLAGS += $(if $(CONFIG_GCC_VERSION_4_3)$(CONFIG_GCC_VERSION_4_4),-Wno-array-bounds)
TARGET_CFLAGS += -ffunction-sections -fdata-sections
EXTRA_CFLAGS += $(TARGET_CPPFLAGS)

CONFIGURE_ARGS += \
	--disable-gpg \
	--with-opkgetcdir=/etc \
	--with-opkglockfile=/var/lock/opkg.lock


MAKE_FLAGS = \
		CC="$(TARGET_CC)" \
		DESTDIR="$(PKG_INSTALL_DIR)" \
		HOST_CPU="$(PKGARCH)" \
		LDFLAGS="-Wl,--gc-sections" \

define Package/apkg/Default/install
	$(INSTALL_DIR) $(1)/usr/lib/opkg
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) ./files/opkg$(2).conf $(1)/etc/opkg.conf
	$(VERSION_SED) $(1)/etc/opkg.conf
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/opkg-cl $(1)/bin/opkg
endef

Package/apkg/install = $(call Package/apkg/Default/install,$(1),)


define Build/InstallDev
	mkdir -p $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/libopkg $(1)/usr/include/
endef


HOST_CONFIGURE_ARGS+= \
	--disable-gpg \
	--with-opkgetcdir=/etc \
	--with-opkglockfile=/tmp/opkg.lock

define Host/Compile
	+$(MAKE) $(HOST_JOBS) -C $(HOST_BUILD_DIR) CC="$(HOSTCC)" all
endef

define Host/Install
	$(INSTALL_BIN) $(HOST_BUILD_DIR)/src/opkg-cl $(STAGING_DIR_HOST)/bin/opkg
endef

$(eval $(call BuildPackage,apkg))
$(eval $(call HostBuild))
