!!!-----------------------------------------------------------------------
!!! project : daisy
!!! program : hfqmc_config
!!!           hfqmc_setup_array
!!!           hfqmc_selfer_init
!!!           hfqmc_solver_init
!!!           hfqmc_final_array
!!! source  : hfqmc_stream.f90
!!! type    : subroutines
!!! author  : li huang (email:lihuang.dmft@gmail.com)
!!! history : 01/07/2006 by li huang (created)
!!!           08/17/2015 by li huang (last modified)
!!! purpose : initialize and finalize the Hirsch-Fye quantum Monte Carlo
!!!           (HFQMC) quantum impurity solver and dynamical mean field
!!!           theory (DMFT) self-consistent engine
!!! status  : unstable
!!! comment :
!!!-----------------------------------------------------------------------

!!>>> hfqmc_config: setup key parameters for Hirsch-Fye quantum Monte
!!>>> Carlo quantum impurity solver and dynamical mean field theory kernel
  subroutine hfqmc_config()
     use parser, only : p_create, p_parse, p_get, p_destroy
     use mmpi, only : mp_bcast, mp_barrier

     use control ! ALL

     implicit none

! local variables
! used to check whether the input file (solver.hfqmc.in) exists
     logical :: exists

!!========================================================================
!!>>> setup general control flags                                      <<<
!!========================================================================
     isscf  = 2               ! non-self-consistent (1) or self-consistent mode (2)
     issun  = 2               ! without symmetry    (1) or with symmetry   mode (2)
     isspn  = 1               ! spin projection, PM (1) or AFM             mode (2)
     isbin  = 2               ! without binning     (1) or with binning    mode (2)
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

!!========================================================================
!!>>> setup common variables for quantum impurity model                <<<
!!========================================================================
     nband  = 1               ! number of correlated bands
     nspin  = 2               ! number of spin projection
     norbs  = nspin*nband     ! number of correlated orbitals (= nband * nspin)
     niter  = 20              ! maximum number of DMFT + HFQMC self-consistent iterations
!-------------------------------------------------------------------------
     Uc     = 4.00_dp         ! Uc: intraorbital Coulomb interaction
     Jz     = 0.00_dp         ! Jz: Hund's exchange interaction in z axis (Jz = Js = Jp = J)
!-------------------------------------------------------------------------
     mune   = 2.00_dp         ! chemical potential or fermi level
     beta   = 8.00_dp         ! inversion of temperature
     part   = 0.50_dp         ! coupling parameter t for Hubbard model
     alpha  = 0.70_dp         ! mixing parameter for self-consistent engine
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

!!========================================================================
!!>>> setup common variables for quantum impurity solver               <<<
!!========================================================================
     mstep  = 16              ! maximum number of delayed update steps
     mfreq  = 8193            ! maximum number of matsubara frequency
!-------------------------------------------------------------------------
     nsing  = (norbs-1)*nband ! number of auxiliary ising-like fields
     ntime  = 64              ! number of time slice
     ntherm = 100             ! maximum number of thermalization steps
     nsweep = 240000          ! maximum number of quantum Monte Carlo sampling steps
     nclean = 100             ! number of steps for restart calculation from scratch
     ncarlo = 10              ! number of steps for record accepted measurement
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! read in input file if possible, only master node can do it
     if ( myid == master ) then
         exists = .false.

! inquire file status: solver.hfqmc.in
         inquire (file = 'solver.hfqmc.in', exist = exists)

! read in parameters, default setting should be overrided
         if ( exists .eqv. .true. ) then
! create the file parser
             call p_create()

! parse the config file
             call p_parse('solver.hfqmc.in')

! extract parameters
             call p_get('isscf' , isscf )
             call p_get('issun' , issun )
             call p_get('isspn' , isspn )
             call p_get('isbin' , isbin )

             call p_get('nband' , nband )
             call p_get('nspin' , nspin )
             call p_get('norbs' , norbs )
             call p_get('niter' , niter )

             call p_get('Uc'    , Uc    )
             call p_get('Jz'    , Jz    )

             call p_get('mune'  , mune  )
             call p_get('beta'  , beta  )
             call p_get('part'  , part  )
             call p_get('alpha' , alpha )

             call p_get('mstep' , mstep )
             call p_get('mfreq' , mfreq )

             call p_get('nsing' , nsing )
             call p_get('ntime' , ntime )
             call p_get('ntherm', ntherm)
             call p_get('nsweep', nsweep)
             call p_get('nclean', nclean)
             call p_get('ncarlo', ncarlo)

