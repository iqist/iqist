!!!-----------------------------------------------------------------------
!!! project : begonia
!!! program : cat_insert_ztrace
!!!           cat_remove_ztrace
!!!           cat_lshift_ztrace
!!!           cat_rshift_ztrace <<<---
!!!           try_insert_colour
!!!           try_remove_colour
!!!           try_lshift_colour
!!!           try_rshift_colour <<<---
!!!           cat_insert_colour
!!!           cat_remove_colour
!!!           cat_lshift_colour
!!!           cat_rshift_colour <<<---
!!!           try_insert_flavor
!!!           try_remove_flavor
!!!           try_lshift_flavor
!!!           try_rshift_flavor <<<---
!!!           cat_insert_flavor
!!!           cat_remove_flavor
!!!           cat_lshift_flavor
!!!           cat_rshift_flavor <<<---
!!!           ctqmc_make_ztrace
!!!           ctqmc_make_evolve <<<---
!!!           ctqmc_make_equate
!!!           ctqmc_make_search <<<---
!!!           ctqmc_make_colour
!!!           ctqmc_make_flavor <<<---
!!!           ctqmc_make_display<<<---
!!! source  : ctqmc_flavor.f90
!!! type    : subroutines
!!! author  : li huang (email:lihuang.dmft@gmail.com)
!!! history : 09/23/2009 by li huang (created)
!!!           08/17/2015 by li huang (last modified)
!!! purpose : provide basic infrastructure (elementary updating subroutines)
!!!           for hybridization expansion version continuous time quantum
!!!           Monte Carlo (CTQMC) quantum impurity solver.
!!!           the following subroutines deal with the operators traces only.
!!! status  : unstable
!!! comment :
!!!-----------------------------------------------------------------------

!!========================================================================
!!>>> service layer: evaluate ztrace ratio                             <<<
!!========================================================================

!!>>> cat_insert_ztrace: calculate the trace ratio for insert new create
!!>>> and destroy operators on perturbation expansion series
  subroutine cat_insert_ztrace(flvr, is, ie, tau_start, tau_end, trace_ratio)
     use constants, only : dp, zero
     use stack, only : istack_getrest, istack_gettop, istack_getter

     use control, only : ncfgs
     use control, only : beta
     use context, only : matrix_ptrace, matrix_ntrace
     use context, only : empty_v, index_t, index_v, type_v, flvr_v, time_v, expt_t, expt_v
     use context, only : eigs

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address to insert new create and destroy operators
! is and ie are for create and destroy operators, respectively
     integer, intent(in)   :: is
     integer, intent(in)   :: ie

! imaginary time point of the new create operator
     real(dp), intent(in)  :: tau_start

! imaginary time point of the new destroy operator
     real(dp), intent(in)  :: tau_end

! ratio between old and new configurations, the local trace part
     real(dp), intent(out) :: trace_ratio

! local variables
! loop index over operators
     integer  :: i

! memory address for new create and destroy operators
     integer  :: as
     integer  :: ae

! total number of operators
     integer  :: nsize

! memory address for the rightmost time evolution operator
     integer  :: ilast

! imaginary time interval for two successive operators
! t_prev stands for t_{i} - t_{i-1), and t_next stands for t_{i+1} - t_{i}
     real(dp) :: t_prev
     real(dp) :: t_next

! determine nsize at first, get total number of operators
     nsize = istack_getrest( empty_v )

! copy index_v to index_t
! since we do not insert the two operators actually at this stage, so
! index_v can not be overwritten here
     do i=1,nsize
         index_t(i) = index_v(i)
     enddo ! over i={1,nsize} loop

!-------------------------------------------------------------------------
! stage 1: insert a create operator, trial step
!-------------------------------------------------------------------------
! get memory address for create operator
     call istack_getter( empty_v, istack_gettop( empty_v ) - 0, as )

! store basic data for new create operator
     time_v(as) = tau_start
     flvr_v(as) = flvr
     type_v(as) = 1

! shift index_t to make an empty room
     do i=nsize,is,-1
         index_t(i+1) = index_t(i)
     enddo ! over i={nsize,is,-1} loop

! store the memory address for create operator
     index_t(is) = as

! evaluate previous imaginary time interval
     if ( is ==         1 ) then ! the imaginary time of create operator is the smallest
         t_prev = time_v( index_t(is) ) - zero
     else
         t_prev = time_v( index_t(is) ) - time_v( index_t(is-1) )
     endif ! back if ( is == 1 ) block

! evaluate next imaginary time interval
     if ( is == nsize + 1 ) then ! the imaginary time of create operator is the largest
         t_next = beta - time_v( index_t(is) )
     else
         t_next = time_v( index_t(is+1) ) - time_v( index_t(is) )
     endif ! back if ( is == nsize + 1 ) block

! evaluate ilast
! if is == nsize + 1, index_t(is+1) is not indexed (i.e, equal to 0),
! so we store the rightmost time evolution operator at expt_t
     if ( is == nsize + 1 ) then
         ilast = 1
! the closest operator need to be modified as well
     else
         call istack_getter( empty_v, istack_gettop( empty_v ) - 1, ilast )
         time_v( ilast ) = time_v( index_t(is+1) )
         flvr_v( ilast ) = flvr_v( index_t(is+1) )
         type_v( ilast ) = type_v( index_t(is+1) )
         index_t(is+1) = ilast
     endif ! back if ( is == nsize + 1 ) block

! update the expt_v and expt_t, matrix of time evolution operator
     do i=1,ncfgs
         expt_v( i, as ) = exp ( -eigs(i) * t_prev )
     enddo ! over i={1,ncfgs} loop

     if ( is == nsize + 1 ) then
         do i=1,ncfgs
             expt_t( i, ilast ) = exp ( -eigs(i) * t_next )
         enddo ! over i={1,ncfgs} loop
     else
         do i=1,ncfgs
             expt_v( i, ilast ) = exp ( -eigs(i) * t_next )
         enddo ! over i={1,ncfgs} loop
         do i=1,ncfgs
             expt_t( i,   1   ) = expt_t( i,   2   )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( is == nsize + 1 ) block

! update nsize
     nsize = nsize + 1

!-------------------------------------------------------------------------
! stage 2: insert a destroy operator, trial step
!-------------------------------------------------------------------------
! get memory address for destroy operator
     call istack_getter( empty_v, istack_gettop( empty_v ) - 2, ae )

! store basic data for new destroy operator
     time_v(ae) = tau_end
     flvr_v(ae) = flvr
     type_v(ae) = 0

! shift index_t to make an empty room
     do i=nsize,ie,-1
         index_t(i+1) = index_t(i)
     enddo ! over i={nsize,ie,-1} loop

! store the memory address for destroy operator
     index_t(ie) = ae

! evaluate previous imaginary time interval
     if ( ie ==         1 ) then ! the imaginary time of destroy operator is the smallest
         t_prev = time_v( index_t(ie) ) - zero
     else
         t_prev = time_v( index_t(ie) ) - time_v( index_t(ie-1) )
     endif ! back if ( ie == 1 ) block

! evaluate next imaginary time interval
     if ( ie == nsize + 1 ) then ! the imaginary time of destroy operator is the largest
         t_next = beta - time_v( index_t(ie) )
     else
         t_next = time_v( index_t(ie+1) ) - time_v( index_t(ie) )
     endif ! back if ( ie == nsize + 1 ) block

! evaluate ilast
! if ie == nsize + 1, index_t(ie+1) is not indexed (i.e, equal to 0),
! so we store the rightmost time evolution operator at expt_t
     if ( ie == nsize + 1 ) then
         ilast = 1
! the closest operator need to be modified as well
     else
         call istack_getter( empty_v, istack_gettop( empty_v ) - 3, ilast )
         time_v( ilast ) = time_v( index_t(ie+1) )
         flvr_v( ilast ) = flvr_v( index_t(ie+1) )
         type_v( ilast ) = type_v( index_t(ie+1) )
         index_t(ie+1) = ilast
     endif ! back if ( ie == nsize + 1 ) block

! update the expt_v and expt_t, matrix of time evolution operator
     do i=1,ncfgs
         expt_v( i, ae ) = exp ( -eigs(i) * t_prev )
     enddo ! over i={1,ncfgs} loop

     if ( ie == nsize + 1 ) then
         do i=1,ncfgs
             expt_t( i, ilast ) = exp ( -eigs(i) * t_next )
         enddo ! over i={1,ncfgs} loop
     else
         do i=1,ncfgs
             expt_v( i, ilast ) = exp ( -eigs(i) * t_next )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( ie == nsize + 1 ) block

!-------------------------------------------------------------------------
! stage 3: evaluate trace ratio
!-------------------------------------------------------------------------
! calculate new matrix trace for the flavor part
     call ctqmc_make_ztrace(1, nsize+1, matrix_ntrace, tau_start, tau_end)

! evaluate trace_ratio
     trace_ratio = matrix_ntrace / matrix_ptrace

     return
  end subroutine cat_insert_ztrace

!!>>> cat_remove_ztrace: calculate the trace ratio for remove old create
!!>>> and destroy operators on perturbation expansion series
  subroutine cat_remove_ztrace(is, ie, tau_start, tau_end, trace_ratio)
     use constants, only : dp, zero
     use stack, only : istack_getrest, istack_gettop, istack_getter

     use control, only : ncfgs
     use control, only : beta
     use context, only : matrix_ptrace, matrix_ntrace
     use context, only : empty_v, index_t, index_v, type_v, flvr_v, time_v, expt_t, expt_v
     use context, only : eigs

     implicit none

! external arguments
! index address to remove old create and destroy operators
! is and ie are for create and destroy operators, respectively
     integer, intent(in)   :: is
     integer, intent(in)   :: ie

! imaginary time point of the old create operator
     real(dp), intent(in)  :: tau_start

! imaginary time point of the old destroy operator
     real(dp), intent(in)  :: tau_end

! ratio between old and new configurations, the local trace part
     real(dp), intent(out) :: trace_ratio

! local variables
! loop index over operators
     integer  :: i

! memory address for old create and destroy operators
     integer  :: as
     integer  :: ae

! total number of operators
     integer  :: nsize

! memory address for the rightmost time evolution operator
     integer  :: ilast

! imaginary time interval for two successive operators
! t_prev stands for t_{i} - t_{i-1), and t_next stands for t_{i+1} - t_{i}
     real(dp) :: t_prev
     real(dp) :: t_next

! determine nsize at first, get total number of operators
     nsize = istack_getrest( empty_v )

! copy index_v to index_t
! since we do not remove the two operators actually at this stage, so
! index_v can not be overwritten here
     do i=1,nsize
         index_t(i) = index_v(i)
     enddo ! over i={1,nsize} loop

!-------------------------------------------------------------------------
! stage 1: remove create operator, trial step
!-------------------------------------------------------------------------
! get memory address for old create operator
     as = index_t(is)

! remove the unused index address from index_t
     do i=is,nsize-1
         index_t(i) = index_t(i+1)
     enddo ! over i={is,nsize-1} loop
     index_t(nsize) = 0

! evaluate previous imaginary time interval
     if ( is == 1     ) then ! the imaginary time of create operator is the smallest
         t_prev = zero
     else
         t_prev = time_v( index_t(is-1) )
     endif ! back if ( is == 1 ) block

! evaluate next imaginary time interval
     if ( is == nsize ) then ! the imaginary time of create operator is the largest
         t_next = beta
     else
         t_next = time_v( index_t(is)   )
     endif ! back if ( is == nsize ) block

! evaluate ilast
! if is == nsize, index_t(is) is not indexed (i.e, equal to 0),
! so we store the rightmost time evolution operator at expt_t
     if ( is == nsize ) then
         ilast = 1
! the closest operator need to be modified as well
     else
         call istack_getter( empty_v, istack_gettop( empty_v ) - 0, ilast )
         time_v( ilast ) = time_v( index_t(is) )
         flvr_v( ilast ) = flvr_v( index_t(is) )
         type_v( ilast ) = type_v( index_t(is) )
         index_t(is) = ilast
     endif ! back if ( is == nsize ) block

! update the expt_v and expt_t, matrix of time evolution operator
     if ( is == nsize ) then
         do i=1,ncfgs
             expt_t( i, ilast ) = exp ( -eigs(i) * (t_next - t_prev) )
         enddo ! over i={1,ncfgs} loop
     else
         do i=1,ncfgs
             expt_v( i, ilast ) = exp ( -eigs(i) * (t_next - t_prev) )
         enddo ! over i={1,ncfgs} loop
         do i=1,ncfgs
             expt_t( i, 1 ) = expt_t( i, 2 )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( is == nsize ) block

! update nsize
     nsize = nsize - 1

!-------------------------------------------------------------------------
! stage 2: remove destroy operator, trial step
!-------------------------------------------------------------------------
! get memory address for old destroy operator
     ae = index_t(ie)

! remove the unused index address from index_t
     do i=ie,nsize-1
         index_t(i) = index_t(i+1)
     enddo ! over i={ie,nsize-1} loop
     index_t(nsize) = 0

! evaluate previous imaginary time interval
     if ( ie == 1     ) then ! the imaginary time of destroy operator is the smallest
         t_prev = zero
     else
         t_prev = time_v( index_t(ie-1) )
     endif ! back if ( ie == 1 ) block

! evaluate next imaginary time interval
     if ( ie == nsize ) then ! the imaginary time of destroy operator is the largest
         t_next = beta
     else
         t_next = time_v( index_t(ie)   )
     endif ! back if ( ie == nsize ) block

! evaluate ilast
! if ie == nsize, index_t(ie) is not indexed (i.e, equal to 0),
! so we store the rightmost time evolution operator at expt_t
     if ( ie == nsize ) then
         ilast = 1
! the closest operator need to be modified as well
     else
         call istack_getter( empty_v, istack_gettop( empty_v ) - 1, ilast )
         time_v( ilast ) = time_v( index_t(ie) )
         flvr_v( ilast ) = flvr_v( index_t(ie) )
         type_v( ilast ) = type_v( index_t(ie) )
         index_t(ie) = ilast
     endif ! back if ( ie == nsize ) block

! update the expt_v and expt_t, matrix of time evolution operator
     if ( ie == nsize ) then
         do i=1,ncfgs
             expt_t( i, ilast ) = exp ( -eigs(i) * (t_next - t_prev) )
         enddo ! over i={1,ncfgs} loop
     else
         do i=1,ncfgs
             expt_v( i, ilast ) = exp ( -eigs(i) * (t_next - t_prev) )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( ie == nsize ) block

