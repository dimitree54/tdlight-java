package it.tdlight.common.utils;

public final class LibraryVersion {

	public static final String VERSION = "${project.version}";
	public static final String NATIVES_VERSION = "4.0.${nativesRevisionNumber}${nativesRevisionSuffix}";
	public static final String IMPLEMENTATION_NAME = "tdlight";
	public static final String LINUX_X86_CLASS = "it.tdlight.jni.tdlight.linux.x86.v4_0_${nativesRevisionNumber}.LoadLibrary";
	public static final String LINUX_AMD64_CLASS = "it.tdlight.jni.tdlight.linux.amd64.v4_0_${nativesRevisionNumber}.LoadLibrary";
	public static final String LINUX_AARCH64_CLASS = "it.tdlight.jni.tdlight.linux.aarch64.v4_0_${nativesRevisionNumber}.LoadLibrary";
	public static final String LINUX_ARMHF_CLASS = "it.tdlight.jni.tdlight.linux.armhf.v4_0_${nativesRevisionNumber}.LoadLibrary";
	public static final String LINUX_S390X_CLASS = "it.tdlight.jni.tdlight.linux.s390x.v4_0_${nativesRevisionNumber}.LoadLibrary";
	public static final String LINUX_PPC64LE_CLASS = "it.tdlight.jni.tdlight.linux.ppc64le.v4_0_${nativesRevisionNumber}.LoadLibrary";
	public static final String WINDOWS_AMD64_CLASS = "it.tdlight.jni.tdlight.win.amd64.v4_0_${nativesRevisionNumber}.LoadLibrary";
	public static final String OSX_AMD64_CLASS = "it.tdlight.jni.tdlight.osx.amd64.v4_0_${nativesRevisionNumber}.LoadLibrary";
	public static final String OSX_AARCH64_CLASS = "it.tdlight.jni.tdlight.osx.aarch64.v4_0_${nativesRevisionNumber}.LoadLibrary";
}