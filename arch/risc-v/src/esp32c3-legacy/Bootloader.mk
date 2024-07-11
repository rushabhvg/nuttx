############################################################################
# arch/risc-v/src/esp32c3-legacy/Bootloader.mk
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.  The
# ASF licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.
#
############################################################################

ifeq ($(CONFIG_ESP32C3_BOOTLOADER_BUILD_FROM_SOURCE),y)

TOOLSDIR           = $(TOPDIR)/tools/espressif
CHIPDIR            = $(TOPDIR)/arch/risc-v/src/chip
HALDIR             = $(CHIPDIR)/esp-hal-3rdparty

BOOTLOADER_DIR     = $(CHIPDIR)/bootloader
BOOTLOADER_SRCDIR  = $(BOOTLOADER_DIR)/esp-nuttx-bootloader
BOOTLOADER_VERSION = main
BOOTLOADER_URL     = https://github.com/espressif/esp-nuttx-bootloader
BOOTLOADER_OUTDIR  = out
BOOTLOADER_CONFIG  = $(BOOTLOADER_DIR)/bootloader.conf

MCUBOOT_SRCDIR     = $(BOOTLOADER_DIR)/mcuboot
MCUBOOT_ESPDIR     = $(MCUBOOT_SRCDIR)/boot/espressif
MCUBOOT_URL        = https://github.com/mcu-tools/mcuboot

# Helpers for creating the configuration file

cfg_en  = echo "$(1)=$(if $(CONFIG_ESP32C3_APP_FORMAT_MCUBOOT),1,y)";
cfg_dis = echo "$(1)=$(if $(CONFIG_ESP32C3_APP_FORMAT_MCUBOOT),0,n)";
cfg_val = echo "$(1)=$(2)";

# Commands for colored and formatted output

