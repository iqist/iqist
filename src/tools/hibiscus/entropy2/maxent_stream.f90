!---------------------------------------------------------------
! project : maxent
! program : maxent_config
!           maxent_setup_array
!           maxent_databins_init
!           maxent_final_array
! source  : maxent_stream.f90
! type    : subroutine
! author  : yilin wang (email: qhwyl2006@126.com)
! history : 05/30/2013 by yilin wang
! purpose : define subroutines used to configure, setup array, 
!           finalize array, and initialize data bins
! input   :
! output  :
! status  : unstable
! comment :
!---------------------------------------------------------------

!===============================================================
! subroutine: maxent_config
! purpose   : configure the control parameters
!===============================================================
  subroutine maxent_config()
      use constants
      use control

      implicit none

! local variables
! check whether file exists
      logical :: exists

! stepup control parameters
!===============================================================
! control parameters for maxent
!===============================================================
      imode  = 0            ! 0 for flat model, 1 for gauss model, 2 for reading from file
      icov   = 0            ! diagonalize coavirance matrix: 0 for no, 1 for yes
      nbins  = 1000         ! number of Monte Carlo data bins
      ntime  = 129          ! number of time slice of each data bin
      nwhf   = 1000         ! number of frequency points at the half axis
      nalpha = 1000         ! number of alpha mesh points      

      beta   = 10.0_dp      ! inversion temperatue 
      step   = 0.02_dp      ! step size of frequency mesh
      sigma  = 5.0_dp       ! standard deviation of Gaussian distribution  

      max_alpha = 100.0_dp  ! max value of parameter alpha
      min_alpha = 1.0_dp    ! low value of parameter alpha 

! read control parameters from file
      exists = .false. 
      inquire (file = "maxent.control.in", exist = exists)

! if maxent.control.in doesn't exist, the program should be stoped here
      if ( exists .eqv. .false. ) then
! process error 
          call maxent_print_error( "maxent_config", "no file maxent.control.in" )
! otherwise, open the input file, read it
      else
          open(mytmp, file = "maxent.control.in", form = "formatted", status = "unknown" )
!-------------------------------------------------------------- 
          read(mytmp,*)    ! skip one line
          read(mytmp,*)    ! skip one line
          read(mytmp,*)    ! skip one line 
!--------------------------------------------------------------
          read(mytmp,*) imode
          read(mytmp,*) icov
          read(mytmp,*) nbins
          slice = nbins / 10
          read(mytmp,*) ntime
          read(mytmp,*) nwhf
          nw = 2 * nwhf +1
          read(mytmp,*) nalpha
!--------------------------------------------------------------
          read(mytmp,*) beta
          read(mytmp,*) step
          read(mytmp,*) sigma
          read(mytmp,*) max_alpha
          read(mytmp,*) min_alpha
!--------------------------------------------------------------
! close file
          close(mytmp)
      endif ! back if( exists .eqv. .true.) block
 
      return 
  end subroutine maxent_config

!==============================================================
! subroutine: maxent_setup_array
! purpose   : setup array
!==============================================================
  subroutine maxent_setup_array()
      use context
    
      implicit none

! allocate memory 
      call maxent_allocate_memory_databins()

      return 
  end subroutine maxent_setup_array

!==============================================================
! subroutine: maxent_databins_init
! purpose   : initialize the maxent program
!==============================================================
  subroutine maxent_databins_init()
      use constants
      use control
      use context

      implicit none

! local variables
! scalar variables
      logical :: exists      

! loop index
      integer :: itime
      integer :: jtime
      integer :: ibin
      integer :: iw
      integer :: ialpha
      integer :: i

! error information from lapack call
      integer :: info

! allocate memory status
      integer :: istat

! array variables
! data bins generated by Monte Carlo calculation
      real(dp) :: grnbin(ntime, nbins) 

! average of data bins
      real(dp) :: grn_ave(ntime)

! histogram of green data bins
      integer :: hist(slice, ntime)

! histogram mesh
      real(dp) :: hmesh(slice, ntime)

! covariance matrix of data bins
      real(dp) :: cov(ntime, ntime)

! kernel
      real(dp) :: kernel(ntime, nw)

! eigen vectors of cov
      real(dp) :: umat_cov(ntime, ntime)

! transpose of umat_cov
      real(dp) :: umatt_cov(ntime, ntime)

! temp matrix
      real(dp) :: mtemp1(ntime, nw) 
      real(dp) :: mtemp2(nw,ntime)

! temp vector
      real(dp) :: vtemp(ntime)

! eigenvalues of cov
      real(dp) :: eigval(ntime)

! the left vectors for SVD
      real(dp), allocatable :: umat_temp(:,:)

! the right vectors for SVD
      real(dp), allocatable :: vmatt_temp(:,:)

! singular values 
      real(dp), allocatable :: sigvec_temp(:)

