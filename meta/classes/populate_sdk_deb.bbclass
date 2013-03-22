do_populate_sdk[depends] += "dpkg-native:do_populate_sysroot apt-native:do_populate_sysroot bzip2-native:do_populate_sysroot"
do_populate_sdk[recrdeptask] += "do_package_write_deb"


DEB_SDK_ARCH = "${@[d.getVar('SDK_ARCH', True), "i386"]\
                [d.getVar('SDK_ARCH', True) in \
                ["x86", "i486", "i586", "i686", "pentium"]]}"

do_populate_sdk[lockfiles] += "${DEPLOY_DIR_DEB}/deb.lock"

populate_sdk_post_deb () {

	local target_rootfs=$1

	mkdir -p ${target_rootfs}/etc
	tar -cf - -C ${STAGING_ETCDIR_NATIVE} -ps apt | tar -xf - -C ${target_rootfs}/etc
}

populate_sdk_deb () {

	# update index
	package_update_index_deb

	## install target ##
	# This needs to work in the same way as rootfs_deb.bbclass
	echo "Installing TARGET packages"

	mkdir -p ${IMAGE_ROOTFS}/var/dpkg/alternatives

	export INSTALL_ROOTFS_DEB="${SDK_OUTPUT}/${SDKTARGETSYSROOT}"
	export INSTALL_BASEARCH_DEB="${DPKG_ARCH}"
	export INSTALL_ARCHS_DEB="${PACKAGE_ARCHS}"
	export INSTALL_PACKAGES_NORMAL_DEB="${TOOLCHAIN_TARGET_TASK}"
	export INSTALL_PACKAGES_ATTEMPTONLY_DEB="${TOOLCHAIN_TARGET_TASK_ATTEMPTONLY}"
	export PACKAGES_LINGUAS_DEB=""
	export INSTALL_TASK_DEB="populate_sdk-target"
	export INTERCEPT_DIR=${WORKDIR}/intercept_scripts
	export NATIVE_ROOT=${STAGING_DIR_NATIVE}

	package_install_internal_deb

	${POPULATE_SDK_POST_TARGET_COMMAND}

	populate_sdk_post_deb ${INSTALL_ROOTFS_DEB}

	populate_sdk_log_check populate_sdk

	## install nativesdk ##
	echo "Installing NATIVESDK packages"
	export INSTALL_ROOTFS_DEB="${SDK_OUTPUT}"
	export INSTALL_BASEARCH_DEB="${DEB_SDK_ARCH}"
	export INSTALL_ARCHS_DEB="${SDK_PACKAGE_ARCHS}"
	export INSTALL_PACKAGES_NORMAL_DEB="${TOOLCHAIN_HOST_TASK}"
	export INSTALL_PACKAGES_ATTEMPTONLY_DEB="${TOOLCHAIN_HOST_TASK_ATTEMPTONLY}"
	export PACKAGES_LINGUAS_DEB=""
	export INSTALL_TASK_DEB="populate_sdk-nativesdk"

	package_install_internal_deb
	${POPULATE_SDK_POST_HOST_COMMAND}
	populate_sdk_post_deb ${SDK_OUTPUT}/${SDKPATHNATIVE}

	#move remainings
	install -d ${SDK_OUTPUT}/${SDKPATHNATIVE}/var/lib/dpkg
	mv ${SDK_OUTPUT}/var/lib/dpkg/* ${SDK_OUTPUT}/${SDKPATHNATIVE}/var/lib/dpkg
	rm -rf ${SDK_OUTPUT}/var

	populate_sdk_log_check populate_sdk
}