!-------------------------------------------------------------------------
! stage 3: evaluate trace ratio
!-------------------------------------------------------------------------
! calculate new matrix trace for the flavor part
     call ctqmc_make_ztrace(1, nsize-1, matrix_ntrace, tau_start, tau_end)

! evaluate trace_ratio
     trace_ratio = matrix_ntrace / matrix_ptrace

     return
  end subroutine cat_remove_ztrace

!!>>> cat_lshift_ztrace: calculate the trace ratio for shift old create
!!>>> operators on perturbation expansion series
  subroutine cat_lshift_ztrace(flvr, iso, isn, tau_start1, tau_start2, trace_ratio)
     use constants, only : dp, zero
     use stack, only : istack_getrest, istack_gettop, istack_getter

     use control, only : ncfgs
     use control, only : beta
     use context, only : matrix_ptrace, matrix_ntrace
     use context, only : empty_v, index_t, index_v, type_v, flvr_v, time_v, expt_t, expt_v
     use context, only : eigs

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address to shift existing create operator
! iso and isn are for old and new create operators, respectively
     integer, intent(in)   :: iso
     integer, intent(in)   :: isn

! imaginary time point of the old create operator
     real(dp), intent(in)  :: tau_start1

! imaginary time point of the new create operator
     real(dp), intent(in)  :: tau_start2

! ratio between old and new configurations, the local trace part
     real(dp), intent(out) :: trace_ratio

! local variables
! loop index over operators
     integer  :: i

! memory address for old and new create operators
     integer  :: as

! index address for old create operator
     integer  :: iso_t

! total number of operators
     integer  :: nsize

! imaginary time interval for two successive operators
! t_prev stands for t_{i} - t_{i-1), and t_next stands for t_{i+1} - t_{i}
     real(dp) :: t_prev
     real(dp) :: t_next

! determine nsize at first, get total number of operators
     nsize = istack_getrest( empty_v )

! copy index_v to index_t
! since we do not shift the create operator actually at this stage, so
! index_v can not be overwritten here
     do i=1,nsize
         index_t(i) = index_v(i)
     enddo ! over i={1,nsize} loop

!-------------------------------------------------------------------------
! stage 1: shift old create operator, trial step
!-------------------------------------------------------------------------
! get memory address for create operator
     call istack_getter( empty_v, istack_gettop( empty_v ) - 0, as )

! store basic data for new create operator
     time_v(as) = tau_start2
     flvr_v(as) = flvr
     type_v(as) = 1

! remove the unused index address from index_t
     do i=iso,nsize-1
         index_t(i) = index_t(i+1)
     enddo ! over i={iso,nsize-1} loop
     index_t(nsize) = 0

! shift index_t to make an empty room
     do i=nsize-1,isn,-1
         index_t(i+1) = index_t(i)
     enddo ! over i={nsize-1,isn,-1} loop

! store the memory address for create operator
     index_t(isn) = as

! evaluate previous imaginary time interval
     if ( isn == 1 ) then ! the imaginary time of create operator is the smallest
         t_prev = time_v( index_t(isn) ) - zero
     else
         t_prev = time_v( index_t(isn) ) - time_v( index_t(isn-1) )
     endif ! back if ( isn == 1 ) block

! update the expt_v, matrix of time evolution operator
     do i=1,ncfgs
         expt_v( i, as ) = exp ( -eigs(i) * t_prev )
     enddo ! over i={1,ncfgs} loop

!-------------------------------------------------------------------------
! stage 2: auxiliary tasks
!-------------------------------------------------------------------------
! its neighbor needs to be changes as well.
! makes a copy of time and type, and changes time evolution operator
     if ( isn < nsize ) then
         t_next = time_v( index_t(isn+1) ) - time_v( index_t(isn) )
         call istack_getter( empty_v, istack_gettop( empty_v ) - 1, as )
         time_v(as) = time_v( index_t(isn+1) )
         flvr_v(as) = flvr_v( index_t(isn+1) )
         type_v(as) = type_v( index_t(isn+1) )
         index_t(isn+1) = as
         do i=1,ncfgs
             expt_v( i, as ) = exp ( -eigs(i) * t_next )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( isn < nsize ) block

! the operator closest to the old place needs to be changed as well
     if ( iso < nsize .and. iso /= isn ) then
         if ( iso > isn ) then
             iso_t = iso + 1
         else
             iso_t = iso
         endif ! back if ( iso > isn ) block
         if ( iso_t == 1 ) then
             t_prev = time_v( index_t(iso_t) ) - zero
         else
             t_prev = time_v( index_t(iso_t) ) - time_v( index_t(iso_t-1) )
         endif ! back if ( iso_t == 1 ) block
         call istack_getter( empty_v, istack_gettop( empty_v ) - 2, as )
         time_v(as) = time_v( index_t(iso_t) )
         flvr_v(as) = flvr_v( index_t(iso_t) )
         type_v(as) = type_v( index_t(iso_t) )
         index_t(iso_t) = as
         do i=1,ncfgs
             expt_v( i, as ) = exp ( -eigs(i) * t_prev )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( iso < nsize .and. iso /= isn ) block

! update the final time evolution operator
     t_next = time_v( index_t(nsize) )
     do i=1,ncfgs
         expt_t( i, 1 ) = exp ( -eigs(i) * ( beta - t_next ) )
     enddo ! over i={1,ncfgs} loop

!-------------------------------------------------------------------------
! stage 3: evaluate trace ratio
!-------------------------------------------------------------------------
! calculate new matrix trace for the flavor part
     call ctqmc_make_ztrace(1, nsize, matrix_ntrace, tau_start1, tau_start2)

! evaluate trace_ratio
     trace_ratio = matrix_ntrace / matrix_ptrace

     return
  end subroutine cat_lshift_ztrace

!!>>> cat_rshift_ztrace: calculate the trace ratio for shift old destroy
!!>>> operators on perturbation expansion series
  subroutine cat_rshift_ztrace(flvr, ieo, ien, tau_end1, tau_end2, trace_ratio)
     use constants, only : dp, zero
     use stack, only : istack_getrest, istack_gettop, istack_getter

     use control, only : ncfgs
     use control, only : beta
     use context, only : matrix_ptrace, matrix_ntrace
     use context, only : empty_v, index_t, index_v, type_v, flvr_v, time_v, expt_t, expt_v
     use context, only : eigs

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address to shift existing destroy operator
! ieo and ien are for old and new destroy operators, respectively
     integer, intent(in)   :: ieo
     integer, intent(in)   :: ien

! imaginary time point of the old destroy operator
     real(dp), intent(in)  :: tau_end1

! imaginary time point of the new destroy operator
     real(dp), intent(in)  :: tau_end2

! ratio between old and new configurations, the local trace part
     real(dp), intent(out) :: trace_ratio

! local variables
! loop index over operators
     integer  :: i

! memory address for old and new destroy operators
     integer  :: ae

! index address for old destroy operator
     integer  :: ieo_t

! total number of operators
     integer  :: nsize

! imaginary time interval for two successive operators
! t_prev stands for t_{i} - t_{i-1), and t_next stands for t_{i+1} - t_{i}
     real(dp) :: t_prev
     real(dp) :: t_next

! determine nsize at first, get total number of operators
     nsize = istack_getrest( empty_v )

! copy index_v to index_t
! since we do not shift the destroy operator actually at this stage, so
! index_v can not be overwritten here
     do i=1,nsize
         index_t(i) = index_v(i)
     enddo ! over i={1,nsize} loop

!-------------------------------------------------------------------------
! stage 1: shift old destroy operator, trial step
!-------------------------------------------------------------------------
! get memory address for destroy operator
     call istack_getter( empty_v, istack_gettop( empty_v ) - 0, ae )

! store basic data for new destroy operator
     time_v(ae) = tau_end2
     flvr_v(ae) = flvr
     type_v(ae) = 0

! remove the unused index address from index_t
     do i=ieo,nsize-1
         index_t(i) = index_t(i+1)
     enddo ! over i={ieo,nsize-1} loop
     index_t(nsize) = 0

! shift index_t to make an empty room
     do i=nsize-1,ien,-1
         index_t(i+1) = index_t(i)
     enddo ! over i={nsize-1,ien,-1} loop

! store the memory address for destroy operator
     index_t(ien) = ae

! evaluate previous imaginary time interval
     if ( ien == 1 ) then ! the imaginary time of destroy operator is the smallest
         t_prev = time_v( index_t(ien) ) - zero
     else
         t_prev = time_v( index_t(ien) ) - time_v( index_t(ien-1) )
     endif ! back if ( ien == 1 ) block

! update the expt_v, matrix of time evolution operator
     do i=1,ncfgs
         expt_v( i, ae ) = exp ( -eigs(i) * t_prev )
     enddo ! over i={1,ncfgs} loop

!-------------------------------------------------------------------------
! stage 2: auxiliary tasks
!-------------------------------------------------------------------------
! its neighbor needs to be changes as well.
! makes a copy of time and type, and changes time evolution operator
     if ( ien < nsize ) then
         t_next = time_v( index_t(ien+1) ) - time_v( index_t(ien) )
         call istack_getter( empty_v, istack_gettop( empty_v ) - 1, ae )
         time_v(ae) = time_v( index_t(ien+1) )
         flvr_v(ae) = flvr_v( index_t(ien+1) )
         type_v(ae) = type_v( index_t(ien+1) )
         index_t(ien+1) = ae
         do i=1,ncfgs
             expt_v( i, ae ) = exp ( -eigs(i) * t_next )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( ien < nsize ) block

! the operator closest to the old place needs to be changed as well
     if ( ieo < nsize .and. ieo /= ien ) then
         if ( ieo > ien ) then
             ieo_t = ieo + 1
         else
             ieo_t = ieo
         endif ! back if ( ieo > ien ) block
         if ( ieo_t == 1 ) then
             t_prev = time_v( index_t(ieo_t) ) - zero
         else
             t_prev = time_v( index_t(ieo_t) ) - time_v( index_t(ieo_t-1) )
         endif ! back if ( ieo_t == 1 ) block
         call istack_getter( empty_v, istack_gettop( empty_v ) - 2, ae )
         time_v(ae) = time_v( index_t(ieo_t) )
         flvr_v(ae) = flvr_v( index_t(ieo_t) )
         type_v(ae) = type_v( index_t(ieo_t) )
         index_t(ieo_t) = ae
         do i=1,ncfgs
             expt_v( i, ae ) = exp ( -eigs(i) * t_prev )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( ieo < nsize .and. ieo /= ien ) block

! update the final time evolution operator
     t_next = time_v( index_t(nsize) )
     do i=1,ncfgs
         expt_t( i, 1 ) = exp ( -eigs(i) * (beta - t_next) )
     enddo ! over i={1,ncfgs} loop

!-------------------------------------------------------------------------
! stage 3: evaluate trace ratio
!-------------------------------------------------------------------------
! calculate new matrix trace for the flavor part
     call ctqmc_make_ztrace(1, nsize, matrix_ntrace, tau_end1, tau_end2)

! evaluate trace_ratio
     trace_ratio = matrix_ntrace / matrix_ptrace

     return
  end subroutine cat_rshift_ztrace

!!========================================================================
!!>>> service layer: update perturbation expansion series A            <<<
!!========================================================================

!!>>> try_insert_colour: generate create and destroy operators for selected
!!>>> flavor channel randomly, and then determinte their index address for
!!>>> the colour (determinant) part
  subroutine try_insert_colour(flvr, is, ie, tau_start, tau_end)
     use constants, only : dp, epss
     use spring, only : spring_sfmt_stream

     use control, only : beta
     use context, only : ckink
     use context, only : index_s, index_e, time_s, time_e

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address to insert new create and destroy operators
! is and ie are for create and destroy operators, respectively
     integer, intent(out)  :: is
     integer, intent(out)  :: ie

! imaginary time point of the new create operator
     real(dp), intent(out) :: tau_start

! imaginary time point of the new destroy operator
     real(dp), intent(out) :: tau_end

! local variables
! loop index over operators
     integer :: i

! determine if tau_start or tau_end is collided with existed operators
     integer :: have

! initialize is and ie
     is = 1
     ie = 1

! select imaginary time of the new create operator randomly
! check tau_start is necessary
     have = 99
     creator :   do while ( have > 0 )
         tau_start = spring_sfmt_stream() * beta
         call ctqmc_make_equate(flvr, tau_start, have)
     enddo creator ! over do while loop

! select imaginary time of the new destroy operator randomly
! check tau_end is necessary
     have = 99
     destroyer : do while ( have > 0 )
         tau_end = spring_sfmt_stream() * beta
         call ctqmc_make_equate(flvr, tau_end  , have)
! we need to ensure tau_start is not equal to tau_end
         if ( abs( tau_start - tau_end ) < epss ) then
             have = 99
         endif ! back if ( abs( tau_start - tau_end ) < epss ) block
     enddo destroyer ! over do while loop

! determine the new position (index address, is) of tau_start in time_s
     if ( ckink > 0 ) then
         if      ( tau_start < time_s(index_s(1,     flvr), flvr) ) then
             is = 1
         else if ( tau_start > time_s(index_s(ckink, flvr), flvr) ) then
             is = ckink + 1
         else
             i = 1
             do while ( time_s(index_s(i, flvr), flvr) < tau_start )
                 i = i + 1
             enddo ! over do while loop
             is = i
         endif ! back if      ( tau_start < time_s(index_s(1,     flvr), flvr) ) block
     endif ! back if ( ckink > 0 ) block

! determine the new position (index address, ie) of tau_end in time_e
     if ( ckink > 0 ) then
         if      ( tau_end < time_e(index_e(1,     flvr), flvr) ) then
             ie = 1
         else if ( tau_end > time_e(index_e(ckink, flvr), flvr) ) then
             ie = ckink + 1
         else
             i = 1
             do while ( time_e(index_e(i, flvr), flvr) < tau_end   )
                 i = i + 1
             enddo ! over do while loop
             ie = i
         endif ! back if      ( tau_end < time_e(index_e(1,     flvr), flvr) ) block
     endif ! back if ( ckink > 0 ) block

