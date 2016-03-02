#!/bin/bash

##
##
## Introduction
## ============
##
## It is a bash shell script. The purpose of this script is to make symbolic
## links for the executable codes in the bin directory (current directory).
##
## Usage
## =====
##
## ./x_setup.sh
##
## Author
## ======
##
## This shell script is designed, created, implemented, and maintained by
##
## Li Huang // email: lihuang.dmft@gmail.com
##
## History
## =======
##
## 11/10/2014 by li huang (created)
## 02/13/2016 by li huang (last modified)
##
##

# define my own ln function
function make_link {
    name=$(echo $2 | tr '[:lower:]' '[:upper:]')
    if [ -e "$1" ]
    then
        echo "[$name]: found"
        ln -fs $1 $2.x
        echo "[$name]: setup OK"
    fi
}

# loop over the ctqmc components
for component in azalea gardenia narcissus begonia lavender camellia pansy manjushaka
do
    dir=$(echo ../src/ctqmc/$component/ctqmc)
    make_link $dir $component
done

# loop over the hfqmc components
for component in daisy
do
    dir=$(echo ../src/hfqmc/$component/hfqmc)
    make_link $dir $component
done

# loop over the jasmine components
for component in jasmine
do
    dir=$(echo ../src/tools/jasmine/atomic)
    make_link $dir $component
done

# loop over the hibiscus components
for component in entropy
do
    dir=$(echo ../src/tools/hibiscus/entropy/$component)
    make_link $dir $component
done
for component in sac
do
    dir=$(echo ../src/tools/hibiscus/stoch/$component)
    make_link $dir $component
done
for component in mchi mdos mkra mscr msig mstd mtau mups
do
    dir=$(echo ../src/tools/hibiscus/toolbox/$component)
    make_link $dir $component
done