! destroy the parser
             call p_destroy()
         endif ! back if ( exists .eqv. .true. ) block
     endif ! back if ( myid == master ) block

! since config parameters may be updated in master node, it is important
! to broadcast config parameters from root to all children processes
# if defined (MPI)

     call mp_bcast( isscf , master )
     call mp_bcast( issun , master )
     call mp_bcast( isspn , master )
     call mp_bcast( isbin , master )
     call mp_barrier()

     call mp_bcast( nband , master )
     call mp_bcast( nspin , master )
     call mp_bcast( norbs , master )
     call mp_bcast( niter , master )
     call mp_barrier()

     call mp_bcast( Uc    , master )
     call mp_bcast( Jz    , master )
     call mp_barrier()

     call mp_bcast( mune  , master )
     call mp_bcast( beta  , master )
     call mp_bcast( part  , master )
     call mp_bcast( alpha , master )
     call mp_barrier()

     call mp_bcast( mstep , master )
     call mp_bcast( mfreq , master )
     call mp_barrier()

     call mp_bcast( nsing , master )
     call mp_bcast( ntime , master )
     call mp_bcast( ntherm, master )
     call mp_bcast( nsweep, master )
     call mp_bcast( nclean, master )
     call mp_bcast( ncarlo, master )
     call mp_barrier()

# endif  /* MPI */

     return
  end subroutine hfqmc_config

!!>>> hfqmc_setup_array: allocate memory for global variables and then
!!>>> initialize them
  subroutine hfqmc_setup_array()
     use context ! ALL

     implicit none

! allocate memory for context module
     call hfqmc_allocate_memory_core()
     call hfqmc_allocate_memory_umat()
     call hfqmc_allocate_memory_base()

     return
  end subroutine hfqmc_setup_array

!!>>> hfqmc_selfer_init: initialize the Hirsch-Fye quantum Monte Carlo
!!>>> quantum impurity solver plus the dynamical mean field theory
!!>>> self-consistent engine
  subroutine hfqmc_selfer_init()
     use constants, only : dp, zero, one, two, pi, czi, czero, mytmp
     use mmpi, only : mp_bcast, mp_barrier

     use control, only : norbs
     use control, only : mfreq
     use control, only : ntime
     use control, only : beta
     use control, only : myid, master
     use context, only : tmesh, rmesh
     use context, only : symm, eimp
     use context, only : wssf

     implicit none

! local variables
! loop index
     integer  :: i
     integer  :: j
     integer  :: k

! dummy variables
     real(dp) :: r1
     real(dp) :: r2
     real(dp) :: i1
     real(dp) :: i2

     real(dp) :: rtmp

! used to check whether the input file (solver.wss.in or solver.eimp.in) exists
     logical  :: exists

! build imaginary time tau mesh: tmesh
     call s_linspace_d(zero, beta, ntime, tmesh)

! build matsubara frequency mesh: rmesh
     call s_linspace_d(pi / beta, (two * mfreq - one) * (pi / beta), mfreq, rmesh)

! build initial bath weiss's function at non-interaction limit
     do i=1,norbs
         do j=1,mfreq
             wssf(j,i) = ( czi * two ) * ( rmesh(j) - sqrt( rmesh(j)**2 + one ) )
         enddo ! over j={1,mfreq} loop
     enddo ! over i={1,norbs} loop

! read in initial bath weiss's function if available
!-------------------------------------------------------------------------
     if ( myid == master ) then ! only master node can do it
         exists = .false.

! inquire about file's existence
         inquire(file = 'solver.wss.in', exist = exists)

! find input file: solver.wss.in, read it
         if ( exists .eqv. .true. ) then

             wssf = czero ! reset it to zero

! read in bath weiss's function from solver.wss.in
             open(mytmp, file='solver.wss.in', form='formatted', status='unknown')
             do i=1,norbs
                 do j=1,mfreq
                     read(mytmp,*) k, rtmp, r1, i1, r2, i2
                     wssf(j,i) = dcmplx(r1,i1)
                 enddo ! over j={1,mfreq} loop
                 read(mytmp,*) ! skip two lines
                 read(mytmp,*)
             enddo ! over i={1,norbs} loop
             close(mytmp)

         endif ! back if ( exists .eqv. .true. ) block
     endif ! back if ( myid == master ) block

! write out the bath weiss's function
     if ( myid == master ) then ! only master node can do it
         call hfqmc_dump_wssf(rmesh, wssf)
     endif ! back if ( myid == master ) block

! since the bath weiss's function may be updated in master node, it is
! important to broadcast it from root to all children processes
# if defined (MPI)