! check the validity of tau_start and tau_end
     if ( abs( tau_start - tau_end ) < epss ) then
         call s_print_error('try_insert_colour','tau_start is equal to tau_end')
     endif ! back if ( abs( tau_start - tau_end ) < epss ) block

     return
  end subroutine try_insert_colour

!!>>> try_remove_colour: select index address is and ie for selected
!!>>> flavor channel randomly, and then determine their imaginary time
!!>>> points for the colour (determinant) part
  subroutine try_remove_colour(flvr, is, ie, tau_start, tau_end)
     use constants, only : dp, epss
     use spring, only : spring_sfmt_stream

     use context, only : ckink
     use context, only : index_s, index_e, time_s, time_e

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address to remove old create and destroy operators
! is and ie are for create and destroy operators, respectively
     integer, intent(out)  :: is
     integer, intent(out)  :: ie

! imaginary time point of the old create operator
     real(dp), intent(out) :: tau_start

! imaginary time point of the old destroy operator
     real(dp), intent(out) :: tau_end

! randomly select index address, which is used to access the create operators
     is = ceiling( spring_sfmt_stream() * ckink )

! randomly select index address, which is used to access the destroy operators
     ie = ceiling( spring_sfmt_stream() * ckink )

! evaluate tau_start and tau_end respectively
     tau_start = time_s( index_s(is, flvr), flvr )
     tau_end   = time_e( index_e(ie, flvr), flvr )

! check the validity of tau_start and tau_end
     if ( abs( tau_start - tau_end ) < epss ) then
         call s_print_error('try_remove_colour','tau_start is equal to tau_end')
     endif ! back if ( abs( tau_start - tau_end ) < epss ) block

     return
  end subroutine try_remove_colour

!!>>> try_lshift_colour: select index address isn for selected flavor
!!>>> channel randomly, and then determine its imaginary time points,
!!>>> shift it randomly, and then evaluate its final index address for
!!>>> the colour (determinant) part
  subroutine try_lshift_colour(flvr, iso, isn, tau_start1, tau_start2)
     use constants, only : dp, zero
     use spring, only : spring_sfmt_stream

     use control, only : beta
     use context, only : ckink
     use context, only : index_s, time_s

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address to shift old create operator
! iso and isn are for old and new indices, respectively
     integer, intent(out)  :: iso
     integer, intent(out)  :: isn

! imaginary time point of the selected create operator (the old one)
     real(dp), intent(out) :: tau_start1

! imaginary time point of the selected create operator (the new one)
     real(dp), intent(out) :: tau_start2

! local variables
! determine if tau_start2 is collided with existed operators
     integer  :: have

! imaginary time of previous create operator
     real(dp) :: tau_prev

! imaginary time of next create operator
     real(dp) :: tau_next

! randomly select index address, which is used to access the create operators
     iso = ceiling( spring_sfmt_stream() * ckink )

! evaluate tau_start1
     tau_start1 = time_s( index_s(iso, flvr), flvr )

! determine imaginary time and index address for new create operator
     have = 99
     creator : do while ( have > 0 )
         if ( ckink == 1 ) then
             isn = 1
             tau_start2 = spring_sfmt_stream() * beta
         else
             if      ( iso == 1     ) then
                 tau_prev = time_s( index_s(ckink, flvr), flvr )
                 tau_next = time_s( index_s(iso+1, flvr), flvr )
                 tau_start2 = tau_prev + ( tau_next - zero + beta - tau_prev ) * spring_sfmt_stream()
                 if ( tau_start2 > beta ) then
                     isn = 1
                     tau_start2 = tau_start2 - beta
                 else
                     isn = ckink
                 endif ! back if ( tau_start2 > beta ) block
             else if ( iso == ckink ) then
                 tau_prev = time_s( index_s(iso-1, flvr), flvr )
                 tau_next = time_s( index_s(1,     flvr), flvr )
                 tau_start2 = tau_prev + ( tau_next - zero + beta - tau_prev ) * spring_sfmt_stream()
                 if ( tau_start2 > beta ) then
                     isn = 1
                     tau_start2 = tau_start2 - beta
                 else
                     isn = ckink
                 endif ! back if ( tau_start2 > beta ) block
             else
                 tau_prev = time_s( index_s(iso-1, flvr), flvr )
                 tau_next = time_s( index_s(iso+1, flvr), flvr )
                 tau_start2 = tau_prev + ( tau_next - tau_prev ) * spring_sfmt_stream()
                 isn = iso
             endif ! back if ( iso == 1 ) block
         endif ! back if ( ckink == 1 ) block

! check tau_start2 is necessary
         call ctqmc_make_equate(flvr, tau_start2, have)
     enddo creator ! over do while loop

     return
  end subroutine try_lshift_colour

!!>>> try_rshift_colour: select index address ien for selected flavor
!!>>> channel randomly, and then determine its imaginary time points,
!!>>> shift it randomly, and then evaluate its final index address for
!!>>> the colour (determinant) part
  subroutine try_rshift_colour(flvr, ieo, ien, tau_end1, tau_end2)
     use constants, only : dp, zero
     use spring, only : spring_sfmt_stream

     use control, only : beta
     use context, only : ckink
     use context, only : index_e, time_e

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address to shift old destroy operator
! ieo and ien are for old and new indices, respectively
     integer, intent(out)  :: ieo
     integer, intent(out)  :: ien

! imaginary time point of the selected destroy operator (the old one)
     real(dp), intent(out) :: tau_end1

! imaginary time point of the selected destroy operator (the new one)
     real(dp), intent(out) :: tau_end2

! local variables
! determine if tau_end2 is collided with existed operators
     integer  :: have

! imaginary time of previous destroy operator
     real(dp) :: tau_prev

! imaginary time of next destroy operator
     real(dp) :: tau_next

! randomly select index address, which is used to access the destroy operators
     ieo = ceiling( spring_sfmt_stream() * ckink )

! evaluate tau_end1
     tau_end1 = time_e( index_e(ieo, flvr), flvr )

! determine imaginary time and index address for new destroy operator
     have = 99
     destroyer : do while ( have > 0 )
         if ( ckink == 1 ) then
             ien = 1
             tau_end2 = spring_sfmt_stream() * beta
         else
             if      ( ieo == 1     ) then
                 tau_prev = time_e( index_e(ckink, flvr), flvr )
                 tau_next = time_e( index_e(ieo+1, flvr), flvr )
                 tau_end2 = tau_prev + ( tau_next - zero + beta - tau_prev ) * spring_sfmt_stream()
                 if ( tau_end2 > beta ) then
                     ien = 1
                     tau_end2 = tau_end2 - beta
                 else
                     ien = ckink
                 endif ! back if ( tau_end2 > beta ) block
             else if ( ieo == ckink ) then
                 tau_prev = time_e( index_e(ieo-1, flvr), flvr )
                 tau_next = time_e( index_e(1,     flvr), flvr )
                 tau_end2 = tau_prev + ( tau_next - zero + beta - tau_prev ) * spring_sfmt_stream()
                 if ( tau_end2 > beta ) then
                     ien = 1
                     tau_end2 = tau_end2 - beta
                 else
                     ien = ckink
                 endif ! back if ( tau_end2 > beta ) block
             else
                 tau_prev = time_e( index_e(ieo-1, flvr), flvr )
                 tau_next = time_e( index_e(ieo+1, flvr), flvr )
                 tau_end2 = tau_prev + ( tau_next - tau_prev ) * spring_sfmt_stream()
                 ien = ieo
             endif ! back if ( ieo == 1 ) block
         endif ! back if ( ckink == 1 ) block

! check tau_end2 is necessary
         call ctqmc_make_equate(flvr, tau_end2, have)
     enddo destroyer ! over do while loop

     return
  end subroutine try_rshift_colour

!!========================================================================
!!>>> service layer: update perturbation expansion series B            <<<
!!========================================================================

!!>>> cat_insert_colour: update the perturbation expansion series for
!!>>> insert new create and destroy operators in the colour part actually
  subroutine cat_insert_colour(flvr, is, ie, tau_start, tau_end)
     use constants, only : dp
     use stack, only : istack_pop

     use control, only : nfreq
     use context, only : ckink
     use context, only : empty_s, empty_e, index_s, index_e, time_s, time_e, exp_s, exp_e
     use context, only : rmesh

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address for insert new create and destroy operators
     integer, intent(in)  :: is
     integer, intent(in)  :: ie

! imaginary time \tau_s for create operator
     real(dp), intent(in) :: tau_start

! imaginary time \tau_e for destroy operator
     real(dp), intent(in) :: tau_end

! local variables
! loop index over operators and frequencies
     integer  :: i

! memory address for new create and destroy operators
     integer  :: as
     integer  :: ae

! dummy variables, \tau_s * \omega and \tau_e * \omega
     real(dp) :: xs
     real(dp) :: xe

! get memory address for is and ie
     call istack_pop( empty_s(flvr), as )
     call istack_pop( empty_e(flvr), ae )

! shift index_s and index_e to create two empty rooms for as and ae
     do i=ckink,is,-1
         index_s(i+1, flvr) = index_s(i, flvr)
     enddo ! over i={ckink,is,-1} loop

     do i=ckink,ie,-1
         index_e(i+1, flvr) = index_e(i, flvr)
     enddo ! over i={ckink,ie,-1} loop

! update index_s and index_e at is and ie by as and ae, respectively
     index_s(is, flvr) = as
     index_e(ie, flvr) = ae

! update time_s and time_e, record new imaginary time points
     time_s(as, flvr) = tau_start
     time_e(ae, flvr) = tau_end

! update exp_s and exp_e, record new exponent values
     do i=1,nfreq
         xs = rmesh(i) * tau_start
         exp_s(i, as, flvr) = dcmplx( cos(xs), sin(xs) )

         xe = rmesh(i) * tau_end
         exp_e(i, ae, flvr) = dcmplx( cos(xe), sin(xe) )
     enddo ! over i={1,nfreq} loop

     return
  end subroutine cat_insert_colour

!!>>> cat_remove_colour: update the perturbation expansion series for
!!>>> remove old create and destroy operators in the colour part actually
  subroutine cat_remove_colour(flvr, is, ie)
     use stack, only : istack_push

     use context, only : ckink
     use context, only : empty_s, empty_e, index_s, index_e

     implicit none

! external arguments
! current flavor channel
     integer, intent(in) :: flvr

! index address for remove old create and destroy operators
     integer, intent(in) :: is
     integer, intent(in) :: ie

! local variables
! loop index over operators
     integer :: i

! memory address for old create and destroy operators
     integer :: as
     integer :: ae

! get memory address for is and ie
     as = index_s(is, flvr)
     ae = index_e(ie, flvr)

! push the memory address back to the empty_s and empty_e stacks
     call istack_push( empty_s(flvr), as )
     call istack_push( empty_e(flvr), ae )

! remove the unused index from index_s and index_e
     do i=is,ckink-1
         index_s(i, flvr) = index_s(i+1, flvr)
     enddo ! over i={is,ckink-1} loop
     index_s(ckink, flvr) = 0

     do i=ie,ckink-1
         index_e(i, flvr) = index_e(i+1, flvr)
     enddo ! over i={ie,ckink-1} loop
     index_e(ckink, flvr) = 0

     return
  end subroutine cat_remove_colour

!!>>> cat_lshift_colour: update the perturbation expansion series for
!!>>> lshift an old create operators in the colour part actually
  subroutine cat_lshift_colour(flvr, iso, isn, tau_start)
     use constants, only : dp

     use control, only : nfreq
     use context, only : ckink
     use context, only : index_s, time_s, exp_s
     use context, only : rmesh

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address for lshift old create operator
     integer, intent(in)  :: iso
     integer, intent(in)  :: isn

! imaginary time \tau_s for create operator (the new one)
     real(dp), intent(in) :: tau_start

! local variables
! loop index over operators and frequencies
     integer  :: i

! memory address for new create operator
     integer  :: as

! dummy variables, \tau_s * \omega
     real(dp) :: xs

! get memory address for iso
     as = index_s(iso, flvr)

! update index_s
     do i=iso,ckink-1
         index_s(i, flvr) = index_s(i+1, flvr)
     enddo ! over i={iso,ckink-1} loop
     index_s(ckink, flvr) = 0

     do i=ckink-1,isn,-1
         index_s(i+1, flvr) = index_s(i, flvr)
     enddo ! over i={ckink-1,isn,-1} loop
     index_s(isn, flvr) = as

! update time_s, record new imaginary time point
     time_s(as, flvr) = tau_start

! update exp_s, record new exponent values
     do i=1,nfreq
         xs = rmesh(i) * tau_start
         exp_s(i, as, flvr) = dcmplx( cos(xs), sin(xs) )
     enddo ! over i={1,nfreq} loop

     return
  end subroutine cat_lshift_colour

!!>>> cat_rshift_colour: update the perturbation expansion series for
!!>>> rshift an old destroy operators in the colour part actually
  subroutine cat_rshift_colour(flvr, ieo, ien, tau_end)
     use constants, only : dp

     use control, only : nfreq
     use context, only : ckink
     use context, only : index_e, time_e, exp_e
     use context, only : rmesh

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address for rshift old destroy operator
     integer, intent(in)  :: ieo
     integer, intent(in)  :: ien

! imaginary time \tau_e for destroy operator (the new one)
     real(dp), intent(in) :: tau_end

! local variables
! loop index over operators and frequencies
     integer  :: i

! memory address for new destroy operator
     integer  :: ae

! dummy variables, \tau_e * \omega
     real(dp) :: xe

! get memory address for ieo
     ae = index_e(ieo, flvr)

! update index_e
     do i=ieo,ckink-1
         index_e(i, flvr) = index_e(i+1, flvr)
     enddo ! over i={ieo,ckink-1} loop
     index_e(ckink, flvr) = 0

     do i=ckink-1,ien,-1
         index_e(i+1, flvr) = index_e(i, flvr)
     enddo ! over i={ckink-1,ien,-1} loop
     index_e(ien, flvr) = ae

! update time_e, record new imaginary time point
     time_e(ae, flvr) = tau_end

! update exp_e, record new exponent values
     do i=1,nfreq
         xe = rmesh(i) * tau_end
         exp_e(i, ae, flvr) = dcmplx( cos(xe), sin(xe) )
     enddo ! over i={1,nfreq} loop

     return
  end subroutine cat_rshift_colour

