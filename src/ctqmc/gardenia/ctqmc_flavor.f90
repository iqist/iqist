!!!-----------------------------------------------------------------------
!!! project : gardenia
!!! program : cat_insert_ztrace
!!!           cat_remove_ztrace
!!!           cat_lshift_ztrace
!!!           cat_rshift_ztrace
!!!           cat_reswap_ztrace  <<<---
!!!           cat_insert_segment
!!!           cat_remove_segment
!!!           cat_lshift_segment
!!!           cat_rshift_segment
!!!           cat_reswap_segment <<<---
!!!           ctqmc_make_flavor1
!!!           ctqmc_make_flavor2
!!!           ctqmc_make_flavor3
!!!           ctqmc_make_flavor4 <<<---
!!!           ctqmc_spin_counter <<<---
!!!           ctqmc_make_overlap
!!!           ctqmc_make_compare <<<---
!!!           ctqmc_make_segment
!!!           ctqmc_make_display <<<---
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

!!>>> cat_insert_ztrace: calculate the trace ratio for insert new segment
!!>>> or anti-segment on perturbation expansion series
  subroutine cat_insert_ztrace(flvr, anti, tau_start, tau_end, trace_ratio)
     use constants, only : dp, zero

     use control, only : norbs
     use control, only : mune, beta
     use context, only : eimp, uumat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! whether it is an anti-segment
     logical, intent(in)   :: anti

! imaginary time \tau_s for start point
     real(dp), intent(in)  :: tau_start

! imaginary time \tau_e for end   point
     real(dp), intent(in)  :: tau_end

! the desired ztrace ratio
     real(dp), intent(out) :: trace_ratio

! local variables
! loop index over orbitals
     integer  :: i

! dummy variables
     real(dp) :: raux

! length for segment or anti-segment
     real(dp) :: dtau

! segment overlap between flvr and other else flavors
     real(dp) :: ovlp(norbs)
     real(dp) :: ovlp1(norbs)
     real(dp) :: ovlp2(norbs)

! initialize dtau
     dtau  = zero

! initialize ovlp
     ovlp  = zero

     ovlp1 = zero
     ovlp2 = zero

! calculate ovlp and dtau
! for segment case
     if ( anti .eqv. .false. ) then
         if ( tau_start < tau_end ) then
             dtau = tau_end - tau_start
             call ctqmc_make_overlap(flvr, tau_start, tau_end, ovlp)
! the new segment winds around the circle
         else
             dtau = beta - tau_start + tau_end - zero
             call ctqmc_make_overlap(flvr, zero, tau_end, ovlp1)
             call ctqmc_make_overlap(flvr, tau_start, beta, ovlp2)
             ovlp = ovlp1 + ovlp2
         endif ! back if ( tau_start < tau_end ) block
! for anti-segment case
     else
         if ( tau_start > tau_end ) then
             dtau = tau_start - tau_end
             call ctqmc_make_overlap(flvr, tau_end, tau_start, ovlp)
! the new anti-segment winds around the circle
         else
             dtau = tau_start - zero + beta - tau_end
             call ctqmc_make_overlap(flvr, zero, tau_start, ovlp1)
             call ctqmc_make_overlap(flvr, tau_end, beta, ovlp2)
             ovlp = ovlp1 + ovlp2
         endif ! back if ( tau_start > tau_end ) block
     endif ! back if ( anti .eqv. .false. ) block

! calculate the exponent factor:
! +\tilde{\tau} \mu - U * \tau_{overlap} for segment
! -\tilde{\tau} \mu + U * \tau_{overlap} for anti-segment
     raux = dtau * ( mune - eimp(flvr) )
     do i=1,norbs
         raux = raux - uumat(flvr, i) * ovlp(i)
     enddo ! over i={1,norbs} loop

! evaluate the final ztrace ratio
     if ( anti .eqv. .false. ) then
         trace_ratio = exp(+raux)
     else
         trace_ratio = exp(-raux)
     endif ! back if ( anti .eqv. .false. ) block

     return
  end subroutine cat_insert_ztrace

!!>>> cat_remove_ztrace: calculate the trace ratio for remove old segment
!!>>> or anti-segment on perturbation expansion series
  subroutine cat_remove_ztrace(flvr, anti, tau_start, tau_end, trace_ratio)
     use constants, only : dp, zero

     use control, only : norbs
     use control, only : mune, beta
     use context, only : eimp, uumat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! whether it is an anti-segment
     logical, intent(in)   :: anti

! imaginary time \tau_s for start point
     real(dp), intent(in)  :: tau_start

! imaginary time \tau_e for end   point
     real(dp), intent(in)  :: tau_end

! the desired ztrace ratio
     real(dp), intent(out) :: trace_ratio

! local variables
! loop index over orbitals
     integer  :: i

! dummy variables
     real(dp) :: raux

! length for segment or anti-segment
     real(dp) :: dtau

! segment overlap between flvr and other else flavors
     real(dp) :: ovlp(norbs)
     real(dp) :: ovlp1(norbs)
     real(dp) :: ovlp2(norbs)

! initialize dtau
     dtau  = zero

! initialize ovlp
     ovlp  = zero

     ovlp1 = zero
     ovlp2 = zero

! calculate ovlp and dtau
     if ( anti .eqv. .false. ) then
! for segment case
         if ( tau_start < tau_end ) then
             dtau = tau_end - tau_start
             call ctqmc_make_overlap(flvr, tau_start, tau_end, ovlp)
! the selected segment winds around the circle
         else
             dtau = beta - tau_start + tau_end - zero
             call ctqmc_make_overlap(flvr, zero, tau_end, ovlp1)
             call ctqmc_make_overlap(flvr, tau_start, beta, ovlp2)
             ovlp = ovlp1 + ovlp2
         endif ! back if ( tau_start < tau_end ) block
! for anti-segment case
     else
         if ( tau_start > tau_end ) then
             dtau = tau_start - tau_end
             call ctqmc_make_overlap(flvr, tau_end, tau_start, ovlp)
! the selected anti-segment winds around the circle
         else
             dtau = tau_start - zero + beta - tau_end
             call ctqmc_make_overlap(flvr, zero, tau_start, ovlp1)
             call ctqmc_make_overlap(flvr, tau_end, beta, ovlp2)
             ovlp = ovlp1 + ovlp2
         endif ! back if ( tau_start > tau_end ) block
     endif ! back if ( anti .eqv. .false. ) block

! calculate the exponent factor:
! -\tilde{\tau} \mu + U * \tau_{overlap} for segment
! +\tilde{\tau} \mu - U * \tau_{overlap} for anti-segment
     raux = dtau * ( mune - eimp(flvr) )
     do i=1,norbs
         raux = raux - uumat(flvr, i) * ovlp(i)
     enddo ! over i={1,norbs} loop

! evaluate the final ztrace ratio
     if ( anti .eqv. .false. ) then
         trace_ratio = exp(-raux)
     else
         trace_ratio = exp(+raux)
     endif ! back if ( anti .eqv. .false. ) block

     return
  end subroutine cat_remove_ztrace

!!>>> cat_lshift_ztrace: calculate the trace ratio for left shift old
!!>>> segment or anti-segment on perturbation expansion series
  subroutine cat_lshift_ztrace(flvr, ring, tau_start1, tau_start2, trace_ratio)
     use constants, only : dp, zero

     use control, only : norbs
     use control, only : mune, beta
     use context, only : eimp, uumat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! whether the update operation winds around the circle
     logical, intent(in)   :: ring

! imaginary time \tau_s for start point (the old one)
     real(dp), intent(in)  :: tau_start1

! imaginary time \tau_s for start point (the new one)
     real(dp), intent(in)  :: tau_start2

! the desired ztrace ratio
     real(dp), intent(out) :: trace_ratio

! local variables
! loop index over orbitals
     integer  :: i

! dummy variables
     real(dp) :: raux

! length for segment or anti-segment
     real(dp) :: dtau

! segment overlap between flvr and other else flavors
     real(dp) :: ovlp(norbs)
     real(dp) :: ovlp1(norbs)
     real(dp) :: ovlp2(norbs)

! initialize dtau
     dtau  = zero

! initialize ovlp
     ovlp  = zero

     ovlp1 = zero
     ovlp2 = zero

