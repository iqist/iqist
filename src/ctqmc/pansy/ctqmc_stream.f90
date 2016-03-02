!!!-----------------------------------------------------------------------
!!! project : pansy
!!! program : ctqmc_config
!!!           ctqmc_setup_array
!!!           ctqmc_selfer_init
!!!           ctqmc_solver_init
!!!           ctqmc_final_array
!!! source  : ctqmc_stream.f90
!!! type    : subroutines
!!! author  : li huang (email:lihuang.dmft@gmail.com)
!!!           yilin wang (email:qhwyl2006@126.com)
!!! history : 09/16/2009 by li huang (created)
!!!           08/17/2015 by li huang (last modified)
!!! purpose : initialize and finalize the hybridization expansion version
!!!           continuous time quantum Monte Carlo (CTQMC) quantum impurity
!!!           solver and dynamical mean field theory (DMFT) self-consistent
!!!           engine
!!! status  : unstable
!!! comment :
!!!-----------------------------------------------------------------------

!!>>> ctqmc_config: setup key parameters for continuous time quantum Monte
!!>>> Carlo quantum impurity solver and dynamical mean field theory kernel
  subroutine ctqmc_config()
     use parser, only : p_create, p_parse, p_get, p_destroy
     use mmpi, only : mp_bcast, mp_barrier

     use control ! ALL

     implicit none

! local variables
! used to check whether the input file (solver.ctqmc.in) exists
     logical :: exists

!!========================================================================
!!>>> setup general control flags                                      <<<
!!========================================================================
     isscf  = 2            ! non-self-consistent (1) or self-consistent mode (2)
     issun  = 2            ! without symmetry    (1) or with symmetry   mode (2)
     isspn  = 1            ! spin projection, PM (1) or AFM             mode (2)
     isbin  = 2            ! without binning     (1) or with binning    mode (2)
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

!!========================================================================
!!>>> setup common variables for quantum impurity model                <<<
!!========================================================================
     nband  = 1            ! number of correlated bands
     nspin  = 2            ! number of spin projection
     norbs  = nspin*nband  ! number of correlated orbitals (= nband * nspin)
     ncfgs  = 2**norbs     ! number of atomic states
     niter  = 20           ! maximum number of DMFT + CTQMC self-consistent iterations
!-------------------------------------------------------------------------
     U      = 4.00_dp      ! U : average Coulomb interaction
     Uc     = 4.00_dp      ! Uc: intraorbital Coulomb interaction
     Uv     = 4.00_dp      ! Uv: interorbital Coulomb interaction, Uv = Uc - 2 * Jz for t2g system
     Jz     = 0.00_dp      ! Jz: Hund's exchange interaction in z axis (Jz = Js = Jp = J)
     Js     = 0.00_dp      ! Js: spin-flip term
     Jp     = 0.00_dp      ! Jp: pair-hopping term
!-------------------------------------------------------------------------
     mune   = 2.00_dp      ! chemical potential or fermi level
     beta   = 8.00_dp      ! inversion of temperature
     part   = 0.50_dp      ! coupling parameter t for Hubbard model
     alpha  = 0.70_dp      ! mixing parameter for self-consistent engine
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

!!========================================================================
!!>>> setup common variables for quantum impurity solver               <<<
!!========================================================================
     mkink  = 1024         ! maximum perturbation expansions order
     mfreq  = 8193         ! maximum number of matsubara frequency
!-------------------------------------------------------------------------
     nfreq  = 128          ! maximum number of matsubara frequency sampling by quantum impurity solver
     ntime  = 1024         ! number of time slice
     npart  = 4            ! number of parts that the imaginary time axis is split
     nflip  = 20000        ! flip period for spin up and spin down states
     ntherm = 200000       ! maximum number of thermalization steps
     nsweep = 20000000     ! maximum number of quantum Monte Carlo sampling steps
     nwrite = 2000000      ! output period
     nclean = 100000       ! clean update period
     nmonte = 10           ! how often to sampling the gmat and nmat
     ncarlo = 10           ! how often to sampling the gtau and prob
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! read in input file if possible, only master node can do it
     if ( myid == master ) then
         exists = .false.

! inquire file status: solver.ctqmc.in
         inquire (file = 'solver.ctqmc.in', exist = exists)

! read in parameters, default setting should be overrided
         if ( exists .eqv. .true. ) then
! create the file parser
             call p_create()

