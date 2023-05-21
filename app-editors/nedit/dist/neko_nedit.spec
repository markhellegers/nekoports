product neko_nedit
    id "nedit-5.7 Nirvana Text Editor"
    image sw
        id "NEdit 5.7 Software"
        version 3
        order 9999
        subsys eoe default
            id "execution only env"
            replaces self
            exp neko_nedit.sw.eoe
        endsubsys
    endimage
    image opt
        id "optional software"
        version 3
        order 9999
        subsys relnotes
            id "release notes"
            replaces self
            exp neko_nedit.opt.relnotes
        endsubsys
        subsys dist
            id "distribution files"
            replaces self
            exp neko_nedit.opt.dist
        endsubsys
        subsys src
            id "original source code and patches"
            replaces self
            exp neko_nedit.opt.src
        endsubsys
        subsys patches
            id "source code patches"
            replaces self
            exp neko_nedit.opt.patches
        endsubsys
    endimage
endproduct
