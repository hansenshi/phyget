#!/bin/bash
#

chaa () {
  mv $1.xml `echo $1 | tr [a-z] [A-Z]`.xml
}

chaa $1
