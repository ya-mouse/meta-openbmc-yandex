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
            if t:
                arrv = t.rsplit('-',2)
                short_ver = re.sub('[^0-9.-]','',arrv[0])
                short_ver = short_ver + '-' + arrv[1] + '-' + arrv[2]
                long_ver  = 'OpenBMC:' + d.getVar('VERSION_ID',True) + " Yandex:" + short_ver
                d.setVar('VERSION', short_ver)
                d.setVar('VERSION_ID', long_ver)
                d.setVar('BUILD_ID', d.getVar('DATETIME'))
        except:
           pass
        os.chdir(cwd)
}