! parse the config file
             call p_parse('solver.ctqmc.in')

! extract parameters
             call p_get('isscf' , isscf )
             call p_get('issun' , issun )
             call p_get('isspn' , isspn )
             call p_get('isbin' , isbin )

             call p_get('nband' , nband )
             call p_get('nspin' , nspin )
             call p_get('norbs' , norbs )
             call p_get('ncfgs' , ncfgs )
             call p_get('niter' , niter )

             call p_get('U'     , U     )
             call p_get('Uc'    , Uc    )
             call p_get('Uv'    , Uv    )
             call p_get('Jz'    , Jz    )
             call p_get('Js'    , Js    )
             call p_get('Jp'    , Jp    )

             call p_get('mune'  , mune  )
             call p_get('beta'  , beta  )
             call p_get('part'  , part  )
             call p_get('alpha' , alpha )

             call p_get('mkink' , mkink )
             call p_get('mfreq' , mfreq )

             call p_get('nfreq' , nfreq )
             call p_get('ntime' , ntime )
             call p_get('npart' , npart )
             call p_get('nflip' , nflip )
             call p_get('ntherm', ntherm)
             call p_get('nsweep', nsweep)
             call p_get('nwrite', nwrite)
             call p_get('nclean', nclean)
             call p_get('nmonte', nmonte)
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
     call mp_bcast( ncfgs , master )
     call mp_bcast( niter , master )
     call mp_barrier()

     call mp_bcast( U     , master )
     call mp_bcast( Uc    , master )
     call mp_bcast( Uv    , master )
     call mp_bcast( Jz    , master )
     call mp_bcast( Js    , master )
     call mp_bcast( Jp    , master )
     call mp_barrier()

     call mp_bcast( mune  , master )
     call mp_bcast( beta  , master )
     call mp_bcast( part  , master )
     call mp_bcast( alpha , master )
     call mp_barrier()

     call mp_bcast( mkink , master )
     call mp_bcast( mfreq , master )
     call mp_barrier()

     call mp_bcast( nfreq , master )
     call mp_bcast( ntime , master )
     call mp_bcast( npart , master )
     call mp_bcast( nflip , master )
     call mp_bcast( ntherm, master )
     call mp_bcast( nsweep, master )
     call mp_bcast( nwrite, master )
     call mp_bcast( nclean, master )
     call mp_bcast( nmonte, master )
     call mp_bcast( ncarlo, master )
     call mp_barrier()

# endif  /* MPI */

     return
  end subroutine ctqmc_config

!!>>> ctqmc_setup_array: allocate memory for global variables and then
!!>>> initialize them
  subroutine ctqmc_setup_array()
     use context ! ALL

     implicit none

! allocate memory for context module
     call ctqmc_allocate_memory_clur()
     call ctqmc_allocate_memory_flvr()

     call ctqmc_allocate_memory_mesh()
     call ctqmc_allocate_memory_meat()
     call ctqmc_allocate_memory_umat()
     call ctqmc_allocate_memory_mmat()

     call ctqmc_allocate_memory_gmat()
     call ctqmc_allocate_memory_wmat()
     call ctqmc_allocate_memory_smat()

     return
  end subroutine ctqmc_setup_array

!!>>> ctqmc_selfer_init: initialize the continuous time quantum Monte
!!>>> Carlo quantum impurity solver plus dynamical mean field theory
!!>>> self-consistent engine
  subroutine ctqmc_selfer_init()
     use constants, only : dp, zero, one, two, pi, czi, czero, mytmp
     use mmpi, only : mp_bcast, mp_barrier

     use control, only : norbs, ncfgs
     use control, only : mfreq
     use control, only : ntime
     use control, only : U
     use control, only : mune, beta, part
     use control, only : myid, master
     use context, only : cssoc
     use context, only : tmesh, rmesh
     use context, only : symm, eimp, eigs, naux, saux
     use context, only : hybf

     use m_sect ! ALL
     use m_part ! ALL

     implicit none

! local variables
! loop index
     integer  :: i
     integer  :: j
     integer  :: k
     integer  :: m
     integer  :: n

! version of file 'atom.cix'
     integer  :: ver

! dummy integer variables
     integer  :: j1, j2, j3, j4, j5

! used to check whether the input file (solver.hyb.in or solver.eimp.in
! or atom.cix) exists
     logical  :: exists