! temp matrixs in singular space
      real(dp), allocatable :: ss_mtemp1(:,:)
      real(dp), allocatable :: ss_mtemp2(:,:)
      real(dp), allocatable :: ss_mtemp3(:,:)

! temp chi^2
      real(dp) :: chi_temp

! the min value of nw and ntime
      integer :: min_mn

! initialize them
      grn_ave = zero
      hist = 0
      cov = zero
      umat_cov = zero
      umatt_cov = zero
      eigval = zero
      kernel = zero
      mtemp1 = zero
      mtemp2 = zero
      vtemp = zero
      chi_temp = zero

! print out runtime information
      write(mystd,"(2X,a)") "MAXENT >>> Initialize Data Bins..."

! determine the min value of nw and ntime 
      min_mn = min(nw,ntime)

! allocate memory for umat and vmatt
      allocate(umat_temp(nw,min_mn),     stat = istat)
      allocate(vmatt_temp(min_mn,ntime), stat = istat)
      allocate(sigvec_temp(min_mn),      stat = istat)

! process allocate error
      if ( istat /= 0 ) then
          call maxent_print_error("maxent_databins_init", "can't allocate enough memory")
      endif 

! initialize them
      umat_temp   = zero
      vmatt_temp  = zero
      sigvec_temp = zero

!--------------------------------------------------------------
! step 1: read data bins from file maxent.bins.in
!--------------------------------------------------------------
! open file maxent.bins.in to read data from it
      exists = .false.
      inquire( file="maxent.bins.in", exist = exists )    

! if maxent.bins.in doesn't exist, the program should be stoped here
      if ( exists .eqv. .false. ) then
! process error 
          call maxent_print_error( "maxent_databins_init", "no file maxent.bins.in" )
! otherwise, open the input file, read it
      else
          open(mytmp, file = "maxent.bins.in", form = "formatted", status = "unknown" )
! read data bins              
          do ibin=1, nbins
              read(mytmp,*)  ! skip header
              do itime=1, ntime
                  read(mytmp,*) tmesh(itime), grnbin(itime, ibin)
              enddo ! loop over {itime=1, ntime}
              read(mytmp,*) ! skip one blank line
              read(mytmp,*) ! skip one blank line 
          enddo ! loop over {ibin=1, nbins}               
! close file
          close(mytmp)
      endif ! back if( exists .eqv. .false.) block

!---------------------------------------------------------------
! step 2: calculate the average of data bins
!---------------------------------------------------------------
      grn_ave = zero
      do itime=1, ntime
          do ibin=1, nbins
              grn_ave(itime) = grn_ave(itime) + grnbin(itime,ibin) 
          enddo
          grn_ave(itime) = grn_ave(itime) / real(nbins)
      enddo

!---------------------------------------------------------------
! step 3: check whether the data bins are  Gaussian distribution 
!---------------------------------------------------------------
      call maxent_make_hist( grnbin, grn_ave, hmesh, hist)
      call maxent_dump_hist( hmesh, hist ) 

!---------------------------------------------------------------
! step 4: calculate the covariance matrix of data bins and
! diagonalize it 
!---------------------------------------------------------------
      cov = zero
      do itime=1, ntime
          do jtime=1, ntime
             do ibin=1, nbins
                 cov(itime, jtime) = cov(itime, jtime) + &
                 ( grnbin(itime,ibin) - grn_ave(itime) ) * &
                 ( grnbin(jtime,ibin) - grn_ave(jtime) ) 
             enddo ! loop over {ibin=1, nbins}
             cov(itime, jtime) = cov(itime, jtime) / real(nbins-1)
          enddo ! loop over {jtime=1, ntime}
      enddo ! loop over {itime=1, ntime} 

      umat_cov = cov
      if ( icov == 1 ) then
          call maxent_dsyev(ntime, umat_cov, eigval, info )
          if ( info /=0 ) then
              call maxent_print_error("maxent_databins_init", "diagonalize covariance matrix.")
          endif
 
! store the eigen values in the global variable eigcov
          eigcov = eigval
      else
          do itime=1, ntime
              eigcov(itime) = cov(itime,itime)
          enddo
      endif

! if icov == 2, we should adjust the small eigvalues to a larger constant
      if ( icov == 2 ) then
          do itime=1, ntime
              if (eigcov(itime) < eps6) then
                  eigcov(itime) = eps6
              endif
          enddo
      endif

      call maxent_dump_eigcov()

!---------------------------------------------------------------
! step 5: construct mesh of frequency, and alpha
!---------------------------------------------------------------
! step 5.1: frequency mesh
      do iw=1,nw
          fmesh(iw) = step * ( iw - nwhf - 1 )
      enddo 

! step 5.2: alpha mesh
      do ialpha=1, nalpha
          amesh(ialpha) = max_alpha - (max_alpha - min_alpha) / real(nalpha-1) * ( ialpha -1 )  
      enddo 

