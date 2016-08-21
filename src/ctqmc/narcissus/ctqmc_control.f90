!!!-----------------------------------------------------------------------
!!! project : narcissus
!!! program : control    module
!!! source  : ctqmc_control.f90
!!! type    : module
!!! author  : li huang (email:lihuang.dmft@gmail.com)
!!! history : 09/15/2009 by li huang (created)
!!!           08/17/2015 by li huang (last modified)
!!! purpose : define global control parameters for hybridization expansion
!!!           version continuous time quantum Monte Carlo (CTQMC) quantum
!!!           impurity solver and dynamical mean field theory (DMFT) self-
!!!           consistent engine
!!! status  : unstable
!!! comment :
!!!-----------------------------------------------------------------------

  module control
     use constants, only : dp

     implicit none

!!========================================================================
!!>>> character variables                                              <<<
!!========================================================================

! the code name of the current ctqmc impurity solver
     character(len = 09), public, save :: cname = 'NARCISSUS'

!!========================================================================
!!>>> integer variables                                                <<<
!!========================================================================

! control flag: running mode
! if isscf == 1, one-shot non-self-consistent scheme, used in local density
! approximation plus dynamical mean field theory case
! if isscf == 2, self-consistent scheme, used in normal model hamiltonian
! plus dynamical mean field theory case
     integer, public, save :: isscf  = 2

! control flag: symmetry of bands
! if issun == 1, the bands are not symmetrized
! if issun == 2, the bands are symmetrized according to symmetry matrix
     integer, public, save :: issun  = 2

! control flag: symmetry of spin orientation
! if isspn == 1, enforce spin up = spin down
! if isspn == 2, let spin up and spin down states evolve independently
     integer, public, save :: isspn  = 1

! control flag: impurity green's function binning mode
! if isbin == 1, without binning mode
! if isbin == 2, with binning mode
     integer, public, save :: isbin  = 2

! control flag: apply orthogonal polynomial representation to perform measurement
! if isort == 1, use normal representation to measure G(\tau)
! if isort == 2, use legendre polynomial to measure G(\tau)
! if isort == 3, use chebyshev polynomial (the second kind) to measure G(\tau)
! if isort == 4, use normal representation to measure G(\tau) and F(\tau)
! if isort == 5, use legendre polynomial to measure G(\tau) and F(\tau)
! if isort == 6, use chebyshev polynomial (the second kind) to measure G(\tau) and F(\tau)
!
! note: if isort \in [1,3], we use ctqmc_make_hub1() to calculate the self
! energy function, or else we use ctqmc_make_hub2().
!
! note: isort \in [4, 5, 6] is not compatible with isscr = 2. in other
! words, you can not set isort = 4, 5, or 6 when isscr = 2.
!
! note: as for the kernel polynomial representation, the default dirichlet
! kernel is applied automatically. if you want to choose the other kernel,
! please check the ctqmc_make_gtau() subroutine in ctqmc_record.f90.
     integer, public, save :: isort  = 1

! control flag: whether we measure the charge or spin susceptibility
! we just use the following algorithm to judge which susceptibility should
! be calculated:
! (a) issus is converted to a binary representation at first. for example,
! 10_10 is converted to 1010_2, 15_10 is converted to 1111_2, etc.
!
! (b) then we examine the bits. if it is 1, then we do the calculation.
! if it is 0, then we ignore the calculation. for example, we just use the
! second bit (from right side to left side) to represent the calculation
! of spin-spin correlation function. so, if issus is 10_10 (1010_2), we
! will calculate the spin-spin correlation function. if issus is 13_10
! (1101_2), we will not calculate it since the second bit is 0.
!
! the following are the definitions of bit representation:
! if p == 1, do nothing
! if p == 2, calculate spin-spin correlation function (time space)
! if p == 3, calculate orbital-orbital correlation function (time space)
! if p == 4, calculate spin-spin correlation function (frequency space)
! if p == 5, calculate orbital-orbital correlation function (frequency space)
! if p == 6, calculate < k^2 > - < k >^2
! if p == 7, calculate fidelity susceptibility matrix
! if p == 8, reserved
! if p == 9, reserved
!
! example:
!   ( 1 1 1 0 1 0 1 0 1)_2
! p = 9 8 7 6 5 4 3 2 1
!
! note: p = 4 and p = 5 are not implemented so far.
     integer, public, save :: issus  = 1