!!========================================================================
!!>>> service layer: update perturbation expansion series C            <<<
!!========================================================================

!!>>> try_insert_flavor: determine index addresses for the new create and
!!>>> destroy operators in the flavor part, and then determine whether
!!>>> they can be inserted diagrammatically
  subroutine try_insert_flavor(flvr, is, ie, tau_start, tau_end, ladd)
     use constants, only : dp
     use stack, only : istack_getrest

     use control, only : nband
     use context, only : cssoc
     use context, only : empty_v, index_v, type_v, flvr_v, time_v

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address to insert new create and destroy operators
! is and ie are for create and destroy operators, respectively
     integer, intent(out) :: is
     integer, intent(out) :: ie

! whether the new create and destroy operators can be inserted diagrammatically
     logical, intent(out) :: ladd

! imaginary time point of the new create operator
     real(dp), intent(in) :: tau_start

! imaginary time point of the new destroy operator
     real(dp), intent(in) :: tau_end

! local variables
! loop index over operators
     integer :: i

! loop index over orbitals
     integer :: m
     integer :: n

! pseudo-index address for create and destroy operators, respectively
     integer :: pis
     integer :: pie

! total number of operators in the flavor part
     integer :: nsize

! dummy variables, used to check whether current subspace can survive
     integer :: idead

! dummy variables, used to resolve spin up and spin down states
     integer :: iupdn

! dummy variables, operator index, used to loop over the flavor part
     integer :: counter

! subspace constructed by nup and ndn
     integer :: nupdn(2)

! init ladd
     ladd = .false.

! determine nsize at first, get total number of operators
     nsize = istack_getrest( empty_v )

!-------------------------------------------------------------------------
! stage 1: determine is and ie, where are they ?
!-------------------------------------------------------------------------
! determine is
     is = 1
     if ( nsize > 0 ) then
         if      ( tau_start < time_v( index_v(1)     ) ) then
             is = 1          ! it is the first operator
         else if ( tau_start > time_v( index_v(nsize) ) ) then
             is = nsize + 1  ! it is the last  operator
         else
             i = 1
             do while ( time_v( index_v(i) ) < tau_start )
                 i = i + 1
             enddo ! over do while loop
             is = i
         endif ! back if ( tau_start < time_v( index_v(1) ) ) block
     endif ! back if ( nsize > 0 ) block

! determine ie
     ie = 1
     if ( nsize > 0 ) then
         if      ( tau_end < time_v( index_v(1)     ) ) then
             ie = 1          ! it is the first operator
         else if ( tau_end > time_v( index_v(nsize) ) ) then
             ie = nsize + 1  ! it is the last  operator
         else
             i = 1
             do while ( time_v( index_v(i) ) < tau_end )
                 i = i + 1
             enddo ! over do while loop
             ie = i
         endif ! back if ( tau_end < time_v( index_v(1) ) ) block
     endif ! back if ( nsize > 0 ) block

! adjust ie further, since we insert create operator firstly, and then
! insert destroy operator
     if ( tau_start < tau_end ) then
         ie = ie + 1
     endif ! back if ( tau_start < tau_end ) block

!-------------------------------------------------------------------------
! stage 2: determine ladd, whether we can get them ?
!-------------------------------------------------------------------------
! for the spin-orbital coupling case, we can not lookup the operators
! series quickly
     if ( cssoc == 1 ) then
         ladd = .true.; RETURN
     endif ! back if ( cssoc == 1 ) block

! evaluate pis and pie
     pis = is
     pie = ie
     if ( tau_start > tau_end ) then
         pis = pis + 1
     endif ! back if ( tau_start > tau_end ) block

! loop over all the subspace
     do m=0,nband
         do n=0,nband

! construct current subspace
             nupdn(1) = m
             nupdn(2) = n

! init key variables
             idead = 0
             counter = 0

! loop over all the operators, simulate their actions on subspace
             do i=1,nsize+2
                 counter = counter + 1

! meet the new create operator
                 if      ( i == pis ) then
                     counter = counter - 1
                     iupdn = (flvr - 1) / nband + 1
                     nupdn(iupdn) = nupdn(iupdn) + 1
! meet the new destroy operator
                 else if ( i == pie ) then
                     counter = counter - 1
                     iupdn = (flvr - 1) / nband + 1
                     nupdn(iupdn) = nupdn(iupdn) - 1
! meet other existing operators
                 else
                     iupdn = ( flvr_v( index_v(counter) ) - 1 ) / nband + 1
                     nupdn(iupdn) = nupdn(iupdn) + 2 * type_v( index_v(counter) ) - 1
                 endif ! back if ( i == pis ) block

! determine whether the final subspace is valid yet
                 if ( nupdn(iupdn) < 0 .or. nupdn(iupdn) > nband ) EXIT
                 idead = idead + 1
             enddo ! over i={1,nsize+2} loop

! once current subspace can survive, in order to save computational time,
! we return immediately, no need to deal with the rest subspaces
             if ( idead == nsize + 2 ) then
                 ladd = .true.; RETURN
             endif ! back if ( idead == nsize + 2 ) block

         enddo ! over n={0,nband} loop
     enddo ! over m={0,nband} loop

     return
  end subroutine try_insert_flavor

!!>>> try_remove_flavor: determine index addresses for the new create and
!!>>> destroy operators in the flavor part, and then determine whether
!!>>> they can be inserted diagrammatically
  subroutine try_remove_flavor(is, ie, tau_start, tau_end, lrmv)
     use constants, only : dp
     use stack, only : istack_getrest

     use control, only : nband
     use context, only : cssoc
     use context, only : empty_v, index_v, type_v, flvr_v

     implicit none

! external arguments
! index address to remove old create and destroy operators
! is and ie are for create and destroy operators, respectively
     integer, intent(out) :: is
     integer, intent(out) :: ie

! whether the old create and destroy operators can be removed diagrammatically
     logical, intent(out) :: lrmv

! imaginary time point of the old create operator
     real(dp), intent(in) :: tau_start

! imaginary time point of the old destroy operator
     real(dp), intent(in) :: tau_end

! local variables
! loop index over operators
     integer :: i

! loop index over orbitals
     integer :: m
     integer :: n

! pseudo-index address for create and destroy operators, respectively
     integer :: pis
     integer :: pie

! total number of operators in the flavor part
     integer :: nsize

! dummy variables, used to check whether current subspace can survive
     integer :: idead

! dummy variables, used to resolve spin up and spin down states
     integer :: iupdn

! subspace constructed by nup and ndn
     integer :: nupdn(2)

! init lrmv
     lrmv = .false.

! determine nsize at first, get total number of operators
     nsize = istack_getrest( empty_v )

!-------------------------------------------------------------------------
! stage 1: determine is and ie, where are they ?
!-------------------------------------------------------------------------
! determine is
!<     i = 1
!<     do while ( i <= nsize .and. abs( time_v( index_v(i) ) - tau_start ) > eps6 )
!<         i = i + 1
!<     enddo ! over do while loop
!<     is = i
     call ctqmc_make_search( is, nsize, tau_start )

! determine ie
!<     i = 1
!<     do while ( i <= nsize .and. abs( time_v( index_v(i) ) - tau_end   ) > eps6 )
!<         i = i + 1
!<     enddo ! over do while loop
!<     ie = i
     call ctqmc_make_search( ie, nsize, tau_end )

! adjust ie further, since we remove create operator firstly, and then
! remove destroy operator
     if ( tau_start < tau_end ) then
         ie = ie - 1
     endif ! back if ( tau_start < tau_end ) block

!-------------------------------------------------------------------------
! stage 2: determine lrmv, whether we can kick off them ?
!-------------------------------------------------------------------------
! for the spin-orbital coupling case, we can not lookup the operators
! series quickly
     if ( cssoc == 1 ) then
         lrmv = .true.; RETURN
     endif ! back if ( cssoc == 1 ) block

! evaluate pis and pie
     pis = is
     pie = ie
     if ( tau_start < tau_end ) then
         pie = pie + 1
     endif ! back if ( tau_start < tau_end ) block

! loop over all the subspace
     do m=0,nband
         do n=0,nband

! construct current subspace
             nupdn(1) = m
             nupdn(2) = n

! init key variables
             idead = 0

! loop over all the operators, simulate their actions on subspace
             do i=1,nsize
                 if ( i == pis .or. i == pie ) then
                     idead = idead + 1
                 else
                     iupdn = ( flvr_v( index_v(i) ) - 1 ) / nband + 1
                     nupdn(iupdn) = nupdn(iupdn) + 2 * type_v( index_v(i) ) - 1
                     if ( nupdn(iupdn) < 0 .or. nupdn(iupdn) > nband ) EXIT
                     idead = idead + 1
                 endif ! back if ( i == pis .or. i == pie ) block
             enddo ! over i={1,nsize} loop

! once current subspace can survive, in order to save computational time,
! we return immediately, no need to deal with the rest subspaces
             if ( idead == nsize ) then
                 lrmv = .true.; RETURN
             endif ! back if ( idead == nsize ) block

         enddo ! over n={0,nband} loop
     enddo ! over m={0,nband} loop

     return
  end subroutine try_remove_flavor

!!>>> try_lshift_flavor: determine index addresses for the old and new
!!>>> create operators in the flavor part, and then determine whether it
!!>>> can be shifted diagrammatically
  subroutine try_lshift_flavor(flvr, iso, isn, tau_start1, tau_start2, lshf)
     use constants, only : dp
     use stack, only : istack_getrest

     use control, only : nband
     use context, only : cssoc
     use context, only : empty_v, index_v, type_v, flvr_v, time_v

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address to shift existing create operator
! iso and isn are for old and new create operators, respectively
     integer, intent(out) :: iso
     integer, intent(out) :: isn

! whether the old create operators can be shifted diagrammatically
     logical, intent(out) :: lshf

! imaginary time point of the old create operator
     real(dp), intent(in) :: tau_start1

! imaginary time point of the new create operator
     real(dp), intent(in) :: tau_start2

! local variables
! loop index over operators
     integer :: i

! loop index over orbitals
     integer :: m
     integer :: n

! pseudo-index address for old and new create operators, respectively
     integer :: piso
     integer :: pisn

! total number of operators in the flavor part
     integer :: nsize

! dummy variables, used to check whether current subspace can survive
     integer :: idead

! dummy variables, used to resolve spin up and spin down states
     integer :: iupdn

! dummy variables, operator index, used to loop over the flavor part
     integer :: counter

! subspace constructed by nup and ndn
     integer :: nupdn(2)

! init lshf
     lshf = .false.

! determine nsize at first, get total number of operators
     nsize = istack_getrest( empty_v )

!-------------------------------------------------------------------------
! stage 1: determine iso and isn, where are they ?
!-------------------------------------------------------------------------
! determine iso
!<     i = 1
!<     do while ( i <= nsize .and. abs( time_v( index_v(i) ) - tau_start1 ) > eps6 )
!<         i = i + 1
!<     enddo ! over do while loop
!<     iso = i
     call ctqmc_make_search( iso, nsize, tau_start1 )

! determine isn
     isn = 1
     if ( nsize > 0 ) then
         if      ( tau_start2 < time_v( index_v(1)     ) ) then
             isn = 1          ! it is the first operator
         else if ( tau_start2 > time_v( index_v(nsize) ) ) then
             isn = nsize + 1  ! it is the last  operator
         else
             i = 1
             do while ( time_v( index_v(i) ) < tau_start2 )
                 i = i + 1
             enddo ! over do while loop
             isn = i
         endif ! back if ( tau_start2 < time_v( index_v(1) ) ) block
     endif ! back if ( nsize > 0 ) block

! adjust isn further
     if ( tau_start1 < tau_start2 ) then
         isn = isn - 1
     endif ! back if ( tau_start1 < tau_start2 ) block

!-------------------------------------------------------------------------
! stage 2: determine lshf, whether we can shift it ?
!-------------------------------------------------------------------------
! for the spin-orbital coupling case, we can not lookup the operators
! series quickly
     if ( cssoc == 1 ) then
         lshf = .true.; RETURN
     endif ! back if ( cssoc == 1 ) block

! evaluate piso and pisn
     piso = iso
     pisn = isn
     if ( tau_start1 < tau_start2 ) then
         pisn = pisn + 1
     else
         piso = piso + 1
     endif ! back if ( tau_start1 < tau_start2 ) block

! loop over all the subspace
     do m=0,nband
         do n=0,nband

! construct current subspace
             nupdn(1) = m
             nupdn(2) = n

! init key variables
             idead = 0
             counter = 0

! loop over all the operators, simulate their actions on subspace
             do i=1,nsize+1
                 counter = counter + 1

! meet the old create operator
                 if      ( i == piso ) then
                     idead = idead + 1
! meet the new create operator
                 else if ( i == pisn ) then
                     counter = counter - 1
                     iupdn = (flvr - 1) / nband + 1
                     nupdn(iupdn) = nupdn(iupdn) + 1
                     if ( nupdn(iupdn) < 0 .or. nupdn(iupdn) > nband ) EXIT
                     idead = idead + 1
! meet other existing operators
                 else
                     iupdn = ( flvr_v( index_v(counter) ) - 1 ) / nband + 1
                     nupdn(iupdn) = nupdn(iupdn) + 2 * type_v( index_v(counter) ) - 1
                     if ( nupdn(iupdn) < 0 .or. nupdn(iupdn) > nband ) EXIT
                     idead = idead + 1
                 endif ! back if ( i == piso ) block
             enddo ! over i={1,nsize+1} loop

! once current subspace can survive, in order to save computational time,
! we return immediately, no need to deal with the rest subspaces
             if ( idead == nsize + 1 ) then
                 lshf = .true.; RETURN
             endif ! back if ( idead == nsize + 1 ) block

         enddo ! over n={0,nband} loop
     enddo ! over m={0,nband} loop

     return
  end subroutine try_lshift_flavor

!!>>> try_rshift_flavor: determine index addresses for the old and new
!!>>> destroy operators in the flavor part, and then determine whether
!!>>> it can be shifted diagrammatically
  subroutine try_rshift_flavor(flvr, ieo, ien, tau_end1, tau_end2, rshf)
     use constants, only : dp
     use stack, only : istack_getrest

     use control, only : nband
     use context, only : cssoc
     use context, only : empty_v, index_v, type_v, flvr_v, time_v, time_v

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address to shift existing destroy operator
! ieo and ien are for old and new destroy operators, respectively
     integer, intent(out) :: ieo
     integer, intent(out) :: ien

