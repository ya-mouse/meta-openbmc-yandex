do_patchappend () {
    rm -f ${S}/crypto/wvblowfish.cc \
          ${S}/crypto/tests/cryptotest.cc
}

addtask patchappend after do_patch before do_compile