! control flag: whether we measure the high order correlation function
! we just use the following algorithm to judge which correlation function
! should be calculated:
! (a) isvrt is converted to a binary representation at first. for example,
! 10_10 is converted to 1010_2, 15_10 is converted to 1111_2, etc.
!
! (b) then we examine the bits. if it is 1, then we do the calculation.
! if it is 0, then we ignore the calculation. for example, we just use the
! second bit (from right side to left side) to represent the calculation
! of two-particle green's function. so, if isvrt is 10_10 (1010_2), we
! will calculate the two-particle green's function. if isvrt is 13_10
! (1101_2), we will not calculate it since the second bit is 0.
!
! the following are the definitions of bit representation:
! if p == 1, do nothing
! if p == 2, calculate two-particle green's function and vertex function
! if p == 3, calculate two-particle green's function and vertex function
! if p == 4, calculate particle-particle pair susceptibility
! if p == 5, reserved
! if p == 6, reserved
! if p == 7, reserved
! if p == 8, reserved
! if p == 9, reserved
!
! example:
!   ( 1 1 1 0 1 0 1 0 1)_2
! p = 9 8 7 6 5 4 3 2 1
!
! note: if p == 2 or p == 3, both the two-particle green's and vertex
! functions are computed, but using two different algorithms. you can not
! set them to 1 at the same time. in order words, if you set the bit at
! p == 2 to 1, then the bit at p == 3 must be 0, and vice versa.
!
! note: if p == 2, the traditional algorithm is used. if p == 3, the
! improved estimator for two-particle green's function is used.
!
! note: the isvrt parameter has nothing to do with the isort parameter,
! but when p = 3 bit is set to be 1, the prefactor for improved estimator
! (please see 'pref' in ctqmc_context.f90) should be calculated and used
! to improve the computational accuracy. on the other hand, if isort >= 4,
! the same prefactor will be calculated as well. you can not setup isscr
! = 2 at this time.
     integer, public, save :: isvrt  = 1

