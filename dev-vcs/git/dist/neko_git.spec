product neko_git
    id "git 2.36.0 - distributed version control system"
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
                neko_zlib.sw.lib 9 maxint
                neko_curl.sw.lib 12 maxint
                neko_libidn2.sw.lib 1 maxint
                neko_openssl.sw.lib 33 maxint
                neko_expat.sw.lib 5 maxint
                neko_libunistring.sw.lib 1 maxint
            )
            exp neko_git.sw.eoe
        endsubsys
    endimage
    image opt
        id "Optional"
        version 1
        order 9999
        subsys src
            id "original source code"
            replaces self
            exp neko_git.opt.src
        endsubsys
        subsys patches
            id "patches to source code"
            replaces self
            exp neko_git.opt.patches
        endsubsys
        subsys relnotes
            id "release notes"
            replaces self
            exp neko_git.opt.relnotes
        endsubsys
        subsys dist
            id "distribution files"
            replaces self
            exp neko_git.opt.dist
        endsubsys
    endimage
endproduct
