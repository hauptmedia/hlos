REQUIRE_IMAGE_METADATA=1
REQUIRE_IMAGE_SIGNATURE=1

platform_check_image() {
	return 0;
}

platform_copy_config() {
	local partdev

	if export_partdevice partdev -1; then
		mount -t vfat -o rw,noatime "/dev/$partdev" /mnt
		cp -af "$CONF_TAR" /mnt/
		umount /mnt
	fi
}

platform_do_upgrade() {
	local diskdev partdev diff

	export_bootdevice && export_partdevice diskdev -2 || {
		echo "Unable to determine upgrade device"
		return 1
	}

	sync

	dd if="/dev/$diskdev" of=/tmp/u-boot.env bs=1024 skip=544 count=128

	get_image "$@" | dd of="/dev/$diskdev" bs=4096 conv=fsync

	dd if=/tmp/u-boot.env of="/dev/$diskdev" bs=1024 seek=544 conv=fsync
	rm /tmp/u-boot.env

	# Separate removal and addtion is necessary; otherwise, partition 1
	# will be missing if it overlaps with the old partition 2
	partx -d - "/dev/$diskdev"
	partx -a - "/dev/$diskdev"

	return 0
}