! dummy real variables
     real(dp) :: rtmp
     real(dp) :: r1, r2
     real(dp) :: i1, i2

! build imaginary time tau mesh: tmesh
     call s_linspace_d(zero, beta, ntime, tmesh)

! build matsubara frequency mesh: rmesh
     call s_linspace_d(pi / beta, (two * mfreq - one) * (pi / beta), mfreq, rmesh)

! build initial green's function: i * 2.0 * ( w - sqrt(w*w + 1) )
! using the analytical equation at non-interaction limit, and then
! build initial hybridization function using self-consistent condition
     do i=1,mfreq
         call s_identity_z( norbs, hybf(i,:,:) )
         hybf(i,:,:) = hybf(i,:,:) * (part**2) * (czi*two)
         hybf(i,:,:) = hybf(i,:,:) * ( rmesh(i) - sqrt( rmesh(i)**2 + one ) )
     enddo ! over i={1,mfreq} loop

! read in initial hybridization function if available
!-------------------------------------------------------------------------
     if ( myid == master ) then ! only master node can do it
         exists = .false.

! inquire about file's existence
         inquire (file = 'solver.hyb.in', exist = exists)

! find input file: solver.hyb.in, read it
         if ( exists .eqv. .true. ) then

             hybf = czero ! reset it to zero

! read in hybridization function from solver.hyb.in
             open(mytmp, file='solver.hyb.in', form='formatted', status='unknown')
             do i=1,norbs
                 do j=1,mfreq
                     read(mytmp,*) k, rtmp, r1, i1, r2, i2
                     hybf(j,i,i) = dcmplx(r1,i1)
                 enddo ! over j={1,mfreq} loop
                 read(mytmp,*) ! skip two lines
                 read(mytmp,*)
             enddo ! over i={1,norbs} loop
             close(mytmp)

         endif ! back if ( exists .eqv. .true. ) block
     endif ! back if ( myid == master ) block

! since the hybridization function may be updated in master node, it is
! important to broadcast it from root to all children processes
# if defined (MPI)

! broadcast data
     call mp_bcast(hybf, master)

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
         inquire (file = 'solver.eimp.in', exist = exists)

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

! setup initial eigs, naux, and saux
     eigs = zero
     naux = zero
     saux = zero

! read in initial F matrix if available
!-------------------------------------------------------------------------
     if ( myid == master ) then ! only master node can do it
         exists = .false.

! inquire about file's existence
! file atom.cix is necessary, the code can not run without it
         inquire (file = 'atom.cix', exist = exists)
         if ( exists .eqv. .false. ) then
             call s_print_error('ctqmc_selfer_init','file atom.cix does not exist')
         endif ! back if ( exists .eqv. .false. ) block

! find input file: atom.cix, read it
! open data file
         open(mytmp, file='atom.cix', form='formatted', status='unknown')

! skip ten comment lines
         do i=1,10
             read(mytmp,*)
         enddo ! over i={1,10} loop

! determine whether the spin-orbital coupling effect should be considered
! and check the version of atom.cix
         read(mytmp,*) ver, i, j, cssoc
         if ( ver /= 2 ) then
             call s_print_error('ctqmc_selfer_init','file format of atom.cix is not correct')
         endif ! back if ( ver /= 2 ) block

! skip nine comment lines
         do i=1,9
             read(mytmp,*)
         enddo ! over i={1,9} loop

! read the total number of sectors, maximum dimension of sectors,
! and average dimension of sectors
         read(mytmp,*) nsect, max_dim_sect, ave_dim_sect

! after we know the total number of sectors, we can allocate memory
! for sectors, only for master node
         call ctqmc_allocate_memory_sect()
         call ctqmc_allocate_memory_part()

! read each sector's information
         do i=1,nsect
! read the dimension, number of fermion operators, start index of this sector,
! total number of electrons, z component of spin momentum, z component of
! spin-orbit momentum, and PS good quantum number
             read(mytmp,*) ! skip the header
             read(mytmp,*) k, sectors(i)%ndim,   &
                              sectors(i)%nops,   &
                              sectors(i)%istart, &
                              sectors(i)%nele,   &
                              sectors(i)%sz,     &
                              sectors(i)%jz,     &
                              sectors(i)%ps

! allocate the memory for sectors(i), only for master node
             call ctqmc_allocate_memory_one_sect(sectors(i))

