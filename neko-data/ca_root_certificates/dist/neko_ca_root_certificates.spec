product neko_ca_root_certificates
    id "ca_root_certificates 2022.10.11 - certificate data from Mozilla"
    image sw
        id "Software"
        version 1
        order 9999
        subsys eoe default
            id "execution only env"
            replaces self
             prereq (
                neko_openssl.sw.eoe 33 maxint
            )
           exp neko_ca_root_certificates.sw.eoe
        endsubsys
    endimage
    image opt
        id "Optional"
        version 1
        order 9999
        subsys src
            id "original source code"
            replaces self
            exp neko_ca_root_certificates.opt.src
        endsubsys
        subsys relnotes
            id "release notes"
            replaces self
            exp neko_ca_root_certificates.opt.relnotes
        endsubsys
        subsys dist
            id "distribution files"
            replaces self
            exp neko_ca_root_certificates.opt.dist
        endsubsys
    endimage
endproduct
