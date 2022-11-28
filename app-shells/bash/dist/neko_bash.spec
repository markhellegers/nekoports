product neko_bash
    id "bash 5.1.16 - The GNU Bourne Again Shell"
    image sw
        id "Software"
        version 1
        order 9999
        subsys eoe default
            id "execution only env"
            replaces self
            prereq (
                neko_gettext.sw.lib 10 maxint
                neko_libiconv.sw.lib 5 maxint
            )
            exp neko_bash.sw.eoe
        endsubsys
        subsys headers default
            id "header files"
            replaces self
            exp neko_bash.sw.headers
        endsubsys
        subsys lib default
            id "shared libraries"
            replaces self
            prereq (
                neko_gettext.sw.lib 10 maxint
                neko_libiconv.sw.lib 5 maxint
            )
            exp neko_bash.sw.lib
        endsubsys
    endimage
    image man
        id "Man Pages"
        version 1
        order 9999
        subsys manpages default
            id "man pages"
            replaces self
            exp neko_bash.man.manpages
        endsubsys
    endimage
    image opt
        id "Optional"
        version 1
        order 9999
        subsys src
            id "original source code"
            replaces self
            exp neko_bash.opt.src
        endsubsys
        subsys patches
            id "patches to source code"
            replaces self
            exp neko_bash.opt.patches
        endsubsys
        subsys relnotes
            id "release notes"
            replaces self
            exp neko_bash.opt.relnotes
        endsubsys
        subsys dist
            id "distribution files"
            replaces self
            exp neko_bash.opt.dist
        endsubsys
    endimage
endproduct