! broadcast data
     call mp_bcast(wssf, master)

! block until all processes have reached here
     call mp_barrier()

# endif  /* MPI */

! setup initial symm
     symm = 1

! setup initial eimp
     eimp = zero

! read in impurity level and orbital symmetry if available
!-------------------------------------------------------------------------
     if ( myid == master ) then ! only master node can do it
         exists = .false.

! inquire about file's existence
         inquire(file = 'solver.eimp.in', exist = exists)

! find input file: solver.eimp.in, read it
         if ( exists .eqv. .true. ) then

! read in impurity level from solver.eimp.in
             open(mytmp, file='solver.eimp.in', form='formatted', status='unknown')
             do i=1,norbs
                 read(mytmp,*) k, eimp(i), symm(i)
             enddo ! over i={1,norbs} loop
             close(mytmp)

         endif ! back if ( exists .eqv. .true. ) block
     endif ! back if ( myid == master ) block

! broadcast eimp and symm from master node to all children nodes
# if defined (MPI)

! broadcast data
     call mp_bcast(eimp, master)

! broadcast data
     call mp_bcast(symm, master)

! block until all processes have reached here
     call mp_barrier()

# endif  /* MPI */

     return
  end subroutine hfqmc_selfer_init

!!>>> hfqmc_solver_init: initialize the Hirsch-Fye quantum Monte Carlo
!!>>> quantum impurity solver
  subroutine hfqmc_solver_init()
     use constants, only : dp, zero, one, two, half
     use spring, only : spring_sfmt_init, spring_sfmt_stream

     use control, only : nband, norbs
     use control, only : nsing, ntime
     use control, only : Uc, Jz
     use control, only : beta
     use control, only : myid, master
     use context, only : pmat, umat, lmat, imat, smat
     use context, only : symm, tmesh, unity
     use context, only : wtau, wssf

     implicit none

! local variables
! loop index
     integer  :: i
     integer  :: j
     integer  :: k
     integer  :: m

! system time since 1970, Jan 1, used to generate the random number seed
     integer  :: system_time

! random number seed for twist generator
     integer  :: stream_seed

! real(dp) dummy variable
     real(dp) :: raux

! \delta \tau
     real(dp) :: deltau

! evaluate $\delta \tau$
     deltau = beta / real(ntime)

! setup matrixes, only for safety
     pmat = 0

     umat = zero
     lmat = zero

     imat = zero
     smat = zero

     unity = zero

!>>> step 1, init random number generator
     call system_clock(system_time)
     stream_seed = abs( system_time - ( myid * 1981 + 2008 ) * 951049 )
     call spring_sfmt_init(stream_seed)

!>>> step 2, build identity matrix
     call s_identity_d(ntime, unity)

!>>> step 3, build smat, $\sigma$, Pauli matrix
!-------------------------------------------------------------------------
! consider a 3-band model, norbs = 6
!-------------------------------------------------------------------------
! i = 1, j = 2, k = 1,  smat(1, 1) = 1.0, smat(2, 1) = -1.0
! i = 1, j = 3, k = 2,  smat(1, 2) = 1.0, smat(3, 2) = -1.0
! i = 1, j = 4, k = 3,  smat(1, 3) = 1.0, smat(4, 3) = -1.0
! i = 1, j = 5, k = 4,  smat(1, 4) = 1.0, smat(5, 4) = -1.0
! i = 1, j = 6, k = 5,  smat(1, 5) = 1.0, smat(6, 5) = -1.0
! i = 2, j = 3, k = 6,  smat(2, 6) = 1.0, smat(3, 6) = -1.0
! i = 2, j = 4, k = 7,  smat(2, 7) = 1.0, smat(4, 7) = -1.0
! i = 2, j = 5, k = 8,  smat(2, 8) = 1.0, smat(5, 8) = -1.0
! i = 2, j = 6, k = 9,  smat(2, 9) = 1.0, smat(6, 9) = -1.0
! i = 3, j = 4, k = 10, smat(3,10) = 1.0, smat(4,10) = -1.0
! i = 3, j = 5, k = 11, smat(3,11) = 1.0, smat(5,11) = -1.0
! i = 3, j = 6, k = 12, smat(3,12) = 1.0, smat(6,12) = -1.0
! i = 4, j = 5, k = 13, smat(4,13) = 1.0, smat(5,13) = -1.0
! i = 4, j = 6, k = 14, smat(4,14) = 1.0, smat(6,14) = -1.0
! i = 5, j = 6, k = 15, smat(5,15) = 1.0, smat(6,15) = -1.0
!-------------------------------------------------------------------------
!    |   1    2    3    4    5    6
!-------------------------------------------------------------------------
!  1 |   +    -
!  2 |   +         -
!  3 |   +              -
!  4 |   +                   -
!  5 |   +                        -
!  6 |        +    -
!  7 |        +         -
!  8 |        +              -
!  9 |        +                   -
! 10 |             +    -
! 11 |             +         -
! 12 |             +              -
! 13 |                  +    -
! 14 |                  +         -
! 15 |                       +    -
!-------------------------------------------------------------------------
     k = 0
     do i=1,norbs-1
         do j=i+1,norbs
             k = k + 1
             smat(i,k) =  one
             smat(j,k) = -one
         enddo ! over j={i+1,norbs} loop
     enddo ! over i={1,norbs-1} loop