! whether the old destroy operators can be shifted diagrammatically
     logical, intent(out) :: rshf

! imaginary time point of the old destroy operator
     real(dp), intent(in) :: tau_end1

! imaginary time point of the new destroy operator
     real(dp), intent(in) :: tau_end2

! local variables
! loop index over operators
     integer :: i

! loop index over orbitals
     integer :: m
     integer :: n

! pseudo-index address for old and new destroy operators, respectively
     integer :: pieo
     integer :: pien

! total number of operators in the flavor part
     integer :: nsize

! dummy variables, used to check whether current subspace can survive
     integer :: idead

! dummy variables, used to resolve spin up and spin down states
     integer :: iupdn

! dummy variables, operator index, used to loop over the flavor part
     integer :: counter

! subspace constructed by nup and ndn
     integer :: nupdn(2)

! init rshf
     rshf = .false.

! determine nsize at first, get total number of operators
     nsize = istack_getrest( empty_v )

!-------------------------------------------------------------------------
! stage 1: determine ieo and ien, where are they ?
!-------------------------------------------------------------------------
! determine ieo
!<     i = 1
!<     do while ( i <= nsize .and. abs( time_v( index_v(i) ) - tau_end1 ) > eps6 )
!<         i = i + 1
!<     enddo ! over do while loop
!<     ieo = i
     call ctqmc_make_search( ieo, nsize, tau_end1 )

! determine ien
     ien = 1
     if ( nsize > 0 ) then
         if      ( tau_end2 < time_v( index_v(1)     ) ) then
             ien = 1          ! it is the first operator
         else if ( tau_end2 > time_v( index_v(nsize) ) ) then
             ien = nsize + 1  ! it is the last  operator
         else
             i = 1
             do while ( time_v( index_v(i) ) < tau_end2 )
                 i = i + 1
             enddo ! over do while loop
             ien = i
         endif ! back if ( tau_end2 < time_v( index_v(1) ) ) block
     endif ! back if ( nsize > 0 ) block

! adjust ien further
     if ( tau_end1 < tau_end2 ) then
         ien = ien - 1
     endif ! back if ( tau_end1 < tau_end2 ) block

!-------------------------------------------------------------------------
! stage 2: determine rshf, whether we can shift it ?
!-------------------------------------------------------------------------
! for the spin-orbital coupling case, we can not lookup the operators
! series quickly
     if ( cssoc == 1 ) then
         rshf = .true.; RETURN
     endif ! back if ( cssoc == 1 ) block

! evaluate pieo and pien
     pieo = ieo
     pien = ien
     if ( tau_end1 < tau_end2 ) then
         pien = pien + 1
     else
         pieo = pieo + 1
     endif ! back if ( tau_end1 < tau_end2 ) block

! loop over all the subspace
     do m=0,nband
         do n=0,nband

! construct current subspace
             nupdn(1) = m
             nupdn(2) = n

! init key variables
             idead = 0
             counter = 0

! loop over all the operators, simulate their actions on subspace
             do i=1,nsize+1
                 counter = counter + 1

! meet the old destroy operator
                 if      ( i == pieo ) then
                     idead = idead + 1
! meet the new destroy operator
                 else if ( i == pien ) then
                     counter = counter - 1
                     iupdn = (flvr - 1) / nband + 1
                     nupdn(iupdn) = nupdn(iupdn) - 1
                     if ( nupdn(iupdn) < 0 .or. nupdn(iupdn) > nband ) EXIT
                     idead = idead + 1
! meet other existing operators
                 else
                     iupdn = ( flvr_v( index_v(counter) ) - 1 ) / nband + 1
                     nupdn(iupdn) = nupdn(iupdn) + 2 * type_v( index_v(counter) ) - 1
                     if ( nupdn(iupdn) < 0 .or. nupdn(iupdn) > nband ) EXIT
                     idead = idead + 1
                 endif ! back if ( i == pieo ) block
             enddo ! over i={1,nsize+1} loop

! once current subspace can survive, in order to save computational time,
! we return immediately, no need to deal with the rest subspaces
             if ( idead == nsize + 1 ) then
                 rshf = .true.; RETURN
             endif ! back if ( idead == nsize + 1 ) block

         enddo ! over n={0,nband} loop
     enddo ! over m={0,nband} loop

     return
  end subroutine try_rshift_flavor

!!========================================================================
!!>>> service layer: update perturbation expansion series D            <<<
!!========================================================================

!!>>> cat_insert_flavor: insert new create and destroy operators in the
!!>>> flavor part
  subroutine cat_insert_flavor(flvr, is, ie, tau_start, tau_end)
     use constants, only : dp, zero
     use stack, only : istack_getrest, istack_pop

     use control, only : ncfgs
     use control, only : beta
     use context, only : csign
     use context, only : empty_v, index_v, type_v, flvr_v, time_v, expt_t, expt_v
     use context, only : eigs

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address to insert new create and destroy operators
! is and ie are for create and destroy operators, respectively
     integer, intent(in)  :: is
     integer, intent(in)  :: ie

! imaginary time point of the new create operator
     real(dp), intent(in) :: tau_start

! imaginary time point of the new destroy operator
     real(dp), intent(in) :: tau_end

! local variables
! loop index over operators
     integer  :: i

! memory address for new create and destroy operators
     integer  :: as
     integer  :: ae

! total number of operators
     integer  :: nsize

! imaginary time interval for two successive operators
! t_prev stands for t_{i} - t_{i-1), and t_next stands for t_{i+1} - t_{i}
     real(dp) :: t_prev
     real(dp) :: t_next

!-------------------------------------------------------------------------
! stage 1: insert a create operator
!-------------------------------------------------------------------------
! determine nsize
     nsize = istack_getrest( empty_v )

! get memory address for create operator
     call istack_pop( empty_v, as )

! store basic data for new create operator
     time_v(as) = tau_start
     flvr_v(as) = flvr
     type_v(as) = 1

! shift index_v to make an empty room
     do i=nsize,is,-1
         index_v(i+1) = index_v(i)
     enddo ! over i={nsize,is,-1} loop

! store the memory address for create operator
     index_v(is) = as

! evaluate previous imaginary time interval
     if ( is ==         1 ) then ! the imaginary time of create operator is the smallest
         t_prev = time_v( index_v(is) ) - zero
     else
         t_prev = time_v( index_v(is) ) - time_v( index_v(is-1) )
     endif ! back if ( is == 1 ) block

! evaluate next imaginary time interval
     if ( is == nsize + 1 ) then ! the imaginary time of create operator is the largest
         t_next = beta - time_v( index_v(is) )
     else
         t_next = time_v( index_v(is+1) ) - time_v( index_v(is) )
     endif ! back if ( is == nsize + 1 ) block

! update the expt_v and expt_t, matrix of time evolution operator
! if is == nsize + 1, index_v(is+1) is not indexed (i.e, equal to 0),
! so we store the rightmost time evolution operator at expt_t
     if ( is == nsize + 1 ) then
         do i=1,ncfgs
             expt_v( i, as ) = exp ( -eigs(i) * t_prev )
         enddo ! over i={1,ncfgs} loop
         do i=1,ncfgs
             expt_t( i, 2  ) = exp ( -eigs(i) * t_next )
         enddo ! over i={1,ncfgs} loop
     else
         do i=1,ncfgs
             expt_v( i, as ) = exp ( -eigs(i) * t_prev )
         enddo ! over i={1,ncfgs} loop
         as = index_v(is+1)
         do i=1,ncfgs
             expt_v( i, as ) = exp ( -eigs(i) * t_next )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( is == nsize + 1 ) block

!-------------------------------------------------------------------------
! stage 2: insert a destroy operator
!-------------------------------------------------------------------------
! determine nsize
     nsize = istack_getrest( empty_v )

! get memory address for destroy operator
     call istack_pop( empty_v, ae )

! store basic data for new destroy operator
     time_v(ae) = tau_end
     flvr_v(ae) = flvr
     type_v(ae) = 0

! shift index_v to make an empty room
     do i=nsize,ie,-1
         index_v(i+1) = index_v(i)
     enddo ! over i={nsize,ie,-1} loop

! store the memory address for destroy operator
     index_v(ie) = ae

! evaluate previous imaginary time interval
     if ( ie ==         1 ) then ! the imaginary time of destroy operator is the smallest
         t_prev = time_v( index_v(ie) ) - zero
     else
         t_prev = time_v( index_v(ie) ) - time_v( index_v(ie-1) )
     endif ! back if ( ie == 1 ) block

! evaluate next imaginary time interval
     if ( ie == nsize + 1 ) then ! the imaginary time of destroy operator is the largest
         t_next = beta - time_v( index_v(ie) )
     else
         t_next = time_v( index_v(ie+1) ) - time_v( index_v(ie) )
     endif ! back if ( ie == nsize + 1 ) block

! update the expt_v and expt_t, matrix of time evolution operator
! if ie == nsize + 1, index_v(ie+1) is not indexed (i.e, equal to 0),
! so we store the rightmost time evolution operator at expt_t
     if ( ie == nsize + 1 ) then
         do i=1,ncfgs
             expt_v( i, ae ) = exp ( -eigs(i) * t_prev )
         enddo ! over i={1,ncfgs} loop
         do i=1,ncfgs
             expt_t( i, 2  ) = exp ( -eigs(i) * t_next )
         enddo ! over i={1,ncfgs} loop
     else
         do i=1,ncfgs
             expt_v( i, ae ) = exp ( -eigs(i) * t_prev )
         enddo ! over i={1,ncfgs} loop
         ae = index_v(ie+1)
         do i=1,ncfgs
             expt_v( i, ae ) = exp ( -eigs(i) * t_next )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( ie == nsize + 1 ) block

!-------------------------------------------------------------------------
! stage 3: deal with sign problem
!-------------------------------------------------------------------------
! evaluate csign, TO BE CHECKED
     csign = csign * ( 1 - 2 * mod( nsize - ie + nsize - is + 1, 2 ) )

     return
  end subroutine cat_insert_flavor

!!>>> cat_remove_flavor: remove old create and destroy operators in the
!!>>> flavor part
  subroutine cat_remove_flavor(is, ie, tau_start, tau_end)
     use constants, only : dp, zero
     use stack, only : istack_getrest, istack_push

     use control, only : ncfgs
     use control, only : beta
     use context, only : csign
     use context, only : empty_v, index_v, time_v, expt_t, expt_v
     use context, only : eigs

     implicit none

! external arguments
! index address to remove old create and destroy operators
! is and ie are for create and destroy operators, respectively
     integer, intent(in)  :: is
     integer, intent(in)  :: ie

! imaginary time point of the old create operator
     real(dp), intent(in) :: tau_start

! imaginary time point of the old destroy operator
     real(dp), intent(in) :: tau_end

! local variables
! loop index over operators
     integer  :: i

! memory address for old create and destroy operators
     integer  :: as
     integer  :: ae

! total number of operators
     integer  :: nsize

! imaginary time interval for two successive operators
! t_prev stands for t_{i} - t_{i-1), and t_next stands for t_{i+1} - t_{i}
     real(dp) :: t_prev
     real(dp) :: t_next

!-------------------------------------------------------------------------
! stage 1: remove create operator
!-------------------------------------------------------------------------
! determine nsize
     nsize = istack_getrest( empty_v )

! get memory address for old create operator
     as = index_v(is)

! push the memory address back to the empty_v stack
     call istack_push( empty_v, as )

! remove the unused index address from index_v
     do i=is,nsize-1
         index_v(i) = index_v(i+1)
     enddo ! over i={is,nsize-1} loop
     index_v(nsize) = 0

! evaluate previous imaginary time interval
     if ( is == 1     ) then ! the imaginary time of create operator is the smallest
         t_prev = zero
     else
         t_prev = time_v( index_v(is-1) )
     endif ! back if ( is == 1 ) block

! evaluate next imaginary time interval
     if ( is == nsize ) then ! the imaginary time of create operator is the largest
         t_next = beta
     else
         t_next = time_v( index_v(is)   )
     endif ! back if ( is == nsize ) block

! update the expt_v and expt_t, matrix of time evolution operator
! if is == nsize, index_v(is) is not indexed (i.e, equal to 0),
! so we store the rightmost time evolution operator at expt_t
     if ( is == nsize ) then
         do i=1,ncfgs
             expt_t( i, 2  ) = exp ( -eigs(i) * (t_next - t_prev) )
         enddo ! over i={1,ncfgs} loop
     else
         as = index_v(is)
         do i=1,ncfgs
             expt_v( i, as ) = exp ( -eigs(i) * (t_next - t_prev) )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( is == nsize ) block

!-------------------------------------------------------------------------
! stage 2: remove destroy operator
!-------------------------------------------------------------------------
! determine nsize
     nsize = istack_getrest( empty_v )

! get memory address for old destroy operator
     ae = index_v(ie)

! push the memory address back to the empty_v stack
     call istack_push( empty_v, ae )

! remove the unused index address from index_v
     do i=ie,nsize-1
         index_v(i) = index_v(i+1)
     enddo ! over i={ie,nsize-1} loop
     index_v(nsize) = 0

! evaluate previous imaginary time interval
     if ( ie == 1     ) then ! the imaginary time of destroy operator is the smallest
         t_prev = zero
     else
         t_prev = time_v( index_v(ie-1) )
     endif ! back if ( ie == 1 ) block

! evaluate next imaginary time interval
     if ( ie == nsize ) then ! the imaginary time of destroy operator is the largest
         t_next = beta
     else
         t_next = time_v( index_v(ie)   )
     endif ! back if ( ie == nsize ) block

! update the expt_v and expt_t, matrix of time evolution operator
! if ie == nsize, index_v(ie) is not indexed (i.e, equal to 0),
! so we store the rightmost time evolution operator at expt_t
     if ( ie == nsize ) then
         do i=1,ncfgs
             expt_t( i, 2  ) = exp ( -eigs(i) * (t_next - t_prev) )
         enddo ! over i={1,ncfgs} loop
     else
         ae = index_v(ie)
         do i=1,ncfgs
             expt_v( i, ae ) = exp ( -eigs(i) * (t_next - t_prev) )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( ie == nsize ) block

