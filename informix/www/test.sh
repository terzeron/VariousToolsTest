#!/bin/csh

setenv INFORMIXSQLHOSTS /extra/informix/etc/sqlhosts
setenv INFORMIXSERVER cs_shm
setenv INFORMIXDIR /extra/informix
setenv INFORMIXC gcc
setenv ONCONFIG onconfig
setenv LD_LIBRARY_PATH /usr/lib:/usr/openwin/lib:/extra/informix/lib:/extra/informix/lib/esql
setenv PATH ${PATH}:$INFORMIXDIR/bin

@ count = 1
set command = ""
while ($count <= $#argv) 
  set command = "$command '$argv[$count]'"
  @ count ++
end

exec sh -c "./register $command"
