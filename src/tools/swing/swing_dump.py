#!/usr/bin/env python
""" this module provide basis dump function for hibiscus code """

from scipy import *
from scipy import interpolate

# print the running header to the screen
def swing_print_header():
    """ to display the header for hibiscus code """

    print '  HIBISCUS'
    print '  >>> A Stochastic Analytic Continuation Code for Self-Energy Data'
    print

    print '  version: 2011.08.18T            '
    print '  develop: by li huang, CAEP & IOP'
    print '  support: huangli712@yahoo.com.cn'
    print '  license: GPL2 and later versions'
    print

# print the final footer to the screen
def swing_print_footer(tot_time):
    """ to display the footer for hibiscus code """

    print '  HIBISCUS >>> total time spent:', tot_time, 's'

    print '  HIBISCUS >>> I am tired and want to go to bed. Bye!'
    print '  HIBISCUS >>> ending'

# dump the historic command to hist.dat file
def swing_dump_hist(argv):
    """ to record the command history """

    fs = open('hist.dat', 'a')
    for cmd in argv:
        print >> fs, cmd,
    print >> fs

# dump the parameter list and explanations to the screen
def swing_dump_keys(params):
    """ to display the parameter lists """

    print '  HIBISCUS >>> parameters list:'
    for var in params.keys():
        print '%s %-8s %s %-6s %s' % ('   ', var, ':', params[var][0], params[var][1])
    print

# calculate dynamically the self-energy function on real axis, and then
# write them into the sigr.out file
def swing_dump_sigr(om, vary, fixed, gweigh, gwfix, rfunc, sinfty):
    """ dump the final self-energy function in real axis """

    # zsum is used to store the self-energy function on real axis
    zsum = []
    for im in range(len(om)):
        zsum.append(0.0)

    # calculate self-energy function on real logarithm axis
    fs = open('sigr.out', 'w')
    for im in range(len(om)):
        for i in range(len(gweigh)):
            zsum[im] += rfunc[vary[i]-1,im] * gweigh[i]
        for i in range(len(fixed)):
            zsum[im] += rfunc[fixed[i]-1,im] * gwfix[i]
        print >> fs, '%16.8f %16.8f %16.8f' % (om[im], zsum[im].real+sinfty, zsum[im].imag)

    # build real symmetry linear axis
    step = 0.04
    nfrq = 400
    new_om = []
    for im in range(2*nfrq+1):
        new_om.append(step*(im - nfrq))

    # interpolate self-energy function from om mesh to new_om mesh
    # the results are dumped into sigr_linear.out
    spl_re = interpolate.splrep(om, real(zsum), k=3, s=0.0)
    spl_im = interpolate.splrep(om, imag(zsum), k=3, s=0.0)
    fs = open('sigr_linear.out', 'w')
    for im in range(2*nfrq+1):
        sig_re = interpolate.splev(new_om[im], spl_re, der=0) + sinfty
        sig_im = interpolate.splev(new_om[im], spl_im, der=0)
        print >> fs, '%6d %16.8f %16.8f %16.8f' % (im, new_om[im], sig_re, sig_im)

# dump the positions and weights for modified gaussians over iterations
def swing_dump_gaus(it, gpos, gweigh):
    """ dump the modified gaussian function and their weights """

    fs = open('gaus.'+str(it), 'w')
    for i in range(len(gweigh)):
        print >> fs, '%4d %16.8f %16.8f' % (i, gpos[i], gweigh[i])

# dump the evaluated self-energy function on matsubara axis
def swing_dump_siom(it, iom, vary, fixed, gweigh, gwfix, ifunr, ifuni):
    """ dump the fitted self-energy function in matsubara axis """

    fs = open('siom.'+str(it), 'w')
    for im in range(len(iom)):
        gc = 0j
        for i in range(len(gweigh)):
            gc += (ifunr[vary[i]-1,im]  + 1j * ifuni[vary[i]-1,im]) * gweigh[i]
        for i in range(len(fixed)):
            gc += (ifunr[fixed[i]-1,im] + 1j * ifuni[fixed[i]-1,im]) * gwfix[i]
        print >> fs, '%16.8f %16.8f %16.8f' % (iom[im], gc.real, gc.imag)

# dump the evaluated self-energy function on real axis
def swing_dump_sres(it, om, vary, fixed, gweigh, gwfix, rfunc):
    """ dump the fitted self-energy function in real axis """

    fs = open('sres.'+str(it), 'w')
    for im in range(len(om)):
        zsum = 0.0
        for i in range(len(gweigh)):
            zsum += rfunc[vary[i]-1,im] * gweigh[i]
        for i in range(len(fixed)):
            zsum += rfunc[fixed[i]-1,im] * gwfix[i]
        print >> fs, '%16.8f %16.8f %16.8f' % (om[im], zsum.real, zsum.imag)