RED    = \033[1;31m
YELLOW = \033[1;33m
BOLD   = \033[1m
RST    = \033[0m

$(BOOTLOADER_CONFIG): $(TOPDIR)/.config
ifeq ($(CONFIG_ESP32C3_SECURE_BOOT),y)
	$(Q) if [ -z "$(ESPSEC_KEYDIR)" ]; then \
		echo ""; \
		echo "$(RED)bootloader error:$(RST) Missing argument for secure boot keys directory."; \
		echo "USAGE: make bootloader ESPSEC_KEYDIR=<dir>"; \
		echo ""; \
		exit 1; \
	fi
endif
	$(Q) echo "Creating Bootloader configuration"
	$(Q) { \
		$(if $(CONFIG_ESP32C3_FLASH_2M),$(call cfg_en,CONFIG_ESPTOOLPY_FLASHSIZE_2MB)) \
		$(if $(CONFIG_ESP32C3_FLASH_4M),$(call cfg_en,CONFIG_ESPTOOLPY_FLASHSIZE_4MB)) \
		$(if $(CONFIG_ESP32C3_FLASH_8M),$(call cfg_en,CONFIG_ESPTOOLPY_FLASHSIZE_8MB)) \
		$(if $(CONFIG_ESP32C3_FLASH_16M),$(call cfg_en,CONFIG_ESPTOOLPY_FLASHSIZE_16MB)) \
		$(if $(CONFIG_ESP32C3_FLASH_MODE_DIO),$(call cfg_en,CONFIG_ESPTOOLPY_FLASHMODE_DIO)) \
		$(if $(CONFIG_ESP32C3_FLASH_MODE_DOUT),$(call cfg_en,CONFIG_ESPTOOLPY_FLASHMODE_DOUT)) \
		$(if $(CONFIG_ESP32C3_FLASH_MODE_QIO),$(call cfg_en,CONFIG_ESPTOOLPY_FLASHMODE_QIO)) \
		$(if $(CONFIG_ESP32C3_FLASH_MODE_QOUT),$(call cfg_en,CONFIG_ESPTOOLPY_FLASHMODE_QOUT)) \
		$(if $(CONFIG_ESP32C3_FLASH_FREQ_80M),$(call cfg_en,CONFIG_ESPTOOLPY_FLASHFREQ_80M)) \
		$(if $(CONFIG_ESP32C3_FLASH_FREQ_40M),$(call cfg_en,CONFIG_ESPTOOLPY_FLASHFREQ_40M)) \
		$(if $(CONFIG_ESP32C3_FLASH_FREQ_26M),$(call cfg_en,CONFIG_ESPTOOLPY_FLASHFREQ_26M)) \
		$(if $(CONFIG_ESP32C3_FLASH_FREQ_20M),$(call cfg_en,CONFIG_ESPTOOLPY_FLASHFREQ_20M)) \
	} > $(BOOTLOADER_CONFIG)
ifeq ($(CONFIG_ESP32C3_APP_FORMAT_MCUBOOT),y)
	$(Q) { \
		$(if $(CONFIG_ESP32C3_SECURE_BOOT),$(call cfg_en,CONFIG_SECURE_BOOT)$(call cfg_en,CONFIG_SECURE_BOOT_V2_ENABLED)$(call cfg_val,CONFIG_ESP_SIGN_KEY_FILE,$(abspath $(TOPDIR)/$(ESPSEC_KEYDIR)/$(subst ",,$(CONFIG_ESP32C3_SECURE_BOOT_APP_SIGNING_KEY))))) \
		$(if $(CONFIG_ESP32C3_SECURE_SIGNED_APPS_SCHEME_RSA_2048),$(call cfg_en,CONFIG_ESP_USE_MBEDTLS)$(call cfg_en,CONFIG_ESP_SIGN_RSA)$(call cfg_val,CONFIG_ESP_SIGN_RSA_LEN,2048)) \
		$(if $(CONFIG_ESP32C3_SECURE_SIGNED_APPS_SCHEME_RSA_3072),$(call cfg_en,CONFIG_ESP_USE_MBEDTLS)$(call cfg_en,CONFIG_ESP_SIGN_RSA)$(call cfg_val,CONFIG_ESP_SIGN_RSA_LEN,3072)) \
		$(if $(CONFIG_ESP32C3_SECURE_SIGNED_APPS_SCHEME_ECDSA_P256),$(call cfg_en,CONFIG_ESP_USE_TINYCRYPT)$(call cfg_en,CONFIG_ESP_SIGN_EC256)) \
		$(if $(CONFIG_ESP32C3_SECURE_SIGNED_APPS_SCHEME_ED25519),$(call cfg_en,CONFIG_ESP_USE_TINYCRYPT)$(call cfg_en,CONFIG_ESP_SIGN_ED25519)) \
		$(if $(CONFIG_ESP32C3_SECURE_BOOT_ALLOW_JTAG),$(call cfg_en,CONFIG_SECURE_BOOT_ALLOW_JTAG)) \
		$(if $(CONFIG_ESP32C3_SECURE_BOOT_ALLOW_EFUSE_RD_DIS),$(call cfg_en,CONFIG_SECURE_BOOT_V2_ALLOW_EFUSE_RD_DIS)) \
		$(if $(CONFIG_ESP32C3_SECURE_DISABLE_ROM_DL_MODE),$(call cfg_en,CONFIG_SECURE_DISABLE_ROM_DL_MODE)) \
		$(if $(CONFIG_ESP32C3_SECURE_ENABLE_SECURE_ROM_DL_MODE),$(call cfg_en,CONFIG_SECURE_ENABLE_SECURE_ROM_DL_MODE)) \
		$(if $(CONFIG_ESP32C3_SECURE_INSECURE_ALLOW_DL_MODE),$(call cfg_en,CONFIG_SECURE_INSECURE_ALLOW_DL_MODE)) \
		$(if $(CONFIG_ESP32C3_SECURE_FLASH_ENC_ENABLED),$(call cfg_en,CONFIG_SECURE_FLASH_ENC_ENABLED)) \
		$(if $(CONFIG_ESP32C3_SECURE_FLASH_ENCRYPTION_MODE_DEVELOPMENT),$(call cfg_en,CONFIG_SECURE_FLASH_ENCRYPTION_MODE_DEVELOPMENT)) \
		$(if $(CONFIG_ESP32C3_SECURE_FLASH_ENCRYPTION_MODE_RELEASE),$(call cfg_en,CONFIG_SECURE_FLASH_ENCRYPTION_MODE_RELEASE)) \
		$(if $(CONFIG_ESP32C3_SECURE_FLASH_UART_BOOTLOADER_ALLOW_ENC),$(call cfg_en,CONFIG_SECURE_FLASH_UART_BOOTLOADER_ALLOW_ENC)) \
		$(if $(CONFIG_ESP32C3_SECURE_FLASH_UART_BOOTLOADER_ALLOW_CACHE),$(call cfg_en,CONFIG_SECURE_FLASH_UART_BOOTLOADER_ALLOW_CACHE)) \
		$(if $(CONFIG_ESP32C3_SECURE_FLASH_REQUIRE_ALREADY_ENABLED),$(call cfg_en,CONFIG_SECURE_FLASH_REQUIRE_ALREADY_ENABLED)) \
		$(call cfg_val,CONFIG_ESP_BOOTLOADER_OFFSET,0x1000) \
		$(call cfg_val,CONFIG_ESP_BOOTLOADER_SIZE,0xF000) \
		$(call cfg_val,CONFIG_ESP_IMAGE0_PRIMARY_START_ADDRESS,$(CONFIG_ESP32C3_OTA_PRIMARY_SLOT_OFFSET)) \
		$(call cfg_val,CONFIG_ESP_APPLICATION_SIZE,$(CONFIG_ESP32C3_OTA_SLOT_SIZE)) \
		$(call cfg_val,CONFIG_ESP_IMAGE0_SECONDARY_START_ADDRESS,$(CONFIG_ESP32C3_OTA_SECONDARY_SLOT_OFFSET)) \
		$(call cfg_en,CONFIG_ESP_MCUBOOT_WDT_ENABLE) \
		$(call cfg_val,CONFIG_ESP_SCRATCH_OFFSET,$(CONFIG_ESP32C3_OTA_SCRATCH_OFFSET)) \
		$(call cfg_val,CONFIG_ESP_SCRATCH_SIZE,$(CONFIG_ESP32C3_OTA_SCRATCH_SIZE)) \
		$(call cfg_en,CONFIG_ESP_CONSOLE_UART) \
		$(if $(CONFIG_UART0_SERIAL_CONSOLE),$(call cfg_val,CONFIG_ESP_CONSOLE_UART_NUM,0)) \
		$(if $(CONFIG_UART1_SERIAL_CONSOLE),$(call cfg_val,CONFIG_ESP_CONSOLE_UART_NUM,1)) \
	} >> $(BOOTLOADER_CONFIG)
else ifeq ($(CONFIG_ESP32C3_APP_FORMAT_LEGACY),y)
	$(Q) { \
		$(call cfg_dis,CONFIG_BOOTLOADER_REGION_PROTECTION_ENABLE) \
		$(call cfg_en,CONFIG_PARTITION_TABLE_CUSTOM) \
		$(call cfg_val,CONFIG_PARTITION_TABLE_CUSTOM_FILENAME,\"partitions.csv\") \
		$(call cfg_val,CONFIG_PARTITION_TABLE_OFFSET,$(CONFIG_ESP32C3_PARTITION_TABLE_OFFSET)) \
	} >> $(BOOTLOADER_CONFIG)
endif

ifeq ($(CONFIG_ESP32C3_APP_FORMAT_MCUBOOT),y)

BOOTLOADER_BIN        = $(TOPDIR)/mcuboot-esp32c3.bin
BOOTLOADER_SIGNED_BIN = $(TOPDIR)/mcuboot-esp32c3.signed.bin

$(MCUBOOT_SRCDIR):
	$(Q) echo "Cloning MCUboot"
	$(Q) git clone --quiet $(MCUBOOT_URL) $(MCUBOOT_SRCDIR)
	$(Q) git -C "$(MCUBOOT_SRCDIR)" checkout --quiet $(CONFIG_ESP32C3_MCUBOOT_VERSION)
	$(Q) git -C "$(MCUBOOT_SRCDIR)" submodule --quiet update --init --recursive ext/mbedtls

$(BOOTLOADER_BIN): chip/$(ESP_HAL_3RDPARTY_REPO) $(MCUBOOT_SRCDIR) $(BOOTLOADER_CONFIG)
	$(Q) echo "Building Bootloader"
	$(Q) $(TOOLSDIR)/build_mcuboot_esp32c3_legacy.sh \
		-c esp32c3 \
		-f $(BOOTLOADER_CONFIG) \
		-p $(BOOTLOADER_DIR) \
		-e $(HALDIR)
	$(call COPYFILE, $(BOOTLOADER_DIR)/$(BOOTLOADER_OUTDIR)/mcuboot-esp32c3.bin, $(TOPDIR))

bootloader: $(BOOTLOADER_BIN)
ifeq ($(CONFIG_ESP32C3_SECURE_BOOT),y)
	$(eval KEYDIR := $(TOPDIR)/$(ESPSEC_KEYDIR))
	$(eval BOOTLOADER_SIGN_KEY := $(abspath $(KEYDIR)/$(subst ",,$(CONFIG_ESP32C3_SECURE_BOOT_BOOTLOADER_SIGNING_KEY))))
ifeq ($(CONFIG_ESP32C3_SECURE_BOOT_BUILD_SIGNED_BINARIES),y)
	$(Q) if [ ! -f "$(BOOTLOADER_SIGN_KEY)" ]; then \
		echo ""; \
		echo "$(RED)bootloader error:$(RST) Bootloader signing key $(BOLD)$(CONFIG_ESP32C3_SECURE_BOOT_BOOTLOADER_SIGNING_KEY)$(RST) does not exist."; \
		echo "Generate using:"; \
		echo "    espsecure.py generate_signing_key --version 2 $(CONFIG_ESP32C3_SECURE_BOOT_BOOTLOADER_SIGNING_KEY)"; \
		echo ""; \
		exit 1; \
	fi
	$(Q) echo "Signing Bootloader"
	espsecure.py sign_data --version 2 --keyfile $(BOOTLOADER_SIGN_KEY) -o $(BOOTLOADER_SIGNED_BIN) $(BOOTLOADER_BIN)
else
	$(Q) echo ""
	$(Q) echo "$(YELLOW)Bootloader not signed. Sign the bootloader before flashing.$(RST)"
	$(Q) echo "To sign the bootloader, you can use this command:"
	$(Q) echo "    espsecure.py sign_data --version 2 --keyfile $(BOOTLOADER_SIGN_KEY) -o mcuboot-esp32c3.signed.bin mcuboot-esp32c3.bin"
	$(Q) echo ""
endif
endif

clean_bootloader:
	$(call DELDIR,$(MCUBOOT_SRCDIR))
	$(call DELDIR,$(BOOTLOADER_DIR)/$(BOOTLOADER_OUTDIR))
	$(call DELFILE,$(BOOTLOADER_CONFIG))
	$(call DELFILE,$(BOOTLOADER_BIN))
	$(if $(CONFIG_ESP32C3_SECURE_BOOT_BUILD_SIGNED_BINARIES),$(call DELFILE,$(BOOTLOADER_SIGNED_BIN)))

else ifeq ($(CONFIG_ESP32C3_APP_FORMAT_LEGACY),y)

$(BOOTLOADER_SRCDIR):
	$(Q) git clone $(BOOTLOADER_URL) $(BOOTLOADER_SRCDIR) -b $(BOOTLOADER_VERSION)
	$(Q) git -C $(BOOTLOADER_SRCDIR) submodule update --init esp-idf

bootloader: $(BOOTLOADER_SRCDIR) $(BOOTLOADER_CONFIG)
	$(Q) echo "Building Bootloader binaries"
	$(Q) $(BOOTLOADER_SRCDIR)/build_idfboot.sh -c esp32c3 -s -f $(BOOTLOADER_CONFIG)
	$(call COPYFILE,$(BOOTLOADER_SRCDIR)/$(BOOTLOADER_OUTDIR)/bootloader-esp32c3.bin,$(TOPDIR))
	$(call COPYFILE,$(BOOTLOADER_SRCDIR)/$(BOOTLOADER_OUTDIR)/partition-table-esp32c3.bin,$(TOPDIR))

clean_bootloader:
	$(call DELDIR,$(BOOTLOADER_SRCDIR))
	$(call DELFILE,$(BOOTLOADER_CONFIG))
	$(call DELFILE,$(TOPDIR)/bootloader-esp32c3.bin)
	$(call DELFILE,$(TOPDIR)/partition-table-esp32c3.bin)

endif

else ifeq ($(CONFIG_ESP32C3_BOOTLOADER_DOWNLOAD_PREBUILT),y)

BOOTLOADER_VERSION = latest
BOOTLOADER_URL     = https://github.com/espressif/esp-nuttx-bootloader/releases/download/$(BOOTLOADER_VERSION)

ifeq ($(CONFIG_ESP32C3_APP_FORMAT_LEGACY),y)

bootloader:
	$(call DOWNLOAD,$(BOOTLOADER_URL),bootloader-esp32c3.bin,$(TOPDIR)/bootloader-esp32c3.bin)
	$(call DOWNLOAD,$(BOOTLOADER_URL),partition-table-esp32c3.bin,$(TOPDIR)/partition-table-esp32c3.bin)

clean_bootloader:
	$(call DELFILE,$(TOPDIR)/bootloader-esp32c3.bin)
	$(call DELFILE,$(TOPDIR)/partition-table-esp32c3.bin)

endif

endif