!-------------------------------------------------------------------------
! stage 3: deal with sign problem
!-------------------------------------------------------------------------
! copy is and ie to as and ae respectively
     as = is
     ae = ie

! in principle, destroy operator should be removed at first, but in fact,
! we remove create operator at first. in order to treat csign correctly,
! we need to recover the original scheme, so ae is restored at first.
! please refer to try_remove_flavor().
     if ( tau_start < tau_end ) then
         ae = ae + 1
     endif ! back if ( tau_start < tau_end ) block

! it is assumed that destroy operator is removed at first, so as should be
! adjusted if needed
     if ( tau_start > tau_end ) then
         as = as - 1
     endif ! back if ( tau_start > tau_end ) block

! evaluate csign, TO BE CHECKED
     csign = csign * ( 1 - 2 * mod( nsize - ae + nsize - as + 1, 2 ) )

     return
  end subroutine cat_remove_flavor

!!>>> cat_lshift_flavor: shift the old create operator in the flavor part
  subroutine cat_lshift_flavor(flvr, iso, isn, tau_start2)
     use constants, only : dp, zero
     use stack, only : istack_getrest

     use control, only : ncfgs
     use control, only : beta
     use context, only : csign
     use context, only : empty_v, index_v, type_v, flvr_v, time_v, expt_t, expt_v
     use context, only : eigs

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address to shift existing create operator
! iso and isn are for old and new create operators, respectively
     integer, intent(in)  :: iso
     integer, intent(in)  :: isn

! imaginary time point of the new create operator
     real(dp), intent(in) :: tau_start2

! local variables
! loop index over operators
     integer  :: i

! memory address for old and new create operators
     integer  :: as

! index address for old create operator
     integer  :: iso_t

! total number of operators
     integer  :: nsize

! imaginary time interval for two successive operators
! t_prev stands for t_{i} - t_{i-1), and t_next stands for t_{i+1} - t_{i}
     real(dp) :: t_prev
     real(dp) :: t_next

! determine nsize at first, get total number of operators
     nsize = istack_getrest( empty_v )

!-------------------------------------------------------------------------
! stage 1: shift old create operator
!-------------------------------------------------------------------------
! get memory address for create operator
     as = index_v(iso)

! store basic data for new create operator
     time_v(as) = tau_start2
     flvr_v(as) = flvr
     type_v(as) = 1

! remove the unused index address from index_v
     do i=iso,nsize-1
         index_v(i) = index_v(i+1)
     enddo ! over i={iso,nsize-1} loop
     index_v(nsize) = 0

! shift index_v to make an empty room
     do i=nsize-1,isn,-1
         index_v(i+1) = index_v(i)
     enddo ! over i={nsize-1,isn,-1} loop

! store the memory address for create operator
     index_v(isn) = as

! evaluate previous imaginary time interval
     if ( isn == 1 ) then ! the imaginary time of create operator is the smallest
         t_prev = time_v( index_v(isn) ) - zero
     else
         t_prev = time_v( index_v(isn) ) - time_v( index_v(isn-1) )
     endif ! back if ( isn == 1 ) block

! update the expt_v, matrix of time evolution operator
     do i=1,ncfgs
         expt_v( i, as ) = exp ( -eigs(i) * t_prev )
     enddo ! over i={1,ncfgs} loop

!-------------------------------------------------------------------------
! stage 2: auxiliary tasks
!-------------------------------------------------------------------------
! its neighbor needs to be changes as well. change time evolution operator
     if ( isn < nsize ) then
         t_next = time_v( index_v(isn+1) ) - time_v( index_v(isn) )
         as = index_v(isn+1)
         do i=1,ncfgs
             expt_v( i, as ) = exp ( -eigs(i) * t_next )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( isn < nsize ) block

! the operator closest to the old place needs to be changed as well
     if ( iso < nsize .and. iso /= isn ) then
         if ( iso > isn ) then
             iso_t = iso + 1
         else
             iso_t = iso
         endif ! back if ( iso > isn ) block
         if ( iso_t == 1 ) then
             t_prev = time_v( index_v(iso_t) ) - zero
         else
             t_prev = time_v( index_v(iso_t) ) - time_v( index_v(iso_t-1) )
         endif ! back if ( iso_t == 1 ) block
         as = index_v(iso_t)
         do i=1,ncfgs
             expt_v( i, as ) = exp ( -eigs(i) * t_prev )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( iso < nsize .and. iso /= isn ) block

! update the final time evolution operator
     t_next = time_v( index_v(nsize) )
     do i=1,ncfgs
         expt_t( i, 2 ) = exp ( -eigs(i) * (beta - t_next) )
     enddo ! over i={1,ncfgs} loop

!-------------------------------------------------------------------------
! stage 3: deal with sign problem
!-------------------------------------------------------------------------
! evaluate csign, TO BE CHECKED
     csign = csign * ( 1 - 2 * mod( iso + isn, 2 ) )

     return
  end subroutine cat_lshift_flavor

!!>>> cat_rshift_flavor: shift the old destroy operator in the flavor part
  subroutine cat_rshift_flavor(flvr, ieo, ien, tau_end2)
     use constants, only : dp, zero
     use stack, only : istack_getrest

     use control, only : ncfgs
     use control, only : beta
     use context, only : csign
     use context, only : empty_v, index_v, type_v, flvr_v, time_v, expt_t, expt_v
     use context, only : eigs

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address to shift existing destroy operator
! iso and isn are for old and new destroy operators, respectively
     integer, intent(in)  :: ieo
     integer, intent(in)  :: ien

! imaginary time point of the new destroy operator
     real(dp), intent(in) :: tau_end2

! local variables
! loop index over operators
     integer  :: i

! memory address for old and new destroy operators
     integer  :: ae

! index address for old destroy operator
     integer  :: ieo_t

! total number of operators
     integer  :: nsize

! imaginary time interval for two successive operators
! t_prev stands for t_{i} - t_{i-1), and t_next stands for t_{i+1} - t_{i}
     real(dp) :: t_prev
     real(dp) :: t_next

! determine nsize at first, get total number of operators
     nsize = istack_getrest( empty_v )

!-------------------------------------------------------------------------
! stage 1: shift old destroy operator
!-------------------------------------------------------------------------
! get memory address for destroy operator
     ae = index_v(ieo)

! store basic data for new destroy operator
     time_v(ae) = tau_end2
     flvr_v(ae) = flvr
     type_v(ae) = 0

! remove the unused index address from index_v
     do i=ieo,nsize-1
         index_v(i) = index_v(i+1)
     enddo ! over i={ieo,nsize-1} loop
     index_v(nsize) = 0

! shift index_v to make an empty room
     do i=nsize-1,ien,-1
         index_v(i+1) = index_v(i)
     enddo ! over i={nsize-1,ien,-1} loop

! store the memory address for destroy operator
     index_v(ien) = ae

! evaluate previous imaginary time interval
     if ( ien == 1 ) then ! the imaginary time of destroy operator is the smallest
         t_prev = time_v( index_v(ien) ) - zero
     else
         t_prev = time_v( index_v(ien) ) - time_v( index_v(ien-1) )
     endif ! back if ( ien == 1 ) block

! update the expt_v, matrix of time evolution operator
     do i=1,ncfgs
         expt_v( i, ae ) = exp ( -eigs(i) * t_prev )
     enddo ! over i={1,ncfgs} loop

!-------------------------------------------------------------------------
! stage 2: auxiliary tasks
!-------------------------------------------------------------------------
! its neighbor needs to be changes as well. change time evolution operator
     if ( ien < nsize ) then
         t_next = time_v( index_v(ien+1) ) - time_v( index_v(ien) )
         ae = index_v(ien+1)
         do i=1,ncfgs
             expt_v( i, ae ) = exp ( -eigs(i) * t_next )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( ien < nsize ) block

! the operator closest to the old place needs to be changed as well
     if ( ieo < nsize .and. ieo /= ien ) then
         if ( ieo > ien ) then
             ieo_t = ieo + 1
         else
             ieo_t = ieo
         endif ! back if ( ieo > ien ) block
         if ( ieo_t == 1 ) then
             t_prev = time_v( index_v(ieo_t) ) - zero
         else
             t_prev = time_v( index_v(ieo_t) ) - time_v( index_v(ieo_t-1) )
         endif ! back if ( ieo_t == 1 ) block
         ae = index_v(ieo_t)
         do i=1,ncfgs
             expt_v( i, ae ) = exp ( -eigs(i) * t_prev )
         enddo ! over i={1,ncfgs} loop
     endif ! back if ( ieo < nsize .and. ieo /= ien ) block

! update the final time evolution operator
     t_next = time_v( index_v(nsize) )
     do i=1,ncfgs
         expt_t( i, 2 ) = exp ( -eigs(i) * (beta - t_next) )
     enddo ! over i={1,ncfgs} loop

!-------------------------------------------------------------------------
! stage 3: deal with sign problem
!-------------------------------------------------------------------------
! evaluate csign, TO BE CHECKED
     csign = csign * ( 1 - 2 * mod( ieo + ien, 2 ) )

     return
  end subroutine cat_rshift_flavor

!!========================================================================
!!>>> service layer: utility subroutines to calculate trace            <<<
!!========================================================================

!!>>> ctqmc_make_ztrace: core subroutine of begonia
!!>>> used to evaluate the operator traces by direct matrix multiplication.
!!>>> how to deal with the operator traces is the most important problem
!!>>> of the general matrix version hybridization expansion continuous
!!>>> time quantum Monte Carlo impurity solver. since this subroutine
!!>>> should be called for about one thousand millions times in one DMFT
!!>>> loop, so its execution efficiency is our focus.
!!
!!>>> in general, in each quantum Monte Carlo step, we need to multiply
!!>>> all f-matrices and related time evolution operators together, and
!!>>> then evaluate the matrix trace. this method is very very inefficient
!!>>> for multi-orbitals systems, in which the dimension of the f-matrix
!!>>> increasing exponently, and for low temperature (large \beta) and
!!>>> weak interaction (small U) systems, in which the perturbation orders
!!>>> is so large, i.e., the number of matrices that we need to store and
!!>>> multiply is very large.
!!
!!>>> in order to overcome this problem, we adopt a smart algorithm. we
!!>>> divide the imaginary time axis [0, \beta] into npart parts, and then
!!>>> evaluate the operator traces in each part in advance. in each Monte
!!>>> Carlo step, only those modified parts are picked up, and then their
!!>>> operators multiplication are performed again. the obtained results
!!>>> are multiplied with the rest parts, and then the product can be used
!!>>> to extract the final operator traces. in the worst situation, only
!!>>> four parts should be recalculated again. in the best situation, only
!!>>> one part should be recalculated.
!!
!!>>> according to our extensive benchmarks, this algorithm can improve
!!>>> the computational efficiency significantly.
  subroutine ctqmc_make_ztrace(cmode, csize, trace, tau_s, tau_e)
     use constants, only : dp
     use sparse, only : sp_uni_to_csr
     use sparse, only : sp_csr_cp_elm, sp_csr_cp_csr
     use sparse, only : sp_csr_mm_csr, sp_dia_mm_csr

     use control, only : ncfgs, nzero
     use control, only : npart
     use control, only : beta
     use context, only : index_t, index_v, type_v, flvr_v, time_v, expt_t, expt_v
     use context, only : diag
     use context, only : isave
     use context, only : spm_a, spm_b, spm_c, spm_d, spm_s

     implicit none

! external arguments
! control flag, possible calculation mode
! if cmode = 1, partly-trial calculation, useful for ctqmc_insert_ztrace() etc
! if cmode = 2, partly-normal calculation, not used by now
! if cmode = 3, fully-trial calculation, useful for ctqmc_reflip_kink()
! if cmode = 4, fully-normal calculation, useful for ctqmc_retrieve_status()
     integer, intent(in)   :: cmode

! total number of operators
     integer, intent(in)   :: csize

! final trace for matrix multiplication
     real(dp), intent(out) :: trace

! imaginary time value of operator A, only valid in cmode = 1 or 2
     real(dp), intent(in)  :: tau_s

! imaginary time value of operator B, only valid in cmode = 1 or 2
     real(dp), intent(in)  :: tau_e

! local variables
! loop index
     integer  :: i
     integer  :: j

! position of the operator A and operator B, index of part
     integer  :: tis
     integer  :: tie
     integer  :: tip

! type for current operator
     integer  :: vt

! flavor channel for current operator
     integer  :: vf

! length in imaginary time axis for each part
     real(dp) :: interval

! number of operators for each part
     integer  :: nop(npart)

! start index of operators for each part
     integer  :: ops(npart)

! end index of operators for each part
     integer  :: ope(npart)

! dummy sparse matrix structure, in CSR style
! note: in order to improve the computational efficiency, we do not use
! the T_spmat structure here
     integer  :: imm1(ncfgs+1)
     integer  :: jmm1(nzero)
     real(dp) :: smm1(nzero)

! dummy sparse matrix structure, in CSR style
! note: in order to improve the computational efficiency, we do not use
! the T_spmat structure here
     integer  :: imm2(ncfgs+1)
     integer  :: jmm2(nzero)
     real(dp) :: smm2(nzero)

! evaluate interval at first
     interval = beta / real(npart)

! init key arrays
     nop = 0
     ops = 0
     ope = 0

! init global array
     isave = 0

! build identity sparse matrix as a start matrix
     call sp_uni_to_csr( ncfgs, nzero, smm1, jmm1, imm1 )

!-------------------------------------------------------------------------
! case A: partly-trial mode
!-------------------------------------------------------------------------
     if      ( cmode == 1 ) then

! get the position of operator A and operator B
         tis = ceiling( tau_s / interval )
         tie = ceiling( tau_e / interval )

! calculate number of operators for each part
         do i=1,csize
             j = ceiling( time_v( index_t(i) ) / interval )
             nop(j) = nop(j) + 1
         enddo ! over i={1,csize} loop

! calculate the start and end index of operators for each part
         do i=1,npart
             if ( nop(i) > 0 ) then
                 ops(i) = 1
                 do j=1,i-1
                     ops(i) = ops(i) + nop(j)
                 enddo ! over j={1,i-1} loop
                 ope(i) = ops(i) + nop(i) - 1
             endif ! back if ( nop(i) > 0 ) block
         enddo ! over i={1,npart} loop

! determine the influence of operator A, which part should be recalculated
         isave(tis) = 1