!>>> step 4, build pmat, orbital pointer matrix
! first entry (1-nsing) is which pseudo spin flips, and the second entry
! (1-2) corresponds to 1 to ferro-coupling (+), and 2 to antiferro (-)
!-------------------------------------------------------------------------
! consider a 3-band model, norbs = 6
!-------------------------------------------------------------------------
! k = 1   |  pmat( 1,1) = 1, pmat( 1,2) = 2
! k = 2   |  pmat( 2,1) = 1, pmat( 2,2) = 3
! k = 3   |  pmat( 3,1) = 1, pmat( 3,2) = 4
! k = 4   |  pmat( 4,1) = 1, pmat( 4,2) = 5
! k = 5   |  pmat( 5,1) = 1, pmat( 5,2) = 6
! k = 6   |  pmat( 6,1) = 2, pmat( 6,2) = 3
! k = 7   |  pmat( 7,1) = 2, pmat( 7,2) = 4
! k = 8   |  pmat( 8,1) = 2, pmat( 8,2) = 5
! k = 9   |  pmat( 9,1) = 2, pmat( 9,2) = 6
! k = 10  |  pmat(10,1) = 3, pmat(10,2) = 4
! k = 11  |  pmat(11,1) = 3, pmat(11,2) = 5
! k = 12  |  pmat(12,1) = 3, pmat(12,2) = 6
! k = 13  |  pmat(13,1) = 4, pmat(13,2) = 5
! k = 14  |  pmat(14,1) = 4, pmat(14,2) = 6
! k = 15  |  pmat(15,1) = 5, pmat(15,2) = 6
!-------------------------------------------------------------------------
     k = 0
     do i=1,norbs-1
         do j=i+1,norbs
             k = k + 1
             pmat(k,1) = i
             pmat(k,2) = j
         enddo ! over j={i+1,norbs} loop
     enddo ! over i={1,norbs-1} loop

!>>> step 5, build umat, Coulomb repulsion parameter
!-------------------------------------------------------------------------
! consider a 3-band model, norbs = 6
!-------------------------------------------------------------------------
! | up >, m = 1, index = 1
! | up >, m = 2, index = 2
! | up >, m = 3, index = 3
! | dn >, m = 1, index = 4
! | dn >, m = 2, index = 5
! | dn >, m = 3, index = 6
!-------------------------------------------------------------------------
! rules:                                        A     B     C      D
! (1) m_{i}  = m_{j}, s_{i}  = s_{j}, U_{i,j} = 0     0     0      0
! (2) m_{i}  = m_{j}, s_{i} != s_{j}, U_{i,j} = U+J   U     U      U
! (3) m_{i} != m_{j}, s_{i}  = s_{j}, U_{i,j} = U-J   U     U-3J   V-J
! (4) m_{i} != m_{j}, s_{i} != s_{j}, U_{i,j} = U     U-J   U-2J   V
! rules A: K. Haule's QMC code
! rules B: V. Oudovenko's QMC code
! rules C: A. Poteryaev's LDA+DMFT code
! rules D: general choice
!-------------------------------------------------------------------------
! symbols:
! U: intra-orbital Coulomb repulsion
! V: inter-orbital Coulomb repulsion, for t2g system, V = U - 2J
! J: Hund exchange term
! \tlide{J}: pair-hopping term, often be neglected.
!-------------------------------------------------------------------------
!  i   j   k    state                            U_{k}
!-------------------------------------------------------------------------
!  1   2   1   | up     ; up     ;        ; >    U-J     U       U-3J
!  1   3   2   | up     ;        ; up     ; >    U-J     U       U-3J
!  1   4   3   | up, dn ;        ;        ; >    U+J     U       U
!  1   5   4   | up     ;     dn ;        ; >    U       U-J     U-2J
!  1   6   5   | up     ;        ;     dn ; >    U       U-J     U-2J
!  2   3   6   |        ; up     ; up     ; >    U-J     U       U-3J
!  2   4   7   |     dn ; up     ;        ; >    U       U-J     U-2J
!  2   5   8   |        ; up, dn ;        ; >    U+J     U       U
!  2   6   9   |        ; up     ;     dn ; >    U       U-J     U-2J
!  3   4  10   |     dn ;        ; up     ; >    U       U-J     U-2J
!  3   5  11   |        ;     dn ; up     ; >    U       U-J     U-2J
!  3   6  12   |        ;        ; up, dn ; >    U+J     U       U
!  4   5  13   |     dn ;     dn ;        ; >    U-J     U       U-3J
!  4   6  14   |     dn ;        ;     dn ; >    U-J     U       U-3J
!  5   6  15   |        ;     dn ;     dn ; >    U-J     U       U-3J
!-------------------------------------------------------------------------