! calculate ovlp and dtau
! it does not wind around the circle
     if ( ring .eqv. .false. ) then
! stretch the segment
         if ( tau_start1 > tau_start2 ) then
             dtau = tau_start1 - tau_start2
             call ctqmc_make_overlap(flvr, tau_start2, tau_start1, ovlp)
! shrink the segment
         else
             dtau = tau_start2 - tau_start1
             call ctqmc_make_overlap(flvr, tau_start1, tau_start2, ovlp)
         endif ! back if ( tau_start1 > tau_start2 ) block
! it does wind around the circle
     else
! shrink the segment
         if ( tau_start1 > tau_start2 ) then
             dtau = beta - tau_start1 + tau_start2 - zero
             call ctqmc_make_overlap(flvr, zero, tau_start2, ovlp1)
             call ctqmc_make_overlap(flvr, tau_start1, beta, ovlp2)
             ovlp = ovlp1 + ovlp2
! stretch the segment
         else
             dtau = tau_start1 - zero + beta - tau_start2
             call ctqmc_make_overlap(flvr, zero, tau_start1, ovlp1)
             call ctqmc_make_overlap(flvr, tau_start2, beta, ovlp2)
             ovlp = ovlp1 + ovlp2
         endif ! back if ( tau_start1 > tau_start2 ) block
     endif ! back if ( ring .eqv. .false. ) block

! calculate the exponent factor:
! +\tilde{\tau} \mu - U * \tau_{overlap} for stretch
! -\tilde{\tau} \mu + U * \tau_{overlap} for shrink
     raux = dtau * ( mune - eimp(flvr) )
     do i=1,norbs
         raux = raux - uumat(flvr, i) * ovlp(i)
     enddo ! over i={1,norbs} loop

! evaluate the final ztrace ratio
     if ( ring .eqv. .false. ) then
         if ( tau_start1 > tau_start2 ) then
             trace_ratio = exp(+raux)
         else
             trace_ratio = exp(-raux)
         endif ! back if ( tau_start1 > tau_start2 ) block
     else
         if ( tau_start1 > tau_start2 ) then
             trace_ratio = exp(-raux)
         else
             trace_ratio = exp(+raux)
         endif ! back if ( tau_start1 > tau_start2 ) block
     endif ! back if ( ring .eqv. .false. ) block

     return
  end subroutine cat_lshift_ztrace

!!>>> cat_rshift_ztrace: calculate the trace ratio for right shift old
!!>>> segment or anti-segment on perturbation expansion series
  subroutine cat_rshift_ztrace(flvr, ring, tau_end1, tau_end2, trace_ratio)
     use constants, only : dp, zero

     use control, only : norbs
     use control, only : mune, beta
     use context, only : eimp, uumat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! whether the update operation winds around the circle
     logical, intent(in)   :: ring

! imaginary time \tau_e for end   point (the old one)
     real(dp), intent(in)  :: tau_end1

! imaginary time \tau_e for end   point (the new one)
     real(dp), intent(in)  :: tau_end2

! the desired ztrace ratio
     real(dp), intent(out) :: trace_ratio

! local variables
! loop index over orbitals
     integer  :: i

! dummy variables
     real(dp) :: raux

! length for segment or anti-segment
     real(dp) :: dtau

! segment overlap between flvr and other else flavors
     real(dp) :: ovlp(norbs)
     real(dp) :: ovlp1(norbs)
     real(dp) :: ovlp2(norbs)

! initialize dtau
     dtau  = zero

! initialize ovlp
     ovlp  = zero

     ovlp1 = zero
     ovlp2 = zero

! calculate ovlp and dtau
! it does not wind around the circle
     if ( ring .eqv. .false. ) then
! shrink the segment
         if ( tau_end1 > tau_end2 ) then
             dtau = tau_end1 - tau_end2
             call ctqmc_make_overlap(flvr, tau_end2, tau_end1, ovlp)
! stretch the segment
         else
             dtau = tau_end2 - tau_end1
             call ctqmc_make_overlap(flvr, tau_end1, tau_end2, ovlp)
         endif ! back if ( tau_end1 > tau_end2 ) block
! it does wind around the circle
     else
! stretch the segment
         if ( tau_end1 > tau_end2 ) then
             dtau = beta - tau_end1 + tau_end2 - zero
             call ctqmc_make_overlap(flvr, zero, tau_end2, ovlp1)
             call ctqmc_make_overlap(flvr, tau_end1, beta, ovlp2)
             ovlp = ovlp1 + ovlp2
! shrink the segment
         else
             dtau = tau_end1 - zero + beta - tau_end2
             call ctqmc_make_overlap(flvr, zero, tau_end1, ovlp1)
             call ctqmc_make_overlap(flvr, tau_end2, beta, ovlp2)
             ovlp = ovlp1 + ovlp2
         endif ! back if ( tau_end1 > tau_end2 ) block
     endif ! back if ( ring .eqv. .false. ) block

! calculate the exponent factor:
! +\tilde{\tau} \mu - U * \tau_{overlap} for stretch
! -\tilde{\tau} \mu + U * \tau_{overlap} for shrink
     raux = dtau * ( mune - eimp(flvr) )
     do i=1,norbs
         raux = raux - uumat(flvr, i) * ovlp(i)
     enddo ! over i={1,norbs} loop

! evaluate the final ztrace ratio
     if ( ring .eqv. .false. ) then
         if ( tau_end1 > tau_end2 ) then
             trace_ratio = exp(-raux)
         else
             trace_ratio = exp(+raux)
         endif ! back if ( tau_end1 > tau_end2 ) block
     else
         if ( tau_end1 > tau_end2 ) then
             trace_ratio = exp(+raux)
         else
             trace_ratio = exp(-raux)
         endif ! back if ( tau_end1 > tau_end2 ) block
     endif ! back if ( ring .eqv. .false. ) block

     return
  end subroutine cat_rshift_ztrace

!!>>> cat_reswap_ztrace: calculate the trace ratio for swap between
!!>>> segment and anti-segment on perturbation expansion series
  subroutine cat_reswap_ztrace(flvr, trace_ratio)
     use constants, only : dp, zero, one

     use control, only : beta
     use context, only : ckink, cstat
     use context, only : index_s, index_e, time_s, time_e
     use context, only : rank, stts

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! the desired ztrace ratio
     real(dp), intent(out) :: trace_ratio

! local variables
! loop index over segments
     integer  :: i

! dummy ztrace
     real(dp) :: p

! imaginary time \tau_s for start point
     real(dp) :: ts

! imaginary time \tau_e for end   point
     real(dp) :: te

! initialize trace_ratio
     trace_ratio = one

! determine cstat and ckink
     cstat = stts(flvr)
     ckink = rank(flvr)

! case 1: there is no segments, null configuration
!-------------------------------------------------------------------------
! swap to cstat = 3
     if      ( cstat == 0 ) then
         ts = zero
         te = beta
         call cat_insert_ztrace(flvr, .false., ts, te, p)
         trace_ratio = p

! case 2: there are segments, segment configuration
!-------------------------------------------------------------------------
! swap to cstat = 2
     else if ( cstat == 1 ) then
! remove occupied states
         do i=1,ckink
             ts = time_s(index_s(i, flvr), flvr)   ! get \tau_s at start point
             te = time_e(index_e(i, flvr), flvr)   ! get \tau_e at end   point
             call cat_remove_ztrace(flvr, .false., ts, te, p)
             trace_ratio = trace_ratio * p
         enddo ! over i={1,ckink} loop

! fill unoccupied states: head
         ts = zero
         te = time_s(index_s(1, flvr), flvr)
         call cat_insert_ztrace(flvr, .false., ts, te, p)
         trace_ratio = trace_ratio * p

! fill unoccupied states: body
         do i=1,ckink-1
             ts = time_e(index_e(i,   flvr), flvr) ! get \tau_s at end   point
             te = time_s(index_s(i+1, flvr), flvr) ! get \tau_e at start point
             call cat_insert_ztrace(flvr, .false., ts, te, p)
             trace_ratio = trace_ratio * p
         enddo ! over i={1,ckink-1} loop