! control flag: hamiltonian model need to be solved
! if isscr == 1, normal model
! if isscr == 2, holstein-hubbard model
! if isscr == 3, dynamic screening, palsmon pole model
! if isscr == 4, dynamic screening, ohmic model
! if isscr ==99, dynamic screening, realistic materials
!
! note: when isscr == 1, lc and wc are ignored. when isscr == 2, lc means
! the electron-phonon coupling constant \lambda, and wc phonon vibration
! frequency \omega_{0}. when isscr == 3, lc and wc just mean the control
! parameters \lambda and \omega^{'}, respectively. when isscr == 4, lc
! and wc just mean the control parameters \alpha and \omega_{c}, respectively.
! when isscr == 99, wc is ignored and lc means the shift for interaction
! matrix and chemical potential.
!
! note: when isscr = 1, 3, 4, or 99, you can use the combination of improved
! estimator and orthogonal polynomial technology to measure G and \Sigma.
! in other words, in such cases, isort can be any values (isort \in [1,6]).
! on the other hand, when isscr = 2, the orthogonal polynomial technology
! is useful as well (G is accurate), but the improved estimator for \Sigma
! and vertex function does not work any more! so in this case, you can not
! setup isort to 4, 5, or 6.
!
! note: isscr = 2 is not compatible with the p = 3 bit of isvrt. so if you
! want to study the two-particle green's function and vertex function of
! the holstein-hubbard model, you can only set the p = 2 bit of isvrt.
     integer, public, save :: isscr  = 1

!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! number of correlated bands
     integer, public, save :: nband  = 1

! number of spin projection
     integer, public, save :: nspin  = 2

! number of correlated orbitals (= nband * nspin)
     integer, public, save :: norbs  = 2

! number of atomic states (= 2**norbs)
     integer, public, save :: ncfgs  = 4

! maximum number of continuous time quantum Monte Carlo quantum impurity
! solver plus dynamical mean field theory self-consistent iterations
     integer, public, save :: niter  = 20

!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! maximum order for legendre polynomial
     integer, public, save :: lemax  = 32

! number of mesh points for legendre polynomial in [-1,1] range
     integer, public, save :: legrd  = 20001

! maximum order for chebyshev polynomial
     integer, public, save :: chmax  = 32

! number of mesh points for chebyshev polynomial in [-1,1] range
     integer, public, save :: chgrd  = 20001

!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! maximum perturbation expansion order
     integer, public, save :: mkink  = 1024

! maximum number of matsubara frequency point
     integer, public, save :: mfreq  = 8193

!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! number of matsubara frequency for the two-particle green's function
     integer, public, save :: nffrq  = 32

! number of bosonic frequncy for the two-particle green's function
     integer, public, save :: nbfrq  = 8

! number of matsubara frequency sampling by continuous time quantum Monte
! Carlo quantum impurity solver
!
! note: the rest (mfreq - nfreq + 1 points) values are evaluated by using
! Hubbard-I approximation
     integer, public, save :: nfreq  = 128

! number of imaginary time slice sampling by continuous time quantum Monte
! Carlo quantum impurity solver
     integer, public, save :: ntime  = 1024

! flip period for spin up and spin down states
!
! note: care must be taken to prevent the system from being trapped in a
! state which breaks a symmetry of local hamiltonian when it should not
! be. to avoid unphysical trapping, we introduce "flip" moves, which
! exchange the operators corresponding, for example, to up and down spins
! in a given orbital.
!
! note: in this code, nowadays the following flip schemes are supported
!     if cflip = 1, flip inter-orbital spins randomly;
!     if cflip = 2, flip intra-orbital spins one by one;
!     if cflip = 3, flip intra-orbital spins globally.
! here cflip is an internal variable.
!
! note: we use the sign of nflip to control flip schemes
!     if nflip = 0, means infinite long period to do flip
!     if nflip > 0, combine cflip = 2 (80%) and cflip = 3 (20%)
!     if nflip < 0, combine cflip = 1 (80%) and cflip = 3 (20%)
!
! note: if nflip /= 0, the absolute value of nflip is the flip period
!
! note: when cflip = 1, the symmetry of all orbitals must be taken into
! consideration, otherwise the code may be trapped by a deadlock.
     integer, public, save :: nflip  = 20000

! maximum number of thermalization steps
     integer, public, save :: ntherm = 200000

! maximum number of quantum Monte Carlo sampling steps
     integer, public, save :: nsweep = 20000000

! output period for quantum impurity solver
     integer, public, save :: nwrite = 2000000

! clean update period for quantum impurity solver
     integer, public, save :: nclean = 100000

! how often to sampling the gmat and paux (nmat and nnmat)
!
! note: the measure periods for schi, sschi, ochi, oochi, g2_re, g2_im,
! h2_re, h2_im, ps_re, and ps_im are also controlled by nmonte parameter.
     integer, public, save :: nmonte = 10

! how often to sampling the gtau and prob
!
! note: the measure period for ftau is also controlled by ncarlo parameter.
     integer, public, save :: ncarlo = 10

!!========================================================================
!!>>> real variables                                                   <<<
!!========================================================================

! average Coulomb interaction
     real(dp), public, save :: U     = 4.00_dp

! intraorbital Coulomb interaction
     real(dp), public, save :: Uc    = 4.00_dp

! interorbital Coulomb interaction, Uv = Uc - 2 * Jz for t2g system
     real(dp), public, save :: Uv    = 4.00_dp

! Hund's exchange interaction in z axis (Jz = Js = Jp = J)
     real(dp), public, save :: Jz    = 0.00_dp

! spin-flip term
     real(dp), public, save :: Js    = 0.00_dp

! pair-hopping term
     real(dp), public, save :: Jp    = 0.00_dp

! strength of dynamical screening effect ( or electron-phonon coupling )
     real(dp), public, save :: lc    = 1.00_dp

! screening frequency ( or frequency for einstein phonons )
     real(dp), public, save :: wc    = 1.00_dp

!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! chemical potential or fermi level
!
! note: it should/can be replaced with eimp
     real(dp), public, save :: mune  = 2.00_dp

! inversion of temperature
     real(dp), public, save :: beta  = 8.00_dp

! coupling parameter t for Hubbard model
     real(dp), public, save :: part  = 0.50_dp

! mixing parameter for dynamical mean field theory self-consistent engine
     real(dp), public, save :: alpha = 0.70_dp

!!========================================================================
!!>>> MPI related common variables                                     <<<
!!========================================================================

! number of processors: default value 1
     integer, public, save :: nprocs = 1

! the id of current process: default value 0
     integer, public, save :: myid   = 0

! denote as the controller process: default value 0
     integer, public, save :: master = 0

! the id of current process in cartesian topology (cid == myid)
     integer, public, save :: cid    = 0

! the x coordinates of current process in cartesian topology
     integer, public, save :: cx     = 0

! the y coordinates of current process in cartesian topology
     integer, public, save :: cy     = 0

  end module control