! read the next index
             read(mytmp,*) ! skip the header
             do j=1,sectors(i)%nops
                 read(mytmp,*) k, sectors(i)%next(j,0), sectors(i)%next(j,1)
             enddo ! over do j={1,sectors(i)%nops} loop

! read the eigenvalue of this sector
             read(mytmp,*) ! skip the header
             do j=1,sectors(i)%ndim
                 read(mytmp,*) k, sectors(i)%eval(j)
             enddo ! over j={1,sectors(i)%ndim} loop
         enddo ! over i={1,nsect} loop

! skip three comment lines
         do i=1,3
             read(mytmp,*)
         enddo ! over i={1,3} loop

! read F-matrix from atom.cix
         do i=1,nsect
             do j=1,sectors(i)%nops
                 do k=0,1
                     m = sectors(i)%next(j,k)
                     if ( m == -1 ) CYCLE
                     read(mytmp,*) ! skip one header line
! determine the dimension of F-matrix, number of non-zero elements
                     read(mytmp,*) j1, j2, j3, j4, j5, n
                     call s_assert(j4 == sectors(m)%ndim)
                     call s_assert(j5 == sectors(i)%ndim)
                     sectors(i)%fmat(j,k)%n = j4
                     sectors(i)%fmat(j,k)%m = j5
! allocate memory for F-matrix, only for master node
                     call ctqmc_allocate_memory_one_fmat(sectors(i)%fmat(j,k))
! read non-zero elements of F-matrix
                     sectors(i)%fmat(j,k)%val = zero
                     do m=1,n
                         read(mytmp,*) j1, j2, r1
                         sectors(i)%fmat(j,k)%val(j1,j2) = r1
                     enddo ! over m={1,n} loop
                 enddo ! over k={0,1} loop
             enddo ! over j={1,sectors(i)%nops} loop
         enddo ! over i={1,nsect} loop

! close data file
         close(mytmp)

! add the contribution from chemical potential to eigenvalues
         k = 0
         do i=1,nsect
             do j=1,sectors(i)%ndim
                 k = k + 1
                 naux(k) = sectors(i)%nele
                 eigs(k) = sectors(i)%eval(j) - mune * naux(k)
             enddo ! over j={1,sectors(i)%ndim} loop
         enddo ! over i={1,nsect} loop

! substract the eigenvalues zero point, here we store the eigen energy
! zero point in U
         r1 = minval(eigs)
         r2 = maxval(eigs)
         U  = r1 + one ! here we choose the minimum as zero point
         do i=1,ncfgs
             eigs(i) = eigs(i) - U
         enddo ! over i={1,ncfgs} loop

! check validity of eigs
! note: \infity - \infity is undefined, which return NaN
         do i=1,ncfgs
             if ( isnan( exp( - beta * eigs(i) ) - exp( - beta * eigs(i) ) ) ) then
                 call s_print_error('ctqmc_selfer_init','NaN error, please adjust the zero base of eigs')
             endif ! back if ( isnan( exp( - beta * eigs(i) ) - exp( - beta * eigs(i) ) ) ) block
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( myid == master ) block

! broadcast U, eigs, naux, and saux from master node to all children nodes
# if defined (MPI)

! broadcast data
     call mp_bcast(U,     master)

! block until all processes have reached here
     call mp_barrier()

! broadcast data
     call mp_bcast(eigs,  master)

! block until all processes have reached here
     call mp_barrier()

! broadcast data
     call mp_bcast(naux,  master)
     call mp_bcast(saux,  master)

! block until all processes have reached here
     call mp_barrier()

! broadcast data
     call mp_bcast(cssoc, master)
     call mp_bcast(nsect, master)
     call mp_bcast(max_dim_sect, master)
     call mp_bcast(ave_dim_sect, master)

! block until all processes have reached here
     call mp_barrier()

# endif  /* MPI */

! allocate memory for sectors, only for children nodes
     if ( myid /= master ) then
         call ctqmc_allocate_memory_sect()
         call ctqmc_allocate_memory_part()
     endif ! back if ( myid /= master ) block

! broadcast sectors from master node to all children nodes
# if defined (MPI)

! broadcast data
     do i=1,nsect

! broadcast sector's information
         call mp_bcast(sectors(i)%ndim,   master)
         call mp_bcast(sectors(i)%nops,   master)
         call mp_bcast(sectors(i)%istart, master)
         call mp_bcast(sectors(i)%nele,   master)
         call mp_bcast(sectors(i)%sz,     master)
         call mp_bcast(sectors(i)%jz,     master)
         call mp_bcast(sectors(i)%ps,     master)

