python() {
        import os
        v = None
        try:
            with open(os.getenv('BUILDDIR', os.getcwd())+'/conf/build.id', 'r') as f:
                v = f.read().rstrip('\n')
            if v:
                d.setVar('VERSION', '0.1.0-%s' % v)
                d.setVar('VERSION_ID', '0.1.0-%s' % v)
                d.setVar('BUILD_ID', d.getVar('DATETIME'))
        except:
            pass
}

OS_RELEASE_FIELDS_append = " BUILD_ID"
os_release[vardepsexclude] = "DATETIME BUILD_ID VERSION VERSION_ID COREBASE DISTRO_VERSION DATE OS_RELEASE_FIELDS"
do_deploy[vardepsexclude] = "BUILD_ID VERSION VERSION_ID COREBASE DATETIME"
do_compile[vardepsexclude] = "BUILD_ID VERSION VERSION_ID COREBASE DATETIME DISTRO_VERSION DATE OS_RELEASE_FIELDS PRETTY_NAME"
do_compile[nostamp] = "1"
do_compile_remove[vardeps] = "BUILD_ID VERSION VERSION_ID COREBASE DATETIME DISTRO_VERSION DATE"
