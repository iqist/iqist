#!/usr/bin/env python

##
##
## Introduction
## ============
##
## Usage
## =====
##
## Author
## ======
##
## This python script is designed, created, implemented, and maintained by
##
## Li Huang // email: huangli712@gmail.com
##
## History
## =======
##
## 11/13/2014 by li huang
##
##

import numpy
import scipy

class p_ctqmc_solver(object):
    """
    """

    def __init__(self, solver):
        """
        """
        pass

    def setp(self, aa):
        """
        """
        self.bb = aa

    def check(self):
        """
        """
        print self.bb

    def write(self):
        """
        """
        pass

if __name__ == '__main__':
    print 'here'
    p = p_ctqmc_solver('azalea')
    p.setp(10)
    p.check()