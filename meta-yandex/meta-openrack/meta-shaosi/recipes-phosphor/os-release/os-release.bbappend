python() {
        import os
        import subprocess
        import re

        cwd = os.getcwd()
        os.chdir(d.getVar("LAYER_DIR",True))
        t = None
        ver = None
        try:
            t = subprocess.check_output(['git', 'describe', '--tags']).rstrip()
            ver = t.rsplit('-',2)[0]
            ver = re.sub('[^0-9.-]','',ver)
            if ver and t:
                short_ver = '0.1.0-' + ver
                long_ver  = 'OpenBMC:' + d.getVar('VERSION_ID',True) + " Yandex:0.1.0-" + t
                d.setVar('VERSION', short_ver)
                d.setVar('VERSION_ID', long_ver)
                d.setVar('BUILD_ID', d.getVar('DATETIME'))
        except:
           pass
        os.chdir(cwd)
}
