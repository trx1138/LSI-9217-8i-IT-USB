FROM alpine:20200917
# Inspiration from: https://www.tfir.io/easiest-way-to-flash-lsi-sas-9211-8i-on-motherboards-without-efi-shell/

RUN apk --no-cache add curl mtools parted p7zip

# Create output directory
ENV ROOT_DIR=imgroot
ENV BOOT_DIR="$ROOT_DIR/efi/boot"
RUN mkdir -p "$BOOT_DIR"

# Download UEFI shell
RUN curl -s -o "$BOOT_DIR/bootx64.efi" 'https://raw.githubusercontent.com/tianocore/edk2/UDK2018/ShellBinPkg/UefiShell/X64/Shell.efi' 

# Download & extract flashing utility
RUN curl 'https://docs.broadcom.com/docs-and-downloads/host-bus-adapters/host-bus-adapters-common-files/sas_sata_6g_p20/Installer_P20_for_UEFI.zip' --output 'installer.zip'
RUN 7z e -o"$ROOT_DIR" installer.zip Installer_P20_for_UEFI/sas2flash_efi_ebc_rel/sas2flash.efi

# Download & extract firmware
RUN curl 'https://docs.broadcom.com/docs-and-downloads/host-bus-adapters/host-bus-adapters-common-files/sas_sata_6g_p20/9211-8i_Package_P20_IR_IT_FW_BIOS_for_MSDOS_Windows.zip' --output 'firmware.zip'
RUN 7z e -o"$ROOT_DIR" firmware.zip 9211-8i_Package_P20_IR_IT_FW_BIOS_for_MSDOS_Windows/Firmware/HBA_9211_8i_IT/2118it.bin 9211-8i_Package_P20_IR_IT_FW_BIOS_for_MSDOS_Windows/sasbios_rel/mptsas2.rom

# Create the image file
ARG IMG
RUN truncate -s 1G "$IMG"
RUN parted --script --align=optimal "$IMG" mklabel gpt mkpart ESP fat32 1MiB 100% set 1 boot on
RUN mformat -t 1022 -h 64 -s 32 -i "$IMG@@1M" -v "flasher" ::

# Recursive copy efi directory
RUN mcopy -i "$IMG@@1M" -sp "$ROOT_DIR"/* ::