! special attention: if operator A is on the left or right boundary, then
! the neighbour part should be recalculated as well
         if ( nop(tis) > 0 ) then
             if ( tau_s >= time_v( index_t( ope(tis) ) ) ) then
                 tip = tis + 1
                 do while ( tip <= npart )
                     if ( nop(tip) > 0 ) then
                         isave(tip) = 1; EXIT
                     endif ! back if ( nop(tip) > 0 ) block
                     tip = tip + 1
                 enddo ! over do while loop
             endif ! back if ( tau_s >= time_v( index_t( ope(tis) ) ) ) block
         else
             tip = tis + 1
             do while ( tip <= npart )
                 if ( nop(tip) > 0 ) then
                     isave(tip) = 1; EXIT
                 endif ! back if ( nop(tip) > 0 ) block
                 tip = tip + 1
             enddo ! over do while loop
         endif ! back if ( nop(tis) > 0 ) block

! determine the influence of operator B, which part should be recalculated
         isave(tie) = 1
! special attention: if operator B is on the left or right boundary, then
! the neighbour part should be recalculated as well
         if ( nop(tie) > 0 ) then
             if ( tau_e >= time_v( index_t( ope(tie) ) ) ) then
                 tip = tie + 1
                 do while ( tip <= npart )
                     if ( nop(tip) > 0 ) then
                         isave(tip) = 1; EXIT
                     endif ! back if ( nop(tip) > 0 ) block
                     tip = tip + 1
                 enddo ! over do while loop
             endif ! back if ( tau_e >= time_v( index_t( ope(tie) ) ) ) block
         else
             tip = tie + 1
             do while ( tip <= npart )
                 if ( nop(tip) > 0 ) then
                     isave(tip) = 1; EXIT
                 endif ! back if ( nop(tip) > 0 ) block
                 tip = tip + 1
             enddo ! over do while loop
         endif ! back if ( nop(tie) > 0 ) block

! main loop over all the parts
         do i=1,npart

! if current part need to be recalculated
             if ( isave(i) == 1 ) then

! build the identity sparse matrix spm_b as a start matrix
                 call sp_uni_to_csr( ncfgs, nzero, &
                                      spm_b(i)%vv, &
                                      spm_b(i)%jv, &
                                      spm_b(i)%iv )

! loop over all the matrix in this part
                 if ( nop(i) > 0 ) then
                     operator_loop1: &
                     do j=ops(i),ope(i)
! get the type and flavor for current operator
                         vt = type_v ( index_t(j) )
                         vf = flvr_v ( index_t(j) )

! multiply spm_b matrix with time evolution operator at first, and then
! multiply the result smm2 matrix with F matrix (spm_c or spm_d)
                         call sp_dia_mm_csr(     ncfgs, nzero, &
                                      expt_v( :, index_t(j) ), &
                                                  spm_b(i)%vv, &
                                                  spm_b(i)%jv, &
                                                  spm_b(i)%iv, &
                                             smm2, jmm2, imm2 )
                         if ( vt == 1 ) then ! create  operator
                             call sp_csr_mm_csr( ncfgs, ncfgs, &
                                                 ncfgs, nzero, &
                                                 spm_c(vf)%vv, &
                                                 spm_c(vf)%jv, &
                                                 spm_c(vf)%iv, &
                                             smm2, jmm2, imm2, &
                                                  spm_b(i)%vv, &
                                                  spm_b(i)%jv, &
                                                  spm_b(i)%iv )
                         else                ! destroy operator
                             call sp_csr_mm_csr( ncfgs, ncfgs, &
                                                 ncfgs, nzero, &
                                                 spm_d(vf)%vv, &
                                                 spm_d(vf)%jv, &
                                                 spm_d(vf)%iv, &
                                             smm2, jmm2, imm2, &
                                                  spm_b(i)%vv, &
                                                  spm_b(i)%jv, &
                                                  spm_b(i)%iv )
                         endif ! back if ( vt == 1 ) block
                     enddo operator_loop1 ! over j={ops(i),ope(i)} loop
                 endif ! back if ( nop(i) > 0 ) block

! multiply current part (spm_b) with the rest parts (smm1), and get smm2
                 call sp_csr_mm_csr( ncfgs, ncfgs, &
                                     ncfgs, nzero, &
                                      spm_b(i)%vv, &
                                      spm_b(i)%jv, &
                                      spm_b(i)%iv, &
                                 smm1, jmm1, imm1, &
                                 smm2, jmm2, imm2 )

! if current part no need to be recalculated
             else

! multiply current part (spm_a) with the rest parts (smm1), and get smm2
                 call sp_csr_mm_csr( ncfgs, ncfgs, &
                                     ncfgs, nzero, &
                                      spm_a(i)%vv, &
                                      spm_a(i)%jv, &
                                      spm_a(i)%iv, &
                                 smm1, jmm1, imm1, &
                                 smm2, jmm2, imm2 )

             endif ! back if ( isave(i) == 1 ) block

! copy smm2 to smm1
             call sp_csr_cp_csr( ncfgs, nzero, &
                             smm2, jmm2, imm2, &
                             smm1, jmm1, imm1 )

         enddo ! over i={1,npart} loop

! multiply the last time evolution operator with smm1, now smm2 is the
! final product matrix
         call sp_dia_mm_csr(     ncfgs, nzero, &
                                  expt_t(:,1), &
                             smm1, jmm1, imm1, &
                             smm2, jmm2, imm2 )

!-------------------------------------------------------------------------
! case B: partly-normal mode
!-------------------------------------------------------------------------
     else if ( cmode == 2 ) then

! get the position of operator A and operator B
         tis = ceiling( tau_s / interval )
         tie = ceiling( tau_e / interval )

! calculate number of operators for each part
         do i=1,csize
             j = ceiling( time_v( index_v(i) ) / interval )
             nop(j) = nop(j) + 1
         enddo ! over i={1,csize} loop

! calculate the start and end index of operators for each part
         do i=1,npart
             if ( nop(i) > 0 ) then
                 ops(i) = 1
                 do j=1,i-1
                     ops(i) = ops(i) + nop(j)
                 enddo ! over j={1,i-1} loop
                 ope(i) = ops(i) + nop(i) - 1
             endif ! back if ( nop(i) > 0 ) block
         enddo ! over i={1,npart} loop

! determine the influence of operator A, which part should be recalculated
         isave(tis) = 1
! special attention: if operator A is on the left or right boundary, then
! the neighbour part should be recalculated as well
         if ( nop(tis) > 0 ) then
             if ( tau_s >= time_v( index_v( ope(tis) ) ) ) then
                 tip = tis + 1
                 do while ( tip <= npart )
                     if ( nop(tip) > 0 ) then
                         isave(tip) = 1; EXIT
                     endif ! back if ( nop(tip) > 0 ) block
                     tip = tip + 1
                 enddo ! over do while loop
             endif ! back if ( tau_s >= time_v( index_v( ope(tis) ) ) ) block
         else
             tip = tis + 1
             do while ( tip <= npart )
                 if ( nop(tip) > 0 ) then
                     isave(tip) = 1; EXIT
                 endif ! back if ( nop(tip) > 0 ) block
                 tip = tip + 1
             enddo ! over do while loop
         endif ! back if ( nop(tis) > 0 ) block

! determine the influence of operator B, which part should be recalculated
         isave(tie) = 1
! special attention: if operator B is on the left or right boundary, then
! the neighbour part should be recalculated as well
         if ( nop(tie) > 0 ) then
             if ( tau_e >= time_v( index_v( ope(tie) ) ) ) then
                 tip = tie + 1
                 do while ( tip <= npart )
                     if ( nop(tip) > 0 ) then
                         isave(tip) = 1; EXIT
                     endif ! back if ( nop(tip) > 0 ) block
                     tip = tip + 1
                 enddo ! over do while loop
             endif ! back if ( tau_e >= time_v( index_v( ope(tie) ) ) ) block
         else
             tip = tie + 1
             do while ( tip <= npart )
                 if ( nop(tip) > 0 ) then
                     isave(tip) = 1; EXIT
                 endif ! back if ( nop(tip) > 0 ) block
                 tip = tip + 1
             enddo ! over do while loop
         endif ! back if ( nop(tie) > 0 ) block

! main loop over all the parts
         do i=1,npart

! if current part need to be recalculated
             if ( isave(i) == 1 ) then

! build the identity sparse matrix spm_a as a start matrix
                 call sp_uni_to_csr( ncfgs, nzero, &
                                      spm_a(i)%vv, &
                                      spm_a(i)%jv, &
                                      spm_a(i)%iv )

! loop over all the matrix in this part
                 if ( nop(i) > 0 ) then
                     operator_loop2: &
                     do j=ops(i),ope(i)
! get the type and flavor for current operator
                         vt = type_v ( index_v(j) )
                         vf = flvr_v ( index_v(j) )

! multiply spm_a matrix with time evolution operator at first, and then
! multiply the result smm2 matrix with F matrix (spm_c or spm_d)
                         call sp_dia_mm_csr(     ncfgs, nzero, &
                                      expt_v( :, index_v(j) ), &
                                                  spm_a(i)%vv, &
                                                  spm_a(i)%jv, &
                                                  spm_a(i)%iv, &
                                             smm2, jmm2, imm2 )
                         if ( vt == 1 ) then ! create  operator
                             call sp_csr_mm_csr( ncfgs, ncfgs, &
                                                 ncfgs, nzero, &
                                                 spm_c(vf)%vv, &
                                                 spm_c(vf)%jv, &
                                                 spm_c(vf)%iv, &
                                             smm2, jmm2, imm2, &
                                                  spm_a(i)%vv, &
                                                  spm_a(i)%jv, &
                                                  spm_a(i)%iv )
                         else                ! destroy operator
                             call sp_csr_mm_csr( ncfgs, ncfgs, &
                                                 ncfgs, nzero, &
                                                 spm_d(vf)%vv, &
                                                 spm_d(vf)%jv, &
                                                 spm_d(vf)%iv, &
                                             smm2, jmm2, imm2, &
                                                  spm_a(i)%vv, &
                                                  spm_a(i)%jv, &
                                                  spm_a(i)%iv )
                         endif ! back if ( vt == 1 ) block
                     enddo operator_loop2 ! over j={ops(i),ope(i)} loop
                 endif ! back if ( nop(i) > 0 ) block

             endif ! back if ( isave(i) == 1 ) block

! multiply current part (spm_a) with the rest parts (smm1), and get smm2
             call sp_csr_mm_csr( ncfgs, ncfgs, &
                                 ncfgs, nzero, &
                                  spm_a(i)%vv, &
                                  spm_a(i)%jv, &
                                  spm_a(i)%iv, &
                             smm1, jmm1, imm1, &
                             smm2, jmm2, imm2 )

! copy smm2 to smm1
             call sp_csr_cp_csr( ncfgs, nzero, &
                             smm2, jmm2, imm2, &
                             smm1, jmm1, imm1 )

         enddo ! over i={1,npart} loop

! multiply the last time evolution operator with smm1, now smm2 is the
! final product matrix
         call sp_dia_mm_csr(     ncfgs, nzero, &
                                  expt_t(:,2), &
                             smm1, jmm1, imm1, &
                             smm2, jmm2, imm2 )

! reset isave, since spm_a should not be overrode by spm_b in this case.
         isave = 0

!-------------------------------------------------------------------------
! case C: fully-trial mode
!-------------------------------------------------------------------------
     else if ( cmode == 3 ) then

! calculate number of operators for each part
         do i=1,csize
             j = ceiling( time_v( index_t(i) ) / interval )
             nop(j) = nop(j) + 1
         enddo ! over i={1,csize} loop

! calculate the start and end index of operators for each part
         do i=1,npart
             if ( nop(i) > 0 ) then
                 ops(i) = 1
                 do j=1,i-1
                     ops(i) = ops(i) + nop(j)
                 enddo ! over j={1,i-1} loop
                 ope(i) = ops(i) + nop(i) - 1
             endif ! back if ( nop(i) > 0 ) block
         enddo ! over i={1,npart} loop

! now all the parts should be recalculated
         isave = 1 ! be used in ctqmc_make_evolve()

! main loop over all the parts
         do i=1,npart

! build the identity sparse matrix spm_b as a start matrix
             call sp_uni_to_csr( ncfgs, nzero, &
                                  spm_b(i)%vv, &
                                  spm_b(i)%jv, &
                                  spm_b(i)%iv )

! loop over all the matrix in this part
             if ( nop(i) > 0 ) then
                 operator_loop3: &
                 do j=ops(i),ope(i)
! get the type and flavor for current operator
                     vt = type_v ( index_t(j) )
                     vf = flvr_v ( index_t(j) )

! multiply spm_b matrix with time evolution operator at first, and then
! multiply the result smm2 matrix with F matrix (spm_c or spm_d)
                     call sp_dia_mm_csr(     ncfgs, nzero, &
                                  expt_v( :, index_t(j) ), &
                                              spm_b(i)%vv, &
                                              spm_b(i)%jv, &
                                              spm_b(i)%iv, &
                                         smm2, jmm2, imm2 )
                     if ( vt == 1 ) then ! create  operator
                         call sp_csr_mm_csr( ncfgs, ncfgs, &
                                             ncfgs, nzero, &
                                             spm_c(vf)%vv, &
                                             spm_c(vf)%jv, &
                                             spm_c(vf)%iv, &
                                         smm2, jmm2, imm2, &
                                              spm_b(i)%vv, &
                                              spm_b(i)%jv, &
                                              spm_b(i)%iv )
                     else                ! destroy operator
                         call sp_csr_mm_csr( ncfgs, ncfgs, &
                                             ncfgs, nzero, &
                                             spm_d(vf)%vv, &
                                             spm_d(vf)%jv, &
                                             spm_d(vf)%iv, &
                                         smm2, jmm2, imm2, &
                                              spm_b(i)%vv, &
                                              spm_b(i)%jv, &
                                              spm_b(i)%iv )
                     endif ! back if ( vt == 1 ) block
                 enddo operator_loop3 ! over j={ops(i),ope(i)} loop
             endif ! back if ( nop(i) > 0 ) block

! multiply current part (spm_b) with the rest parts (smm1), and get smm2
             call sp_csr_mm_csr( ncfgs, ncfgs, &
                                 ncfgs, nzero, &
                                  spm_b(i)%vv, &
                                  spm_b(i)%jv, &
                                  spm_b(i)%iv, &
                             smm1, jmm1, imm1, &
                             smm2, jmm2, imm2 )

