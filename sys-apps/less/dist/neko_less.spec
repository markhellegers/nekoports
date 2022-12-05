product neko_less
    id "less 608 - A free, open-source file pager"
    image sw
        id "Software"
        version 1
        order 9999
        subsys eoe default
            id "execution only env"
            replaces self
            exp neko_less.sw.eoe
        endsubsys
    endimage
    image man
        id "Man Pages"
        version 1
        order 9999
        subsys manpages default
            id "man pages"
            replaces self
            exp neko_less.man.manpages
        endsubsys
    endimage
    image opt
        id "Optional"
        version 1
        order 9999
        subsys src
            id "original source code"
            replaces self
            exp neko_less.opt.src
        endsubsys
        subsys relnotes
            id "release notes"
            replaces self
            exp neko_less.opt.relnotes
        endsubsys
        subsys dist
            id "distribution files"
            replaces self
            exp neko_less.opt.dist
        endsubsys
    endimage
endproduct