!---------------------------------------------------------------
! step 6: construct the kernel
!---------------------------------------------------------------
      do itime=1, ntime
          do iw=1, nw
              if ( fmesh(iw) <= zero ) then
                  kernel(itime,iw) = exp( (beta-tmesh(itime)) * fmesh(iw) ) / &
                                     ( one + exp( beta * fmesh(iw)) )         
              else
                  kernel(itime,iw) = exp( -tmesh(itime) * fmesh(iw) ) / &
                                     ( one + exp( -beta * fmesh(iw)) )    
              endif
          enddo ! loop over {iw=1, nw}
      enddo ! loop over {itime=1, ntime}

!---------------------------------------------------------------
! step 7: construct default model
!---------------------------------------------------------------
! step 7.1: set model
      if ( imode == 0 ) then ! flat model
          call maxent_make_flat_model()
      elseif ( imode == 1 ) then  ! gauss model
          call maxent_make_gauss_model()
      else  ! from file
          call maxent_make_file_model()
      endif ! back if(imode==0) block 

! step 7.2: dump the model for reference
      call maxent_dump_model()

! step 7.3: scale the model
      aw_model = aw_model * step

!---------------------------------------------------------------
! step 8: rotate the kernel, and the data
!---------------------------------------------------------------
! step 8.1: rotate the kernel
! make transpose of umat
      if ( icov == 1 ) then
          umatt_cov = transpose(umat_cov)
          call maxent_dgemm(ntime, ntime, umatt_cov, nw, kernel, mtemp1)
          rkern = mtemp1
      else
          rkern = kernel
      endif
 
! step 8.2: rotate the data
      if ( icov == 1) then
          call maxent_dgemv(ntime, ntime, umatt_cov, grn_ave, vtemp)
          rgrn = vtemp
      else
          rgrn = grn_ave 
      endif

! step 8.3: calculate the chi^2 for the default model, just for
! reference.
! kernel * aw_model
      call maxent_dgemv(ntime, nw, rkern, aw_model, vtemp)

! calculate chi^2
      chi_temp = zero
      do itime=1, ntime
          chi_temp = chi_temp + ( vtemp(itime) - rgrn(itime) )**2 / eigcov(itime)
      enddo
      chi_temp = half * chi_temp

! print temp information for reference
      write(mystd,"(2X,a,E16.8)") "MAXENT >>> chi^2 / 2 for default model: ",chi_temp
       
! step 9: construct the singular space of kerenl^T
! step 9.1: transpose of the rotated kernel "rkern"
      mtemp2 = transpose(rkern)

! step 9.2: call the lapack subroutine dgesvd to make the singular value decomposition
      call maxent_dgesvd(nw, ntime, min_mn, mtemp2, umat_temp, sigvec_temp, vmatt_temp, info)
      if ( info /= 0 ) then
          call maxent_print_error("maxent_databins_init", "SVD of kernel")
      endif
     
      call maxent_dump_svd(min_mn,sigvec_temp)

! step 9.3: determine the dimension of the singular space
      ns = 0
      do i=1, min_mn
          if ( sigvec_temp(i) > sigvec_temp(1) * eps6 ) then
              ns = ns + 1
          endif  
      enddo     

! print ns
      write(mystd,"(2X,a,i5)") "MAXENT >>> Dimension of Singular Space: ", ns

! step 9.4: set the arrays in the singular space
! allocate memory
      call maxent_allocate_memory_singular()

! set the arrays
      umat = umat_temp(:,1:ns)
      vmatt = vmatt_temp(1:ns,:)
      sigvec = sigvec_temp(1:ns)

! step 9.5: construct the M matrix
! $M = \Sigma * V^{T} * W * V * \Sigma^{T}$
      allocate(ss_mtemp1(ns,ntime),  stat=istat)
      allocate(ss_mtemp2(ntime,ns),  stat=istat)
      allocate(ss_mtemp3(ns,ns),     stat=istat)

      if ( istat /= 0 ) then
          call maxent_print_error("maxent_databins_init", "can't allocate enough memory")
      endif 

      do i=1, ns
          ss_mtemp1(i,:) = sigvec(i) * vmatt(i,:)
      enddo

      do itime=1, ntime
          ss_mtemp2(itime,:) = ss_mtemp1(:,itime) / eigcov(itime) 
      enddo

      call maxent_dgemm(ns, ntime, ss_mtemp1, ns, ss_mtemp2, ss_mtemp3) 

      mmat = ss_mtemp3
! print runtime information
      write(mystd,"(2X,a)") "MAXENT >>> Initialize Data Bins Done!"
      write(mystd,*)
      write(mystd,*)

      return
  end subroutine maxent_databins_init

!==============================================================
! subroutine used to finalize 
!==============================================================
  subroutine maxent_final_array()
      use context

      implicit none

! deallocate memory
      call maxent_deallocate_memory_databins()
      call maxent_deallocate_memory_singular()

      return
  end subroutine maxent_final_array