! fill unoccupied states: tail
         ts = time_e(index_e(ckink, flvr), flvr)
         te = beta
         call cat_insert_ztrace(flvr, .false., ts, te, p)
         trace_ratio = trace_ratio * p

! case 3: there are segments, anti-segment configuration
!-------------------------------------------------------------------------
! swap to cstat = 1
     else if ( cstat == 2 ) then
! fill unoccupied states
         do i=1,ckink
             ts = time_e(index_e(i, flvr), flvr)   ! get \tau_s at start point
             te = time_s(index_s(i, flvr), flvr)   ! get \tau_e at end   point
             call cat_insert_ztrace(flvr, .false., ts, te, p)
             trace_ratio = trace_ratio * p
         enddo ! over i={1,ckink} loop

! remove occupied states: head
         ts = zero
         te = time_e(index_e(1, flvr), flvr)
         call cat_remove_ztrace(flvr, .false., ts, te, p)
         trace_ratio = trace_ratio * p

! remove occupied states: body
         do i=1,ckink-1
             ts = time_s(index_s(i,   flvr), flvr) ! get \tau_s at end   point
             te = time_e(index_e(i+1, flvr), flvr) ! get \tau_e at start point
             call cat_remove_ztrace(flvr, .false., ts, te, p)
             trace_ratio = trace_ratio * p
         enddo ! over i={1,ckink-1} loop

! remove occupied states: tail
         ts = time_s(index_s(ckink, flvr), flvr)
         te = beta
         call cat_remove_ztrace(flvr, .false., ts, te, p)
         trace_ratio = trace_ratio * p

! case 4: there is no segments, full configuration
!-------------------------------------------------------------------------
! swap to cstat = 0
     else if ( cstat == 3 ) then
         ts = zero
         te = beta
         call cat_remove_ztrace(flvr, .false., ts, te, p)
         trace_ratio = p

     endif ! back if ( cstat == 0 ) block

     return
  end subroutine cat_reswap_ztrace

!!========================================================================
!!>>> service layer: update perturbation expansion series              <<<
!!========================================================================

!!>>> cat_insert_segment: update the perturbation expansion series for
!!>>> insert new segment or anti-segment
  subroutine cat_insert_segment(flvr, is, ie, tau_start, tau_end)
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

! index address for insert new segment or anti-segment
     integer, intent(in)  :: is
     integer, intent(in)  :: ie

! imaginary time \tau_s for start point
     real(dp), intent(in) :: tau_start

! imaginary time \tau_e for end   point
     real(dp), intent(in) :: tau_end

! local variables
! loop index over segments and frequencies
     integer  :: i

! memory address for new start and end points
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
  end subroutine cat_insert_segment

!!>>> cat_remove_segment: update the perturbation expansion series for
!!>>> remove old segment or anti-segment
  subroutine cat_remove_segment(flvr, is, ie)
     use stack, only : istack_push

     use context, only : ckink
     use context, only : empty_s, empty_e, index_s, index_e

     implicit none

! external arguments
! current flavor channel
     integer, intent(in) :: flvr

! index address for remove old segment or anti-segment
     integer, intent(in) :: is
     integer, intent(in) :: ie

! local variables
! loop index over segments
     integer :: i

! memory address for old start and end points
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
  end subroutine cat_remove_segment

!!>>> cat_lshift_segment: update the perturbation expansion series for
!!>>> left shift old segment or anti-segment
  subroutine cat_lshift_segment(flvr, iso, isn, tau_start)
     use constants, only : dp

     use control, only : nfreq
     use context, only : ckink
     use context, only : index_s, time_s, exp_s
     use context, only : rmesh

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address for lshift old segment or anti-segment
     integer, intent(in)  :: iso
     integer, intent(in)  :: isn

! imaginary time \tau_s for start point (the new one)
     real(dp), intent(in) :: tau_start

! local variables
! loop index over segments and frequencies
     integer  :: i

! memory address for new start point
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
  end subroutine cat_lshift_segment

!!>>> cat_rshift_segment: update the perturbation expansion series for
!!>>> right shift old segment or anti-segment
  subroutine cat_rshift_segment(flvr, ieo, ien, tau_end)
     use constants, only : dp

     use control, only : nfreq
     use context, only : ckink
     use context, only : index_e, time_e, exp_e
     use context, only : rmesh

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address for rshift old segment or anti-segment
     integer, intent(in)  :: ieo
     integer, intent(in)  :: ien

! imaginary time \tau_e for end   point (the new one)
     real(dp), intent(in) :: tau_end

! local variables
! loop index over segments and frequencies
     integer  :: i

! memory address for new end   point
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
  end subroutine cat_rshift_segment

!!>>> cat_reswap_segment: update the perturbation expansion series for
!!>>> swap segment and anti-segment
  subroutine cat_reswap_segment(flvr)
     use constants, only : dp

     use control, only : nfreq
     use context, only : ckink
     use context, only : index_s, index_e, time_s, time_e, exp_s, exp_e

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! local variables
! loop index over segments
     integer  :: i

! dummy time_s and time_e
     real(dp) :: time_t

! dummy exp_s and exp_e
     complex(dp) :: exp_t(nfreq)

! swap time_s and time_e
     do i=1,ckink
         time_t = time_s(index_s(i, flvr), flvr)
         time_s(index_s(i, flvr), flvr) = time_e(index_e(i, flvr), flvr)
         time_e(index_e(i, flvr), flvr) = time_t
     enddo ! over i={1,ckink} loop

! swap exp_s and exp_e
     do i=1,ckink
         exp_t = exp_s(:, index_s(i, flvr), flvr)
         exp_s(:, index_s(i, flvr), flvr) = exp_e(:, index_e(i, flvr), flvr)
         exp_e(:, index_e(i, flvr), flvr) = exp_t
     enddo ! over i={1,ckink} loop

     return
  end subroutine cat_reswap_segment

!!========================================================================
!!>>> service layer: make segments from perturbation expansion series  <<<
!!========================================================================

!!>>> ctqmc_make_flavor1: determine \tau_s, \tau_e and \tau_max for insert
!!>>> new segment or anti-segment
  subroutine ctqmc_make_flavor1(flvr, is, ie, anti, ladd, tau_start, tau_end, tau_max)
     use constants, only : dp, zero, half
     use spring, only : spring_sfmt_stream

     use control, only : beta
     use context, only : ckink, cstat
     use context, only : index_s, index_e, time_s, time_e
     use context, only : stts

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address to insert new segment or anti-segment
! is and ie are for start and end points, respectively
     integer, intent(out)  :: is, ie

! whether it is an anti-segment
     logical, intent(out)  :: anti

! whether the new segment or anti-segment can be inserted diagrammatically
     logical, intent(out)  :: ladd

! start point of the new segment
     real(dp), intent(out) :: tau_start

! end   point of the new segment
     real(dp), intent(out) :: tau_end

! possible maximum length of the new segment
     real(dp), intent(out) :: tau_max

! local variables
! loop index over segments
     integer  :: i

! imaginary time for start and end points
     real(dp) :: ts
     real(dp) :: te

! initialize is and ie
     is = 1
     ie = 1

! select start point in imaginary time of the new segment randomly
     tau_start = spring_sfmt_stream() * beta

! initialize tau_end and tau_max
     tau_end = zero
     tau_max = zero

! initialize ladd
     ladd = .true.

! determine anti randomly
     if ( spring_sfmt_stream() > half ) then
         anti = .true.  ! insert anti-segment
     else
         anti = .false. ! insert segment
     endif ! back if ( spring_sfmt_stream() > half ) block

!-------------------------------------------------------------------------
! stage 1: need to insert a segment
!-------------------------------------------------------------------------
     if ( anti .eqv. .false. ) then

! case 1: there is no segments, null configuration
!-------------------------------------------------------------------------
         if ( stts(flvr) == 0 ) then
             is = 1
             ie = 1
             tau_max = beta
             tau_end = spring_sfmt_stream() * tau_max + tau_start

! check the position of tau_end and setup cstat
! zero < tau_start < tau_end < beta, turn to segment configuration
             if ( tau_end < beta ) then
                 cstat = 1