! setup barrier
         call mp_barrier()

! allocate memory for t_sector structure, only for children nodes
         if ( myid /= master ) then
             call ctqmc_allocate_memory_one_sect(sectors(i))
         endif ! back if ( myid /= master ) block

! setup barrier
         call mp_barrier()

! broadcast sector's data
         call mp_bcast(sectors(i)%next,   master)
         call mp_bcast(sectors(i)%eval,   master)

! setup barrier
         call mp_barrier()

     enddo ! over i={1,nsect} loop

! block until all processes have reached here
     call mp_barrier()

! broadcast data
     do i=1,nsect
         do j=1,sectors(i)%nops
             do k=0,1

! determine whether next sector is valid
                 m = sectors(i)%next(j,k)
                 if ( m == -1 ) CYCLE

! setup the dimension for F-matrix and allocate memory, only for children nodes
                 if ( myid /= master ) then
                     sectors(i)%fmat(j,k)%n = sectors(m)%ndim
                     sectors(i)%fmat(j,k)%m = sectors(i)%ndim
                     call ctqmc_allocate_memory_one_fmat(sectors(i)%fmat(j,k))
                 endif ! back if ( myid /= master ) block

! setup barrier
                 call mp_barrier()

! broadcast sector's F-matrix
                 call mp_bcast(sectors(i)%fmat(j,k)%val, master)

! setup barrier
                 call mp_barrier()

             enddo ! over k={0,1} loop
         enddo ! over j={1,sectors(i)%nops} loop
     enddo ! over i={1,nsect} loop

! block until all processes have reached here
     call mp_barrier()

# endif  /* MPI */

     return
  end subroutine ctqmc_selfer_init

!!>>> ctqmc_solver_init: initialize the continuous time quantum Monte
!!>>> Carlo quantum impurity solver
  subroutine ctqmc_solver_init()
     use constants, only : zero, czero
     use spring, only : spring_sfmt_init
     use stack, only : istack_clean, istack_push

     use control ! ALL
     use context ! ALL

     use m_sect  ! ALL
     use m_part  ! ALL

     implicit none

! local variables
! loop index
     integer :: i
     integer :: j

! system time since 1970, Jan 1, used to generate the random number seed
     integer :: system_time

! random number seed for twist generator
     integer :: stream_seed

! init random number generator
     call system_clock(system_time)
     stream_seed = abs( system_time - ( myid * 1981 + 2008 ) * 951049 )
     call spring_sfmt_init(stream_seed)

! for stack data structure
!-------------------------------------------------------------------------
! init empty_s and empty_e stack structure
     do i=1,norbs
         call istack_clean( empty_s(i) )
         call istack_clean( empty_e(i) )
     enddo ! over i={1,norbs} loop

     do i=1,norbs
         do j=mkink,1,-1
             call istack_push( empty_s(i), j )
             call istack_push( empty_e(i), j )
         enddo ! over j={mkink,1} loop
     enddo ! over i={1,norbs} loop

! init empty_v stack structure
     call istack_clean( empty_v )
     do j=mkink,1,-1
         call istack_push( empty_v, j )
     enddo ! over j={mkink,1} loop

! for integer variables
!-------------------------------------------------------------------------
! init global variables
     ckink   = 0
     csign   = 1
     cnegs   = 0
     caves   = 0

! for real variables
!-------------------------------------------------------------------------
! init statistics variables
     insert_tcount = zero
     insert_accept = zero
     insert_reject = zero

     remove_tcount = zero
     remove_accept = zero
     remove_reject = zero

     lshift_tcount = zero
     lshift_accept = zero
     lshift_reject = zero

     rshift_tcount = zero
     rshift_accept = zero
     rshift_reject = zero

     reflip_tcount = zero
     reflip_accept = zero
     reflip_reject = zero

! for integer arrays
!-------------------------------------------------------------------------
! init index array
     index_s = 0
     index_e = 0

     index_t = 0
     index_v = 0

! init type  array
     type_v  = 1

! init flvr  array
     flvr_v  = 1

! init rank  array
     rank    = 0

! for real arrays
!-------------------------------------------------------------------------
! init time  array
     time_s  = zero
     time_e  = zero

     time_v  = zero

