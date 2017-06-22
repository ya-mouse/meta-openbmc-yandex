python() {
        import os
        v = None
        p = d.getVar("LAYER_DIR",True) + "/conf/build.id"
        try:
            with open(p, 'r') as f:
                v = f.read().rstrip('\n')
            if v:
                d.setVar('VERSION', '0.1.0-%s' % v)
                d.setVar('VERSION_ID', '0.1.0-%s' % v)
                d.setVar('BUILD_ID', d.getVar('DATETIME'))
        except:
            pass
}
