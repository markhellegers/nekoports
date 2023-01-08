/^\=+$/ {filename=prevline}{prevline=$0}{gsub(/[^[:alnum:]]/, "_", filename)}
/BEGIN CERTIFICATE/, /END CERTIFICATE/ {print > ("certs/" filename ".pem")}
/END CERTIFICATE/ {close ("certs/" filename ".pem")}
