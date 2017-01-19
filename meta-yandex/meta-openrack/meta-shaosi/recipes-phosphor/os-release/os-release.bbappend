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