! zero < tau_end < tau_start < beta, turn to anti-segment configuration
             else
                 cstat = 2
                 tau_end = tau_end - beta
             endif ! back if ( tau_end < beta ) block
         endif ! back if ( stts(flvr) == 0 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! case 2: there are segments, segment configuration
!-------------------------------------------------------------------------
         if ( stts(flvr) == 1 ) then

! search whether tau_start is in an existing segment
             do i=1,ckink
                 ts = time_s(index_s(i, flvr), flvr) ! get \tau_s at start point
                 te = time_e(index_e(i, flvr), flvr) ! get \tau_e at end   point

                 if ( tau_start > ts .and. tau_start < te ) then
                     ladd = .false.
                     RETURN ! return to the parent subroutines immediately
                 endif ! back if ( tau_start > ts .and. tau_start < te ) block
             enddo ! over i={1,ckink} loop

! now we know we can insert tau_start, and then tau_end and tau_max should
! be determined carefully.
! case 2A: tau_start is in front of all segments
! zero < tau_start < tau_end < ... < beta, keep segment configuration
             if      ( tau_start < time_s(index_s(1    , flvr), flvr) ) then
                 is = 1
                 ie = 1
                 cstat = 1
                 tau_max = time_s(index_s(1, flvr), flvr) - tau_start
                 tau_end = spring_sfmt_stream() * tau_max + tau_start

! case 2B: tau_start is after all segments
             else if ( tau_start > time_e(index_e(ckink, flvr), flvr) ) then
                 is = ckink + 1
                 ie = ckink + 1
                 tau_max = beta - tau_start + time_s(index_s(1, flvr), flvr) - zero
                 tau_end = spring_sfmt_stream() * tau_max + tau_start

! check the position of tau_end and setup cstat
! zero < ... < tau_start < tau_end < beta, keep segment configuration
                 if ( tau_end < beta ) then
                     cstat = 1
! zero < tau_end < ... < tau_start < beta, turn to anti-segment configuration
                 else
                     cstat = 2
                     ie = 1
                     tau_end = tau_end - beta
                 endif ! back if ( tau_end < beta ) block

! case 2C: tau_start is in the middle of two segments
! zero < ... < tau_start < tau_end < ... < end, keep segment configuration
             else
                 do i=1,ckink-1
                     ts = time_s(index_s(i+1, flvr), flvr)
                     te = time_e(index_e(i  , flvr), flvr)

! determine the position of tau_end and tau_max
                     if ( tau_start > te .and. tau_start < ts ) then
                         is = i + 1
                         ie = i + 1
                         cstat = 1
                         tau_max = ts - tau_start
                         tau_end = spring_sfmt_stream() * tau_max + tau_start
                         EXIT ! terminate the innermost do construct
                     endif ! back if ( tau_start > te .and. tau_start < ts ) block
                 enddo ! over i={1,ckink-1} loop

             endif ! back if      ( tau_start < time_s(index_s(1    , flvr), flvr) ) block

         endif ! back if ( stts(flvr) == 1 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! case 3: there are segments, anti-segment configuration
!-------------------------------------------------------------------------
         if ( stts(flvr) == 2 ) then

! search whether tau_start is in an existing segment or anti-segment
! case 3A: tau_start is in the first segment [0, tau_e(1)]
             if      ( tau_start < time_e(index_e(1    , flvr), flvr) ) then
                 ladd = .false.
                 RETURN ! return to the parent subroutines immediately

! case 3B: tau_start is in the last segment [tau_s(ckink), beta]
             else if ( tau_start > time_s(index_s(ckink, flvr), flvr) ) then
                 ladd = .false.
                 RETURN ! return to the parent subroutines immediately

! case 3C: tau_start is in the immediate region, maybe in an existing segment
             else
                 do i=1,ckink-1
                     ts = time_s(index_s(i  , flvr), flvr) ! get \tau_s at start point
                     te = time_e(index_e(i+1, flvr), flvr) ! get \tau_e at end   point

                     if ( tau_start > ts .and. tau_start < te ) then
                         ladd = .false.
                         RETURN ! return to the parent subroutines immediately
                     endif ! back if ( tau_start > ts .and. tau_start < te ) block
                 enddo ! over i={1,ckink-1} loop

             endif ! back if      ( tau_start < time_e(index_e(1    , flvr), flvr) ) block

! now we know we can insert tau_start, and then tau_end and tau_max should
! be determined carefully.
! zero < ... < tau_start < tau_end < ... < beta, keep anti-segment configuration
             do i=1,ckink
                 ts = time_s(index_s(i, flvr), flvr) ! get \tau_s at start point
                 te = time_e(index_e(i, flvr), flvr) ! get \tau_e at end   point

! determine the position of tau_end and tau_max
                 if ( tau_start > te .and. tau_start < ts ) then
                     is = i
                     ie = i + 1
                     cstat = 2
                     tau_max = ts - tau_start
                     tau_end = spring_sfmt_stream() * tau_max + tau_start
                     EXIT ! terminate the innermost do construct
                 endif ! back if ( tau_start > te .and. tau_start < ts ) block
             enddo ! over i={1,ckink} loop

         endif ! back if ( stts(flvr) == 2 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! case 4: there is no segments, full configuration
!-------------------------------------------------------------------------
         if ( stts(flvr) == 3 ) then
             ladd = .false.
             RETURN ! return to the parent subroutines immediately
         endif ! back if ( stts(flvr) == 3 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

!-------------------------------------------------------------------------
! stage 2: need to insert an anti-segment
!-------------------------------------------------------------------------
     else ! anti .eqv. .true.

! case 1: there is no segments, null configuration
!-------------------------------------------------------------------------
         if ( stts(flvr) == 0 ) then
             ladd = .false.
             RETURN ! return to the parent subroutines immediately
         endif ! if ( stts(flvr) == 0 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! case 2: there are segments, segment configuration
!-------------------------------------------------------------------------
         if ( stts(flvr) == 1 ) then

! search whether tau_start is in an unoccupied region
! case 2A: tau_start is in front of all segments
             if      ( tau_start < time_s(index_s(1    , flvr), flvr) ) then
                 ladd = .false.
                 RETURN ! return to the parent subroutines immediately

! case 2B: tau_start is after all segments
             else if ( tau_start > time_e(index_e(ckink, flvr), flvr) ) then
                 ladd = .false.
                 RETURN ! return to the parent subroutines immediately

! case 2C: tau_start is in the middle of two segments
             else
                 do i=1,ckink-1
                     ts = time_s(index_s(i+1, flvr), flvr) ! get \tau_s at start point
                     te = time_e(index_e(i  , flvr), flvr) ! get \tau_e at end   point

                     if ( tau_start > te .and. tau_start < ts ) then
                         ladd = .false.
                         RETURN ! return to the parent subroutines immediately
                     endif ! back if ( tau_start > te .and. tau_start < ts ) block
                 enddo ! over i={1,ckink-1} loop

             endif ! back if      ( tau_start < time_s(index_s(1    , flvr), flvr) ) block

! now we know we can insert tau_start, and then tau_end and tau_max should
! be determined carefully.
! zero < ... < tau_start < tau_end < ... < beta, keep segment configuration
             do i=1,ckink
                 ts = time_s(index_s(i, flvr), flvr) ! get \tau_s at start point
                 te = time_e(index_e(i, flvr), flvr) ! get \tau_e at end   point

! determine the position of tau_end and tau_max
                 if ( tau_start > ts .and. tau_start < te ) then
                     is = i + 1
                     ie = i
                     cstat = 1
                     tau_max = tau_start - ts
                     tau_end = tau_start - spring_sfmt_stream() * tau_max
                     EXIT ! terminate the innermost do construct
                 endif ! back if ( tau_start > ts .and. tau_start < te ) block
             enddo ! over i={1,ckink} loop

         endif ! back if ( stts(flvr) == 1 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! case 3: there are segments, anti-segment configuration
!-------------------------------------------------------------------------
         if ( stts(flvr) == 2 ) then

! search whether tau_start is in an existing segment or anti-segment
             do i=1,ckink
                 ts = time_s(index_s(i, flvr), flvr) ! get \tau_s at start point
                 te = time_e(index_e(i, flvr), flvr) ! get \tau_e at end   point

                 if ( tau_start > te .and. tau_start < ts ) then
                     ladd = .false.
                     RETURN ! return to the parent subroutines immediately
                 endif ! back if ( tau_start > te .and. tau_start < ts ) block
             enddo ! over i={1,ckink} loop

! now we know we can insert tau_start, and then tau_end and tau_max should
! be determined carefully.
! case 3A: tau_start is in the first segment [0, tau_e(1)]
             if      ( tau_start < time_e(index_e(1    , flvr), flvr) ) then
                 is = 1
                 ie = 1
                 tau_max = tau_start - zero + beta - time_s(index_s(ckink, flvr), flvr)
                 tau_end = tau_start - spring_sfmt_stream() * tau_max

! check the position of tau_end and setup cstat
! zero < tau_end < tau_start < ... < beta, keep anti-segment configuration
                 if ( tau_end > zero ) then
                     cstat = 2
! zero < tau_start < ... < tau_end < beta, turn to segment configuration
                 else
                     cstat = 1
                     ie = ckink + 1
                     tau_end = tau_end + beta
                 endif ! back if ( tau_end > zero ) block

! case 3B: tau_start is in the last segment [tau_s(ckink), beta]
! zero < ... < tau_end < tau_start < beta, keep anti-segment configuration
             else if ( tau_start > time_s(index_s(ckink, flvr), flvr) ) then
                 is = ckink + 1
                 ie = ckink + 1
                 cstat = 2
                 tau_max = tau_start - time_s(index_s(ckink, flvr), flvr)
                 tau_end = tau_start - spring_sfmt_stream() * tau_max

! case 3C: tau_start is in the immediate region, maybe in an existing segment
! zero < ... < tau_end < tau_start < ... < beta, keep anti-segment configuration
             else
                 do i=1,ckink-1
                     ts = time_s(index_s(i  , flvr), flvr) ! get \tau_s at start point
                     te = time_e(index_e(i+1, flvr), flvr) ! get \tau_e at end   point

! determine the position of tau_end and tau_max
                     if ( tau_start > ts .and. tau_start < te ) then
                         is = i + 1
                         ie = i + 1
                         cstat = 2
                         tau_max = tau_start - ts
                         tau_end = tau_start - spring_sfmt_stream() * tau_max
                         EXIT ! terminate the innermost do construct
                     endif ! back if ( tau_start > ts .and. tau_start < te ) block
                 enddo ! over i={1,ckink-1} loop

             endif ! back if      ( tau_start < time_e(index_e(1    , flvr), flvr) ) block

         endif ! back if ( stts(flvr) == 2 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! case 4: there is no segments, full configuration
!-------------------------------------------------------------------------
         if ( stts(flvr) == 3 ) then
             is = 1
             ie = 1
             tau_max = beta
             tau_end = tau_start - spring_sfmt_stream() * tau_max

! check the position of tau_end and setup cstat
! zero < tau_end < tau_start < beta, turn to anti-segment configuration
             if ( tau_end > zero ) then
                 cstat = 2
! zero < tau_start < tau_end < beta, turn to segment configuration
             else
                 cstat = 1
                 tau_end = tau_end + beta
             endif ! back if ( tau_end > zero ) block
         endif ! back if ( stts(flvr) == 3 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

     endif ! back if ( anti .eqv. .false. ) block

     return
  end subroutine ctqmc_make_flavor1

!!>>> ctqmc_make_flavor2: determine \tau_s, \tau_e and \tau_max for remove
!!>>> old segment or anti-segment
  subroutine ctqmc_make_flavor2(flvr, is, ie, anti, tau_start, tau_end, tau_max)
     use constants, only : dp, zero, half
     use spring, only : spring_sfmt_stream

     use control, only : beta
     use context, only : ckink, cstat
     use context, only : index_s, index_e, time_s, time_e
     use context, only : stts

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address to remove old segment or anti-segment
! is and ie are for start and end points, respectively
     integer, intent(out)  :: is, ie

! whether it is an anti-segment
     logical, intent(out)  :: anti

! start point of the selected segment
     real(dp), intent(out) :: tau_start

! end   point of the selected segment
     real(dp), intent(out) :: tau_end

! possible maximum length of the old segment
     real(dp), intent(out) :: tau_max

! initialize is and ie
     is = 1
     ie = 1

! randomly select start index address, which is used to access the segment
     is = ceiling( spring_sfmt_stream() * ckink )

! initialize tau_start, tau_end and tau_max
     tau_start = zero
     tau_end = zero
     tau_max = zero

! determine anti randomly
     if ( spring_sfmt_stream() > half ) then
         anti = .true.  ! remove anti-segment
     else
         anti = .false. ! remove segment
     endif ! back if ( spring_sfmt_stream() > half ) block

!-------------------------------------------------------------------------
! stage 1: need to remove a segment
!-------------------------------------------------------------------------
     if ( anti .eqv. .false. ) then

! case 1: there are segments, segment configuration
!-------------------------------------------------------------------------
         if ( stts(flvr) == 1 ) then

! case 1A: there is only one segment
! turn to null configuration
             if ( ckink == 1 ) then
                 ie = 1
                 cstat = 0
                 tau_start = time_s(index_s(1, flvr), flvr)
                 tau_end = time_e(index_e(1, flvr), flvr)
                 tau_max = beta

! case 1B: there are more than one segments
! keep segment configuration
             else
                 ie = is
                 cstat = 1
                 tau_start = time_s(index_s(is, flvr), flvr)
                 tau_end = time_e(index_e(ie, flvr), flvr)
! remove a normal segment, not the last segment
                 if ( is < ckink ) then
                     tau_max = time_s(index_s(is+1, flvr), flvr) - tau_start
! remove the last segment, pay special attention to tau_max
                 else
                     tau_max = beta - tau_start + time_s(index_s(1, flvr), flvr) - zero
                 endif ! back if ( is < ckink ) block

             endif ! back if ( ckink == 1 ) block

         endif ! back if ( stts(flvr) == 1 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! case 2: there are segments, anti-segment configuration
!-------------------------------------------------------------------------
         if ( stts(flvr) == 2 ) then

! case 2A: there is only one anti-segment
! turn to null configuration
             if ( ckink == 1 ) then
                 ie = 1
                 cstat = 0
                 tau_start = time_s(index_s(1, flvr), flvr)
                 tau_end = time_e(index_e(1, flvr), flvr)
                 tau_max = beta

! case 2B: there are more than one segment or anti-segment
             else
! remove a normal segment, not the last segment
! keep anti-segment configuration
                 if ( is < ckink ) then
                     ie = is + 1
                     cstat = 2
                     tau_start = time_s(index_s(is, flvr), flvr)
                     tau_end = time_e(index_e(ie, flvr), flvr)
                     tau_max = time_s(index_s(is+1, flvr), flvr) - tau_start
! remove the last segment, pay special attention to tau_max
! turn to segment configuration
                 else
                     ie = 1
                     cstat = 1
                     tau_start = time_s(index_s(is, flvr), flvr)
                     tau_end = time_e(index_e(ie, flvr), flvr)
                     tau_max = beta - tau_start + time_s(index_s(1, flvr), flvr) - zero
                 endif ! back if ( is < ckink ) block

             endif ! back if ( ckink == 1 ) block

         endif ! back if ( stts(flvr) == 2 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

!-------------------------------------------------------------------------
! stage 2: need to remove an anti-segment
!-------------------------------------------------------------------------
     else ! anti .eqv. .true.

! case 1: there are segments, segment configuration
!-------------------------------------------------------------------------
         if ( stts(flvr) == 1 ) then

! case 1A: there is only one segment
! turn to full configuration
             if ( ckink == 1 ) then
                 ie = 1
                 cstat = 3
                 tau_start = time_s(index_s(1, flvr), flvr)
                 tau_end = time_e(index_e(1, flvr), flvr)
                 tau_max = beta

! case 1B: there are more than one segments
             else
! remove a normal anti-segment, not the first anti-segment
! keep segment configuration
                 if ( is > 1 ) then
                     ie = is - 1
                     cstat = 1
                     tau_start = time_s(index_s(is, flvr), flvr)
                     tau_end = time_e(index_e(ie, flvr), flvr)
                     tau_max = tau_start - time_s(index_s(is-1, flvr), flvr)
! remove the first anti-segment, pay special attention to tau_max
! turn to anti-segment configuration
                 else
                     ie = ckink
                     cstat = 2
                     tau_start = time_s(index_s(is, flvr), flvr)
                     tau_end = time_e(index_e(ie, flvr), flvr)
                     tau_max = tau_start - zero + beta - time_s(index_s(ckink, flvr), flvr)
                 endif ! back if ( is > 1 ) block

             endif ! back if ( ckink == 1 ) block

         endif ! back if ( stts(flvr) == 1 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! case 2: there are segments, anti-segment configuration
!-------------------------------------------------------------------------
         if ( stts(flvr) == 2 ) then

! case 2A: there is only one anti-segment
! turn to full configuration
             if ( ckink == 1 ) then
                 ie = 1
                 cstat = 3
                 tau_start = time_s(index_s(1, flvr), flvr)
                 tau_end = time_e(index_e(1, flvr), flvr)
                 tau_max = beta

! case 2B: there are more than one segment or anti-segment
! keep anti-segment configuration
             else
                 ie = is
                 cstat = 2
                 tau_start = time_s(index_s(is, flvr), flvr)
                 tau_end = time_e(index_e(ie, flvr), flvr)
! remove a normal anti-segment, not the first anti-segment
                 if ( is > 1 ) then
                     tau_max = tau_start - time_s(index_s(is-1, flvr), flvr)
! remove the first anti-segment, pay special attention to tau_max
                 else
                     tau_max = tau_start - zero + beta - time_s(index_s(ckink, flvr), flvr)
                 endif ! back if ( is > 1 ) block

             endif ! back if ( ckink == 1 ) block

         endif ! back if ( stts(flvr) == 2 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

     endif ! back if ( anti .eqv. .false. ) block

     return
  end subroutine ctqmc_make_flavor2

!!>>> ctqmc_make_flavor3: determine \tau_s1 and \tau_s2 for lshift old
!!>>> segment or anti-segment
  subroutine ctqmc_make_flavor3(flvr, iso, isn, ring, tau_start1, tau_start2)
     use constants, only : dp, zero
     use spring, only : spring_sfmt_stream

     use control, only : beta
     use context, only : ckink, cstat
     use context, only : index_s, index_e, time_s, time_e
     use context, only : stts

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address to left  shift old segment or anti-segment
! iso and isn are for old and new indices, respectively
     integer, intent(out)  :: iso, isn

! whether the update operation winds around the circle
     logical, intent(out)  :: ring

! start point of the selected segment (the old one)
     real(dp), intent(out) :: tau_start1

! start point of the selected segment (the new one)
     real(dp), intent(out) :: tau_start2

! local variables
! dummy variables, end   points in imaginary time
     real(dp) :: tau_end1
     real(dp) :: tau_end2

! initialize ring
     ring = .false.

! initialize iso and isn
     iso = 1
     isn = 1

! randomly select start index address, which is used to access the segment
     iso = ceiling( spring_sfmt_stream() * ckink )

! initialize tau_start1 and tau_start2
     tau_start1 = zero
     tau_start2 = zero

! case 1: there are segments, segment configuration
!-------------------------------------------------------------------------
     if ( stts(flvr) == 1 ) then

! case 1A: there is only one segment
         if ( ckink == 1 ) then
             isn = 1
             tau_start1 = time_s(index_s(1, flvr), flvr)
             tau_start2 = time_e(index_e(1, flvr), flvr) - spring_sfmt_stream() * beta
! zero < tau_start2 < tau_end, keep segment configuration
             if ( tau_start2 > zero ) then
                 cstat = 1
                 ring = .false.
! tau_end < tau_start2 < beta, turn to anti-segment configuration
             else
                 cstat = 2
                 ring = .true.
                 tau_start2 = tau_start2 + beta
             endif ! back if ( tau_start2 > zero ) block

! case 1B: there are more than one segments
         else
! not the first segment, tau_end2 < tau_start1 (tau_start2) < tau_end1, keep segment configuration
             if ( iso > 1 ) then
                 isn = iso
                 cstat = 1
                 ring = .false.
                 tau_end1 = time_e(index_e(iso, flvr), flvr)
                 tau_end2 = time_e(index_e(iso-1, flvr), flvr)
                 tau_start1 = time_s(index_s(iso, flvr), flvr)
                 tau_start2 = tau_end1 - spring_sfmt_stream() * ( tau_end1 - tau_end2 )
! the first segment is chosen
             else
                 tau_end1 = time_e(index_e(1, flvr), flvr)
                 tau_end2 = time_e(index_e(ckink, flvr), flvr)
                 tau_start1 = time_s(index_s(1, flvr), flvr)
                 tau_start2 = tau_end1 - spring_sfmt_stream() * ( tau_end1 - zero + beta - tau_end2 )
! zero < tau_start1 (tau_start2) < tau_end1 < ... < tau_end2 < beta, keep segment configuration
                 if ( tau_start2 > zero ) then
                     isn = 1
                     cstat = 1
                     ring = .false.
! zero < tau_start1 < tau_end1 < ... < tau_end2 < tau_start2 < beta, turn to anti-segment configuration
                 else
                     isn = ckink
                     cstat = 2
                     ring = .true.
                     tau_start2 = tau_start2 + beta
                 endif ! back if ( tau_start2 > zero ) block
             endif ! back if ( iso > 1 ) block

         endif ! back if ( ckink == 1 ) block

     endif ! back if ( stts(flvr) == 1 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! case 2: there are segments, anti-segment configuration
!-------------------------------------------------------------------------
     if ( stts(flvr) == 2 ) then

! case 2A: there is only one anti-segment
         if ( ckink == 1 ) then
             isn = 1
             tau_start1 = time_s(index_s(1, flvr), flvr)
             tau_start2 = time_e(index_e(1, flvr), flvr) - spring_sfmt_stream() * beta
! zero < tau_start2 < tau_end < tau_start1 < beta, turn to segment configuration
             if ( tau_start2 > zero ) then
                 cstat = 1
                 ring = .true.
! zero < tau_end < tau_start1 (tau_start2) < beta, keep anti-segment configuration
             else
                 cstat = 2
                 ring = .false.
                 tau_start2 = tau_start2 + beta
             endif ! back if ( tau_start2 > zero ) block

! case 2B: there are more than one segment or anti-segment
         else
! not the last segment, tau_end1 < tau_start1 (tau_start2) < tau_end2, keep anti-segment configuration
             if ( iso < ckink ) then
                 isn = iso
                 cstat = 2
                 ring = .false.
                 tau_end1 = time_e(index_e(iso, flvr), flvr)
                 tau_end2 = time_e(index_e(iso+1, flvr), flvr)
                 tau_start1 = time_s(index_s(iso, flvr), flvr)
                 tau_start2 = tau_end2 - spring_sfmt_stream() * ( tau_end2 - tau_end1 )
! the last segment is chosen
             else
                 tau_end1 = time_e(index_e(ckink, flvr), flvr)
                 tau_end2 = time_e(index_e(1, flvr), flvr)
                 tau_start1 = time_s(index_s(ckink, flvr), flvr)
                 tau_start2 = tau_end2 - spring_sfmt_stream() * ( beta - tau_end1 + tau_end2 - zero )
! zero < tau_start2 < tau_end2 < ... < tau_end1 < tau_start1 < beta, turn to segment configuration
                 if ( tau_start2 > zero ) then
                     isn = 1
                     cstat = 1
                     ring = .true.
! zero < tau_end2 < ... < tau_end1 < tau_start1 (tau_start2) < beta, keep anti-segment configuration
                 else
                     isn = ckink
                     cstat = 2
                     ring = .false.
                     tau_start2 = tau_start2 + beta
                 endif ! back if ( tau_start2 > zero ) block
             endif ! back if ( iso < ckink ) block

         endif ! back if ( ckink == 1 ) block

     endif ! back if ( stts(flvr) == 2 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

     return
  end subroutine ctqmc_make_flavor3

!!>>> ctqmc_make_flavor4: determine \tau_e1 and \tau_e2 for rshift old
!!>>> segment or anti-segment
  subroutine ctqmc_make_flavor4(flvr, ieo, ien, ring, tau_end1, tau_end2)
     use constants, only : dp, zero
     use spring, only : spring_sfmt_stream

     use control, only : beta
     use context, only : ckink, cstat
     use context, only : index_s, index_e, time_s, time_e
     use context, only : stts

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address to right shift old segment or anti-segment
! ieo and ien are for old and new indices, respectively
     integer, intent(out)  :: ieo, ien

! whether the update operation winds around the circle
     logical, intent(out)  :: ring

! end   point of the selected segment (the old one)
     real(dp), intent(out) :: tau_end1

! end   point of the selected segment (the new one)
     real(dp), intent(out) :: tau_end2

! local variables
! dummy variables, start points in imaginary time
     real(dp) :: tau_start1
     real(dp) :: tau_start2

! initialize ring
     ring = .false.

! initialize ieo and ien
     ieo = 1
     ien = 1

! randomly select end   index address, which is used to access the segment
     ieo = ceiling( spring_sfmt_stream() * ckink )

! initialize tau_end1 and tau_end2
     tau_end1 = zero
     tau_end2 = zero

! case 1: there are segments, segment configuration
!-------------------------------------------------------------------------
     if ( stts(flvr) == 1 ) then

! case 1A: there is only one segment
         if ( ckink == 1 ) then
             ien = 1
             tau_end1 = time_e(index_e(1, flvr), flvr)
             tau_end2 = time_s(index_s(1, flvr), flvr) + spring_sfmt_stream() * beta
! tau_start < tau_end2 < beta, keep segment configuration
             if ( tau_end2 < beta ) then
                 cstat = 1
                 ring = .false.
! tau_end2 < tau_start < beta, turn to anti-segment configuration
             else
                 cstat = 2
                 ring = .true.
                 tau_end2 = tau_end2 - beta
             endif ! back if ( tau_end2 < beta ) block

! case 1B: there are more than one segments
         else
! not the last segment, tau_start1 < tau_end1 (tau_end2) < tau_start2, keep segment configuration
             if ( ieo < ckink ) then
                 ien = ieo
                 cstat = 1
                 ring = .false.
                 tau_start1 = time_s(index_s(ieo, flvr), flvr)
                 tau_start2 = time_s(index_s(ieo+1, flvr), flvr)
                 tau_end1 = time_e(index_e(ieo, flvr), flvr)
                 tau_end2 = tau_start1 + spring_sfmt_stream() * ( tau_start2 - tau_start1 )
! the last segment is chosen
             else
                 tau_start1 = time_s(index_s(ckink, flvr), flvr)
                 tau_start2 = time_s(index_s(1, flvr), flvr)
                 tau_end1 = time_e(index_e(ckink, flvr), flvr)
                 tau_end2 = tau_start1 + spring_sfmt_stream() * ( beta - tau_start1 + tau_start2 - zero )
! zero < tau_start2 < ... < tau_start1 < tau_end1 (tau_end2) < beta, keep segment configuration
                 if ( tau_end2 < beta ) then
                     ien = ckink
                     cstat = 1
                     ring = .false.
! zero < tau_end2 < tau_start2 < ... < tau_start1 < tau_end1 < beta, turn to anti-segment configuration
                 else
                     ien = 1
                     cstat = 2
                     ring = .true.
                     tau_end2 = tau_end2 - beta
                 endif ! back if ( tau_end2 < beta ) block
             endif ! back if ( ieo < ckink ) block

         endif ! back if ( ckink == 1 ) block

     endif ! back if ( stts(flvr) == 1 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

! case 2: there are segments, anti-segment configuration
!-------------------------------------------------------------------------
     if ( stts(flvr) == 2 ) then

! case 2A: there is only one anti-segment
         if ( ckink == 1 ) then
             ien = 1
             tau_end1 = time_e(index_e(1, flvr), flvr)
             tau_end2 = time_s(index_s(1, flvr), flvr) + spring_sfmt_stream() * beta
! zero < tau_end1 < tau_start < tau_end2 < beta, turn to segment configuration
             if ( tau_end2 < beta ) then
                 cstat = 1
                 ring = .true.
! zero < tau_end1 (tau_end2) < tau_start < beta, keep anti-segment configuration
             else
                 cstat = 2
                 ring = .false.
                 tau_end2 = tau_end2 - beta
             endif ! back if ( tau_end2 < beta ) block

! case 2B: there are more than one segment or anti-segment
         else
! not the first segment, tau_start1 < tau_end1 (tau_end2) < tau_start2, keep anti-segment configuration
             if ( ieo > 1 ) then
                 ien = ieo
                 cstat = 2
                 ring = .false.
                 tau_start1 = time_s(index_s(ieo-1, flvr), flvr)
                 tau_start2 = time_s(index_s(ieo, flvr), flvr)
                 tau_end1 = time_e(index_e(ieo, flvr), flvr)
                 tau_end2 = tau_start1 + spring_sfmt_stream() * ( tau_start2 - tau_start1 )
! the first segment is chosen
             else
                 tau_start1 = time_s(index_s(ckink, flvr), flvr)
                 tau_start2 = time_s(index_s(1, flvr), flvr)
                 tau_end1 = time_e(index_e(1, flvr), flvr)
                 tau_end2 = tau_start1 + spring_sfmt_stream() * ( beta - tau_start1 + tau_start2 - zero )
! zero < tau_end1 < tau_start2 < ... < tau_start1 < tau_end2 < beta, turn to segment configuration
                 if ( tau_end2 < beta ) then
                     ien = ckink
                     cstat = 1
                     ring = .true.
! zero < tau_end1 (tau_end2) < tau_start2 < ... < tau_start1 < beta, keep anti-segment configuration
                 else
                     ien = 1
                     cstat = 2
                     ring = .false.
                     tau_end2 = tau_end2 - beta
                 endif ! back if ( tau_end2 < beta ) block
             endif ! back if ( ieo > 1 ) block

         endif ! back if ( ckink == 1 ) block

     endif ! back if ( stts(flvr) == 2 ) block
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

     return
  end subroutine ctqmc_make_flavor4

!!========================================================================
!!>>> service layer: calculate occupation status for current flavor    <<<
!!========================================================================

!!>>> ctqmc_spin_counter: evaluate the occupation status for current
!!>>> flavor channel and time, which can be used to calculate spin-spin
!!>>> correlation function
  subroutine ctqmc_spin_counter(flvr, curr, occu)
     use constants, only : dp, zero, one

     use context, only : index_s, index_e, time_s, time_e
     use context, only : rank, stts

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! current time at imaginary axis
     real(dp), intent(in)  :: curr

! occupation status, if occu = 1.0, occupied, if occu = 0.0, unoccupied
     real(dp), intent(out) :: occu

! local variables
! loop index over segments
     integer  :: i

! imaginary time for start and end points
     real(dp) :: ts
     real(dp) :: te

     FLAVOR_SWITCHER: select case ( stts(flvr) )

! case 1: there is no segments, null configuration
         case (0)
             occu = zero

! case 2: there are segments, segment configuration
         case (1)
             occu = zero

! check whether curr is in an existing segment
             do i=1,rank(flvr)
                 ts = time_s(index_s(i, flvr), flvr) ! get \tau_s at start point
                 te = time_e(index_e(i, flvr), flvr) ! get \tau_e at end   point

                 if ( curr > ts .and. curr < te ) then
                     occu = one
                     RETURN ! return to the parent subroutines immediately
                 endif ! back if ( curr > ts .and. curr < te ) block
             enddo ! over i={1,rank(flvr)} loop

! case 3: there are segments, anti-segment configuration
         case (2)
             occu = one

! check whether curr is not in an existing segment
             do i=1,rank(flvr)
                 ts = time_s(index_s(i, flvr), flvr) ! get \tau_s at start point
                 te = time_e(index_e(i, flvr), flvr) ! get \tau_e at end   point

                 if ( curr < ts .and. curr > te ) then
                     occu = zero
                     RETURN ! return to the parent subroutines immediately
                 endif ! back if ( curr < ts .and. curr > te ) block
             enddo ! over i={1,rank(flvr)} loop

! case 4: there is no segments, full configuration
         case (3)
             occu = one

     end select FLAVOR_SWITCHER

     return
  end subroutine ctqmc_spin_counter

!!========================================================================
!!>>> service layer: calculate overlap between segments                <<<
!!========================================================================

!!>>> ctqmc_make_overlap: calculate the delta segment overlaps between
!!>>> current flavor channel and other flavor channels
  subroutine ctqmc_make_overlap(flvr, tau_start, tau_end, ovlp)
     use constants, only : dp, zero

     use control, only : norbs
     use control, only : beta
     use context, only : index_s, index_e, time_s, time_e
     use context, only : rank, stts

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! imaginary time \tau_s for start point
     real(dp), intent(in)  :: tau_start

! imaginary time \tau_e for end   point
     real(dp), intent(in)  :: tau_end

! segment overlap between different flavors
     real(dp), intent(out) :: ovlp(norbs)

! local variables
! loop index over orbitals
     integer  :: i

! loop index over segments
     integer  :: j

! imaginary time for start and end points
     real(dp) :: ts
     real(dp) :: te

! dummy variables
     real(dp) :: raux

! initialize ovlp
     ovlp = zero

! loop over flavors
     do i=1,norbs

! do not calculate overlap for himself
         if ( flvr == i ) CYCLE

! case 1: null occupation
         if      ( stts(i) == 0 ) then
             ovlp(i) = zero

! case 2: partial occupation, segment scheme
         else if ( stts(i) == 1 ) then
! loop through all the segments
             do j=1,rank(i)
                 ts = time_s(index_s(j, i), i)
                 te = time_e(index_e(j, i), i)
                 if ( ts > tau_end ) EXIT
                 call ctqmc_make_compare( tau_start, tau_end, ts, te, raux )
                 ovlp(i) = ovlp(i) + raux
             enddo ! over j={1,rank(i)} loop

! case 3: partial occupation, anti-segment scheme
         else if ( stts(i) == 2 ) then
! deal with the first segment (header)
             ts = zero
             te = time_e(index_e(1, i), i)
             call ctqmc_make_compare( tau_start, tau_end, ts, te, raux )
             ovlp(i) = ovlp(i) + raux

! deal with the last segment (tailer)
             ts = time_s(index_s(rank(i), i), i)
             te = beta
             call ctqmc_make_compare( tau_start, tau_end, ts, te, raux )
             ovlp(i) = ovlp(i) + raux

! loop through all the other segments
             do j=1,rank(i)-1
                 ts = time_s(index_s(j  , i), i)
                 te = time_e(index_e(j+1, i), i)
                 if ( ts > tau_end ) EXIT
                 call ctqmc_make_compare( tau_start, tau_end, ts, te, raux )
                 ovlp(i) = ovlp(i) + raux
             enddo ! over j={1,rank(i)-1} loop

! case 4: full occupation
         else if ( stts(i) == 3 ) then
             ovlp(i) = tau_end - tau_start

         endif ! back if ( stts(i) == 0 ) block

     enddo ! over i={1,norbs} loop

     return
  end subroutine ctqmc_make_overlap

!!>>> ctqmc_make_compare: compare two segments, and calculate their overlap
  subroutine ctqmc_make_compare(ts0, te0, ts1, te1, cover)
     use constants, only : dp, zero

     implicit none

! external arguments
! segment 1, ts0 < te0 should be certified beforehand
     real(dp), intent(in)  :: ts0, te0

! segment 2, ts1 < te1 should be certified beforehand
     real(dp), intent(in)  :: ts1, te1

! the overlap length for segment1 and segment2
     real(dp), intent(out) :: cover

! local variables
! left boundary
     real(dp) :: lb

! right boundary
     real(dp) :: rb

! init cover
     cover = zero

! determine left boundary, choose a larger value
     if ( ts0 < ts1 ) then
         lb = ts1
     else
         lb = ts0
     endif ! back if ( ts0 < ts1 ) block

! determine right boundary, choose a smaller value
     if ( te0 < te1 ) then
         rb = te0
     else
         rb = te1
     endif ! back if ( te0 < te1 ) block

! compare left boundary and right boundary
     if ( lb < rb ) then
         cover = rb - lb
     else
         cover = zero
     endif ! back if ( lb < rb ) block

     return
  end subroutine ctqmc_make_compare

!!========================================================================
!!>>> service layer: utility subroutines to test segment algorithm     <<<
!!========================================================================

!!>>> ctqmc_make_segment: generate segments or anti-segments for the
!!>>> specified flavor channel randomly, only used to debug the code
  subroutine ctqmc_make_segment(flvr, kink, anti)
     use constants, only : dp
     use spring, only : spring_sfmt_stream

     use control, only : beta
     use context, only : ckink
     use context, only : rank, stts

     implicit none

! external arguments
! current flavor channel
     integer, intent(in) :: flvr

! number of segments (operator pair)
     integer, intent(in) :: kink

! whether it is an anti-segment configuration
     logical, intent(in) :: anti

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

! build segments or anti-segments
     if ( anti .eqv. .false. ) then
         do i=1,kink
             call cat_insert_segment( flvr, i, i, time(2*i-1), time(2*i) )
             ckink = i
         enddo ! over i={1,kink} loop
         stts(flvr) = 1
     else
         do i=1,kink
             call cat_insert_segment( flvr, i, i, time(2*i), time(2*i-1) )
             ckink = i
         enddo ! over i={1,kink} loop
         stts(flvr) = 2
     endif ! back if ( anti .eqv. .false. ) block

! update the rank
     rank(flvr) = ckink

     return
  end subroutine ctqmc_make_segment

!!>>> ctqmc_make_display: display segment information on the screen, only
!!>>> used to debug the code
  subroutine ctqmc_make_display(show_type)
     use constants, only : mystd

     use control, only : norbs
     use context, only : index_s, index_e, time_s, time_e
     use context, only : rank, stts

     implicit none

! external arguments
! output style
     integer, intent(in) :: show_type

! local variables
! loop index over orbitals
     integer :: i

! loop index over segments or anti-segments
     integer :: j

! apply normal display mode
     if ( show_type == 1 ) then
         do i=1,norbs
             write(mystd,'(4X,a,i4)') '# flavor:', i
             write(mystd,'(4X,a,i4)') '# status:', stts(i)

             write(mystd,'(4X,a,i4)') '# time_s data:', rank(i)
             do j=1,rank(i)
                 write(mystd,'(4X,2i4,f12.6)') i, j, time_s(index_s(j, i), i)
             enddo ! over j={1,rank(i)} loop

             write(mystd,'(4X,a,i4)') '# time_e data:', rank(i)
             do j=1,rank(i)
                 write(mystd,'(4X,2i4,f12.6)') i, j, time_e(index_e(j, i), i)
             enddo ! over j={1,rank(i)} loop

             write(mystd,*) ! write empty lines
             write(mystd,*)
         enddo ! over i={1,norbs} loop

! apply compat display mode
     else
         do i=1,norbs
             write(mystd,'(4X,a,i4)') '# flavor:', i
             write(mystd,'(4X,a,i4)') '# status:', stts(i)

             write(mystd,'(4X,a,i4)') '# time_s and time_e data:', rank(i)
             if      ( stts(i) == 0 ) then
                 write(mystd,'(4X,a)') '--->>> null occupation'
             else if ( stts(i) == 1 ) then
                 write(mystd,'(4X,a)') '--->>>      tau_s       tau_e'
                 do j=1,rank(i)
                     write(mystd,'(4X,2i4,2f12.6)') i, j, time_s(index_s(j, i), i), time_e(index_e(j, i), i)
                 enddo ! over j={1,rank(i)} loop
             else if ( stts(i) == 2 ) then
                 write(mystd,'(4X,a)') '--->>>      tau_e       tau_s'
                 do j=1,rank(i)
                     write(mystd,'(4X,2i4,2f12.6)') i, j, time_e(index_e(j, i), i), time_s(index_s(j, i), i)
                 enddo ! over j={1,rank(i)} loop
             else if ( stts(i) == 3 ) then
                 write(mystd,'(4X,a)') '--->>> full occupation'
             endif ! back if      ( stts(i) == 0 ) block

             write(mystd,*) ! write empty lines
             write(mystd,*)
         enddo ! over i={1,norbs} loop

     endif ! back if ( show_type == 1 ) block

     return
  end subroutine ctqmc_make_display