! init hist  array
     hist    = zero

! init auxiliary physical observables
     paux    = zero

! init probability for atomic states
     prob    = zero
     diag    = zero

! init occupation number array
     nmat    = zero
     nnmat   = zero

! init M-matrix related array
     mmat    = zero
     lspace  = zero
     rspace  = zero

! init imaginary time impurity green's function array
     gtau    = zero

! init imaginary time bath weiss's function array
     wtau    = zero

! init exponent array expt_v
     expt_v  = zero

! init exponent array expt_t
! expt_t(:,1) : used to store trial  e^{ -(\beta - \tau_n) \cdot H }
! expt_t(:,2) : used to store normal e^{ -(\beta - \tau_n) \cdot H }
! expt_t(:,3) : used to store e^{ -\beta \cdot H } persistently
! expt_t(:,4) : conserved, not used so far
     do i=1,ncfgs
         expt_t(i, 1) = exp( - eigs(i) * beta )
         expt_t(i, 2) = exp( - eigs(i) * beta )
         expt_t(i, 3) = exp( - eigs(i) * beta )
         expt_t(i, 4) = exp( - eigs(i) * beta )
     enddo ! over i={1,ncfgs} loop

! init matrix_ntrace and matrix_ptrace
     matrix_ntrace = sum( expt_t(:, 1) )
     matrix_ptrace = sum( expt_t(:, 2) )

! for complex arrays
!-------------------------------------------------------------------------
! init exponent array exp_s and exp_e
     exp_s   = czero
     exp_e   = czero

! init G-matrix related array
     gmat    = czero
     lsaves  = czero
     rsaves  = czero

! init impurity green's function array
     grnf    = czero

! init bath weiss's function array
     wssf    = czero

! init self-energy function array
! note: sig1 should not be reinitialized here, since it is used to keep
! the persistency of self-energy function
!<     sig1    = czero
     sig2    = czero

! for the other variables/arrays
!-------------------------------------------------------------------------
! init m_part module
     nop     = 0
     ops     = 0
     ope     = 0

     renew   = 0
     async   = 0
     is_cp   = 0
     nc_cp   = 0

     saved_p = zero
     saved_n = zero

! fourier transformation hybridization function from matsubara frequency
! space to imaginary time space
     call ctqmc_four_hybf(hybf, htau)

! symmetrize the hybridization function on imaginary time axis if needed
     if ( issun == 2 .or. isspn == 1 ) then
         call ctqmc_symm_gtau(symm, htau)
     endif ! back if ( issun == 2 .or. isspn == 1 ) block

! calculate the 2nd-derivates of htau, which is used in spline subroutines
     call ctqmc_make_hsed(tmesh, htau, hsed)

! dump the necessary files
!-------------------------------------------------------------------------
! write out the hybridization function in matsubara frequency axis
     if ( myid == master ) then ! only master node can do it
         call ctqmc_dump_hybf(rmesh, hybf)
     endif ! back if ( myid == master ) block

! write out the hybridization function on imaginary time axis
     if ( myid == master ) then ! only master node can do it
         call ctqmc_dump_htau(tmesh, htau)
     endif ! back if ( myid == master ) block

! write out the seed for random number stream, it is useful to reproduce
! the calculation process once fatal error occurs.
     if ( myid == master ) then ! only master node can do it
         write(mystd,'(4X,a,i11)') 'seed:', stream_seed
     endif ! back if ( myid == master ) block

     return
  end subroutine ctqmc_solver_init

!!>>> ctqmc_final_array: garbage collection for this program, please refer
!!>>> to ctqmc_setup_array
  subroutine ctqmc_final_array()
     use context ! ALL

     use m_sect  ! ALL
     use m_part  ! ALL

     implicit none

! deallocate memory for context module
     call ctqmc_deallocate_memory_clur()
     call ctqmc_deallocate_memory_flvr()

     call ctqmc_deallocate_memory_mesh()
     call ctqmc_deallocate_memory_meat()
     call ctqmc_deallocate_memory_umat()
     call ctqmc_deallocate_memory_mmat()

     call ctqmc_deallocate_memory_gmat()
     call ctqmc_deallocate_memory_wmat()
     call ctqmc_deallocate_memory_smat()

     call ctqmc_deallocate_memory_sect()
     call ctqmc_deallocate_memory_part()

     return
  end subroutine ctqmc_final_array