! copy smm2 to smm1
             call sp_csr_cp_csr( ncfgs, nzero, &
                             smm2, jmm2, imm2, &
                             smm1, jmm1, imm1 )

         enddo ! over i={1,npart} loop

! multiply the last time evolution operator with smm1, now smm2 is the
! final product matrix
         call sp_dia_mm_csr(     ncfgs, nzero, &
                                  expt_t(:,2), &
                             smm1, jmm1, imm1, &
                             smm2, jmm2, imm2 )

!-------------------------------------------------------------------------
! case D: fully-normal mode
!-------------------------------------------------------------------------
     else if ( cmode == 4 ) then

! calculate number of operators for each part
         do i=1,csize
             j = ceiling( time_v( index_v(i) ) / interval )
             nop(j) = nop(j) + 1
         enddo ! over i={1,csize} loop

! calculate the start and end index of operators for each part
         do i=1,npart
             if ( nop(i) > 0 ) then
                 ops(i) = 1
                 do j=1,i-1
                     ops(i) = ops(i) + nop(j)
                 enddo ! over j={1,i-1} loop
                 ope(i) = ops(i) + nop(i) - 1
             endif ! back if ( nop(i) > 0 ) block
         enddo ! over i={1,npart} loop

! now all the parts should be recalculated
         isave = 0 ! be used in ctqmc_make_evolve()

! main loop over all the parts
         do i=1,npart

! build the identity sparse matrix spm_a as a start matrix
             call sp_uni_to_csr( ncfgs, nzero, &
                                  spm_a(i)%vv, &
                                  spm_a(i)%jv, &
                                  spm_a(i)%iv )

! loop over all the matrix in this part
             if ( nop(i) > 0 ) then
                 operator_loop4: &
                 do j=ops(i),ope(i)
! get the type and flavor for current operator
                     vt = type_v ( index_v(j) )
                     vf = flvr_v ( index_v(j) )

! multiply spm_a matrix with time evolution operator at first, and then
! multiply the result smm2 matrix with F matrix (spm_c or spm_d)
                     call sp_dia_mm_csr(     ncfgs, nzero, &
                                  expt_v( :, index_v(j) ), &
                                              spm_a(i)%vv, &
                                              spm_a(i)%jv, &
                                              spm_a(i)%iv, &
                                         smm2, jmm2, imm2 )
                     if ( vt == 1 ) then ! create  operator
                         call sp_csr_mm_csr( ncfgs, ncfgs, &
                                             ncfgs, nzero, &
                                             spm_c(vf)%vv, &
                                             spm_c(vf)%jv, &
                                             spm_c(vf)%iv, &
                                         smm2, jmm2, imm2, &
                                              spm_a(i)%vv, &
                                              spm_a(i)%jv, &
                                              spm_a(i)%iv )
                     else                ! destroy operator
                         call sp_csr_mm_csr( ncfgs, ncfgs, &
                                             ncfgs, nzero, &
                                             spm_d(vf)%vv, &
                                             spm_d(vf)%jv, &
                                             spm_d(vf)%iv, &
                                         smm2, jmm2, imm2, &
                                              spm_a(i)%vv, &
                                              spm_a(i)%jv, &
                                              spm_a(i)%iv )
                     endif ! back if ( vt == 1 ) block
                 enddo operator_loop4 ! over j={ops(i),ope(i)} loop
             endif ! back if ( nop(i) > 0 ) block

! multiply current part (spm_a) with the rest parts (smm1), and get smm2
             call sp_csr_mm_csr( ncfgs, ncfgs, &
                                 ncfgs, nzero, &
                                  spm_a(i)%vv, &
                                  spm_a(i)%jv, &
                                  spm_a(i)%iv, &
                             smm1, jmm1, imm1, &
                             smm2, jmm2, imm2 )

! copy smm2 to smm1
             call sp_csr_cp_csr( ncfgs, nzero, &
                             smm2, jmm2, imm2, &
                             smm1, jmm1, imm1 )

         enddo ! over i={1,npart} loop

! multiply the last time evolution operator with smm1, now smm2 is the
! final product matrix
         call sp_dia_mm_csr(     ncfgs, nzero, &
                                  expt_t(:,2), &
                             smm1, jmm1, imm1, &
                             smm2, jmm2, imm2 )

     endif ! back if ( cmode == 1 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! now smm2 is the final product, we can use it to evaluate the matrix trace
     do j=1,ncfgs
         diag(j,1) = sp_csr_cp_elm( j, j, &
                            ncfgs, nzero, &
                        smm2, jmm2, imm2 )
     enddo ! over j={1,ncfgs} loop
     trace = sum( diag(:,1) )

! save the final matrix product to spm_s
     call sp_csr_cp_csr(    ncfgs, nzero, &
                        smm2, jmm2, imm2, &
                             spm_s(1)%vv, &
                             spm_s(1)%jv, &
                             spm_s(1)%iv )

     return
  end subroutine ctqmc_make_ztrace

!!>>> ctqmc_make_evolve: used to update the operator traces of the
!!>>> modified part
  subroutine ctqmc_make_evolve()
     use sparse, only : sp_csr_cp_csr

     use control, only : ncfgs, nzero
     use control, only : npart
     use context, only : matrix_ptrace, matrix_ntrace
     use context, only : diag
     use context, only : isave
     use context, only : spm_a, spm_b, spm_s

     implicit none

! local variables
! loop index
     integer :: i

! transfer spm_b into spm_a if needed (cmode == 1 or cmode == 3)
     do i=1,npart
         if ( isave(i) == 1 ) then
             call sp_csr_cp_csr( ncfgs, nzero, &
                                  spm_b(i)%vv, &
                                  spm_b(i)%jv, &
                                  spm_b(i)%iv, &
                                  spm_a(i)%vv, &
                                  spm_a(i)%jv, &
                                  spm_a(i)%iv )
         endif ! back if ( isave(i) == 1 ) block
     enddo ! over i={1,npart} loop

! update the operator traces
     matrix_ptrace = matrix_ntrace

! update diag for the calculation of atomic state probability
     diag(:,2) = diag(:,1)

! transfer the final matrix product from spm_s(1) to spm_s(2), the
! latter can be used to calculate nmat and nnmat
     call sp_csr_cp_csr( ncfgs, nzero, &
                          spm_s(1)%vv, &
                          spm_s(1)%jv, &
                          spm_s(1)%iv, &
                          spm_s(2)%vv, &
                          spm_s(2)%jv, &
                          spm_s(2)%iv )

     return
  end subroutine ctqmc_make_evolve

!!========================================================================
!!>>> service layer: utility subroutines to look up in the flavor      <<<
!!========================================================================

!!>>> ctqmc_make_equate: to determine whether there exists an operator
!!>>> whose imaginary time is equal to time
  subroutine ctqmc_make_equate(flvr, time, have)
     use constants, only : dp, epss

     use context, only : ckink
     use context, only : index_s, index_e, time_s, time_e

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! the answer what we need
     integer, intent(out) :: have

! imaginary time value
     real(dp), intent(in) :: time

! local variables
! loop index
     integer :: i

! init have
     have = 0

! loop over all the operators belongs to current flavor
     do i=1,ckink

! check creators, if meet it, return 1
         if ( abs( time_s( index_s(i, flvr), flvr ) - time ) < epss ) then
             have = 1; EXIT
         endif ! back if ( abs( time_s( index_s(i, flvr), flvr ) - time ) < epss ) block

! check destroyers, if meet it, return 2
         if ( abs( time_e( index_e(i, flvr), flvr ) - time ) < epss ) then
             have = 2; EXIT
         endif ! back if ( abs( time_e( index_e(i, flvr), flvr ) - time ) < epss ) block

     enddo ! over i={1,ckink} loop

     return
  end subroutine ctqmc_make_equate

!!>>> ctqmc_make_search: determine index address of operators in the
!!>>> flavor part using bisection algorithm
  subroutine ctqmc_make_search(addr, ndim, time)
     use constants, only : dp

     use context, only : index_v, time_v

     implicit none

! external arguments
! index address of operators
     integer, intent(out) :: addr

! number of operators
     integer, intent(in)  :: ndim

! imaginary time of operators
     real(dp), intent(in) :: time

! local variables
! loop index
     integer :: k

! lower boundary
     integer :: klo

! upper boundary
     integer :: khi

! init the boundaries
     klo = 1
     khi = ndim

! look up the ordered table using bisection algorithm
     do while ( khi - klo > 1 )
         k = (khi + klo) / 2
         if ( time_v( index_v(k) ) > time ) then
             khi = k
         else
             klo = k
         endif ! back if ( time_v( index_v(k) ) > time ) block
     enddo ! over do while loop

! test the left and right boundary, determine which point is our desired
     if ( time_v( index_v(khi) ) == time ) then
         addr = khi
     else
         addr = klo
     endif ! back if ( time_v( index_v(khi) ) == time ) block

     return
  end subroutine ctqmc_make_search

!!========================================================================
!!>>> service layer: utility subroutines to build colour and flavor    <<<
!!========================================================================

!!>>> ctqmc_make_colour: generate perturbation expansion series for the
!!>>> colour (determinant) part, it should be synchronized with the
!!>>> flavor part
  subroutine ctqmc_make_colour(flvr, kink)
     use constants, only : dp
     use spring, only : spring_sfmt_stream

     use control, only : beta
     use context, only : ckink
     use context, only : rank

     implicit none

! external arguments
! current flavor channel
     integer, intent(in) :: flvr

! number of operator pair
     integer, intent(in) :: kink

! local variables
! loop index
     integer  :: i

! data for imaginary time \tau
     real(dp) :: time(2*kink)

! generate 2*kink random numbers range from 0 to 1
     do i=1,2*kink
         time(i) = spring_sfmt_stream()
     enddo ! over i={1,2*kink} loop

! scale time from [0,1] to [0, beta]
     time = time * beta

! sort time series
     call s_sorter(2*kink, time)

! insert new operators into the colour part
     do i=1,kink
         call cat_insert_colour( flvr, i, i, time(2*i-1), time(2*i) )
         ckink = i
     enddo ! over i={1,kink} loop

! update the rank
     rank(flvr) = ckink

     return
  end subroutine ctqmc_make_colour

!!>>> ctqmc_make_flavor: generate perturbation expansion series for the
!!>>> flavor (operator trace) part, it should be synchronized with the
!!>>> colour part.
!!>>> note: ctqmc_make_colour() must be called beforehand
  subroutine ctqmc_make_flavor(flvr, kink)
     use constants, only : dp

     use context, only : index_s, index_e, time_s, time_e

     implicit none

! external arguments
! current flavor channel
     integer, intent(in) :: flvr

! number of operator pair
     integer, intent(in) :: kink

! local variables
! loop index for operator pair
     integer  :: i

! index address for create and destroy operators
     integer  :: is, ie

! \tau_s and \tau_e for create and destroy operators
     real(dp) :: ts, te

     do i=1,kink

! determine index address, create operator first, and then destroy operator
         is = 2 * i -1
         ie = 2 * i

! get imaginary time from the colour part
         ts = time_s( index_s(i, flvr), flvr )
         te = time_e( index_e(i, flvr), flvr )

! insert new operators into the flavor part
         call cat_insert_flavor(flvr, is, ie, ts, te)

     enddo ! over i={1,kink} loop

     return
  end subroutine ctqmc_make_flavor

!!========================================================================
!!>>> service layer: utility subroutines to show the colour and flavor <<<
!!========================================================================

!!>>> ctqmc_make_display: display operators information (include colour
!!>>> and flavor parts) on the screen, only used to debug the code
  subroutine ctqmc_make_display(show_type)
     use constants, only : mystd
     use stack, only : istack_getrest

     use control, only : norbs, ncfgs
     use context, only : index_s, index_e, time_s, time_e
     use context, only : empty_v, index_v, type_v, flvr_v, time_v, expt_t, expt_v
     use context, only : rank

     implicit none

! external arguments
! control flag, output style
! if show_type = 1, display the colour part
! if show_type = 2, display the flavor part
     integer, intent(in) :: show_type

! local variables
! loop index over orbitals
     integer :: i

! loop index over operators
     integer :: j

! total number of operators in the flavor part
     integer :: nsize

! evaluate nsize at first
     nsize = istack_getrest( empty_v )

! display the operators (colour part)
     if ( show_type == 1 ) then
         do i=1,norbs
             write(mystd,'(4X,a,i4)') '# flavor:', i

             write(mystd,'(4X,a,i4)') '# time_s data:', rank(i)
             do j=1,rank(i)
                 write(mystd,'(4X,2i4,f12.6)') i, j, time_s( index_s(j, i), i )
             enddo ! over j={1,rank(i)} loop

             write(mystd,'(4X,a,i4)') '# time_e data:', rank(i)
             do j=1,rank(i)
                 write(mystd,'(4X,2i4,f12.6)') i, j, time_e( index_e(j, i), i )
             enddo ! over j={1,rank(i)} loop

             write(mystd,*) ! write empty lines
             write(mystd,*)
         enddo ! over i={1,norbs} loop

! display the operators (flavor part)
     else
         do j=1,nsize
             write(mystd,'(4X,a)') '< diag >'
             do i=1,ncfgs
                 write(mystd,'(4X,2i4,G16.8)') j, i, expt_v( i, index_v(j) )
             enddo ! over i={1,ncfgs} loop
             write(mystd,*) ! write empty line

             write(mystd,'(4X,a,i4)',advance='no') '>>>', j
             write(mystd,'(2X,a,i4)',advance='no') 'flvr:', flvr_v( index_v(j) )
             write(mystd,'(2X,a,i4)',advance='no') 'type:', type_v( index_v(j) )
             write(mystd,'(2X,a,f12.6)')           'time:', time_v( index_v(j) )
             write(mystd,*) ! write empty line
         enddo ! over j={1,nsize} loop

         write(mystd,'(4X,a)') '< diag >'
         do i=1,ncfgs
             write(mystd,'(4X,2i4,G16.8)') 9999, i, expt_t(i, 2)
         enddo ! over i={1,ncfgs} loop
         write(mystd,*) ! write empty line

     endif ! back if ( show_type == 1 ) block

     return
  end subroutine ctqmc_make_display