! applying rules A:
!<     k = 0
!<     do i=1,norbs-1
!<         do j=i+1,norbs
!<             k = k + 1
!<             if ( i <= nband .and. j > nband ) then
!<                 m = j - nband
!<                 if ( m == i ) then
!<                     umat(k) = Uc + Jz
!<                 else
!<                     umat(k) = Uc
!<                 endif ! back if ( m == i ) block
!<             else
!<                 umat(k) = Uc - Jz
!<             endif ! back if ( i <= nband .and. j > nband ) block
!<         enddo ! over j={i+1,norbs} loop
!<     enddo ! over i={1,norbs-1} loop
!<
! applying rules B:
!<     k = 0
!<     do i=1,norbs-1
!<         do j=i+1,norbs
!<             k = k + 1
!<             if ( i <= nband .and. j > nband ) then
!<                 m = j - nband
!<                 if ( m == i ) then
!<                     umat(k) = Uc
!<                 else
!<                     umat(k) = Uc - Jz
!<                 endif ! back if ( m == i ) block
!<             else
!<                 umat(k) = Uc
!<             endif ! back if ( i <= nband .and. j > nband ) block
!<         enddo ! over j={i+1,norbs} loop
!<     enddo ! over i={1,norbs-1} loop
!<
! applying rules C:
     k = 0
     do i=1,norbs-1
         do j=i+1,norbs
             k = k + 1
             if ( i <= nband .and. j > nband ) then
                 m = j - nband
                 if ( m == i ) then
                     umat(k) = Uc
                 else
                     umat(k) = Uc - 2.0_dp * Jz
                 endif ! back if ( m == i ) block
             else
                 umat(k) = Uc - 3.0_dp * Jz
             endif ! back if ( i <= nband .and. j > nband ) block
         enddo ! over j={i+1,norbs} loop
     enddo ! over i={1,norbs-1} loop

! additional check for umat
     do i=1,nsing
         if ( umat(i) < zero ) then
             call s_print_error('hfqmc_solver_init','umat element is negative')
         endif ! back if ( umat(i) < zero ) block
     enddo ! over i={1,nsing} loop

!>>> step 6, build lmat, $\lambda$ matrix
     do i=1,nsing
         raux = exp( deltau * umat(i) / two )
         lmat(i) = log( raux + sqrt( raux * raux - one ) )
     enddo ! over i={1,nsing} loop

!>>> step 7, build imat, ising spin variables
     do j=1,nsing
         do i=1,ntime
             raux = spring_sfmt_stream()
             if ( raux <= half ) then
                 imat(i,j) =  one
             else
                 imat(i,j) = -one
             endif ! back if ( raux <= half ) block
             imat(i,j) = imat(i,j) * lmat(j)
         enddo ! over i={1,ntime} loop
     enddo ! over j={1,nsing} loop

!>>> step 8, and then fourier wssf to wtau
     call hfqmc_fourier_w2t(wssf, wtau)

! symmetrize the bath weiss's function
     call hfqmc_make_symm(symm, wtau)

! inverse the sign of bath weiss's function
     wtau = -wtau

! write out initial bath weiss's function
     if ( myid == master ) then ! only master node can do it
         call hfqmc_dump_wtau(tmesh, wtau)
     endif ! back if ( myid == master ) block

     return
  end subroutine hfqmc_solver_init

!!>>> hfqmc_final_array: garbage collection for this program
  subroutine hfqmc_final_array()
     use context ! ALL

     implicit none

! deallocate memory for context module
     call hfqmc_deallocate_memory_core()
     call hfqmc_deallocate_memory_umat()
     call hfqmc_deallocate_memory_base()

     return
  end subroutine hfqmc_final_array
