!!!-----------------------------------------------------------------------
!!! project : manjushaka
!!! program : ctqmc_insert_kink
!!!           ctqmc_remove_kink
!!!           ctqmc_lshift_kink
!!!           ctqmc_rshift_kink
!!!           ctqmc_reflip_kink
!!!           ctqmc_reload_kink <<<---
!!!           cat_insert_matrix
!!!           cat_remove_matrix
!!!           cat_lshift_matrix
!!!           cat_rshift_matrix
!!!           cat_reflip_matrix
!!!           cat_reload_matrix <<<---
!!!           cat_insert_detrat
!!!           cat_remove_detrat
!!!           cat_lshift_detrat
!!!           cat_rshift_detrat
!!!           cat_reflip_detrat <<<---
!!! source  : ctqmc_update.f90
!!! type    : subroutines
!!! author  : li huang (email:lihuang.dmft@gmail.com)
!!!           yilin wang (email:qhwyl2006@126.com)
!!! history : 09/16/2009 by li huang (created)
!!!           08/17/2015 by li huang (last modified)
!!! purpose : provide basic infrastructure (elementary updating subroutines)
!!!           for hybridization expansion version continuous time quantum
!!!           Monte Carlo (CTQMC) quantum impurity solver.
!!!           the following subroutines mainly deal with the \mathscr{M}
!!!           matrix: mmat, and \mathscr{G} matrix: gmat.
!!! status  : unstable
!!! comment :
!!!-----------------------------------------------------------------------

!!========================================================================
!!>>> driver layer: updating perturbation expansion series             <<<
!!========================================================================

!!>>> ctqmc_insert_kink: insert new create and destroy operators in the
!!>>> perturbation expansion series
  subroutine ctqmc_insert_kink()
     use constants, only : dp, zero, one
     use spring, only : spring_sfmt_stream

     use control, only : norbs
     use control, only : mkink
     use control, only : beta
     use context, only : ckink, csign, cnegs
     use context, only : insert_tcount, insert_accept, insert_reject
     use context, only : rank

     implicit none

! local variables
! whether the new create and destroy operators can be inserted diagrammatically
     logical  :: ladd

! whether the update operation is accepted
     logical  :: pass

! current flavor channel for both band and spin
     integer  :: flvr

! index address to insert new create and destroy operators
! is and ie are for create and destroy operators, respectively
! cis and cie are for the colour part, and fis and fie are for the flavor part
     integer  :: cis, cie
     integer  :: fis, fie

! transition probability for insert new create and destroy operators
     real(dp) :: p

! random number
     real(dp) :: r

! \tau_s, imaginary time point of the create operator
     real(dp) :: tau_start

! \tau_e, imaginary time point of the destroy operator
     real(dp) :: tau_end

! ratio between old and new configurations, the local trace part
     real(dp) :: trace_ratio

! ratio between old and new configurations, the determinant part
     real(dp) :: deter_ratio

! initialize logical variables
     ladd = .false.
     pass = .false.

! select the flavor channel randomly among 1 ~ norbs
     flvr = ceiling( spring_sfmt_stream() * norbs )

! get the perturbation expansion order ( number of existing create or
! destroy operators ) for current flavor channel
     ckink = rank(flvr)
     if ( ckink == mkink ) then
!<         call s_print_exception('ctqmc_insert_kink','can not insert any operators')
         insert_tcount = insert_tcount + one
         insert_reject = insert_reject + one
         if ( csign < 0 )  cnegs = cnegs + 1
         RETURN
     endif ! back if ( ckink == mkink ) block

! randomly generate tau_start and tau_end at selected flvr channel, and
! then determine index address cis and cie for them
     call try_insert_colour(flvr, cis, cie, tau_start, tau_end)

! fast look up the flavor part of perturbation expansion series, determine
! corresponding fis and fie, and determine whether the operators trace is
! not equal to zero
     call try_insert_flavor(flvr, fis, fie, tau_start, tau_end, ladd)

! calculate the transition ratio between old and new configurations,
! for the local trace part
     if ( ladd .eqv. .true. ) then
         call cat_insert_ztrace(flvr, fis, fie, tau_start, tau_end, trace_ratio)
     else
         trace_ratio = zero
     endif ! back if ( ladd .eqv. .true. ) block

! calculate the transition ratio between old and new configurations,
! for the determinant part
     if ( ladd .eqv. .true. ) then
         call cat_insert_detrat(flvr, tau_start, tau_end, deter_ratio)
     else
         deter_ratio = zero
     endif ! back if ( ladd .eqv. .true. ) block

! we will determine the pass by lazy trace evalution
! if ladd is false, we set the pass as false immediately
     r = spring_sfmt_stream()
     trace_ratio = deter_ratio * ( beta / real( ckink + 1 ) ) ** 2
     if ( ladd .eqv. .true. ) then
         call ctqmc_lazy_ztrace( 1, 2*sum(rank) + 2, trace_ratio, tau_start, tau_end, r, p, pass )
     else
         pass = .false.
     endif ! back if ( ladd .eqv. .true. ) block

! if the update action is accepted
     if ( pass .eqv. .true. ) then

! update the mmat matrix and gmat matrix, respectively,
! cat_insert_colour() subroutine is invoked internally to update the colour
! part of perturbation expansion series
         call cat_insert_matrix(flvr, cis, cie, tau_start, tau_end, deter_ratio)

! update the flavor part of perturbation expansion series
         call cat_insert_flavor(flvr, fis, fie, tau_start, tau_end)

! update the operators trace
         call ctqmc_make_evolve()

! update ckink for current flavor channel
         ckink = ckink + 1

! update rank for current flavor channel
         rank(flvr) = rank(flvr) + 1

! determine the sign, TO BE CHECKED
         csign = csign * int ( sign(one, p) )

     endif ! back if ( pass .eqv. .true. ) block

! record negative sign
     if ( csign < 0 ) then
         cnegs = cnegs + 1
!<         call s_print_exception('ctqmc_insert_kink','csign is negative')
     endif ! back if ( csign < 0 ) block

! update the insert statistics
     insert_tcount = insert_tcount + one
     if ( pass .eqv. .true. ) then
         insert_accept = insert_accept + one
     else
         insert_reject = insert_reject + one
     endif ! back if ( pass .eqv. .true. ) block

     return
  end subroutine ctqmc_insert_kink

!!>>> ctqmc_remove_kink: remove old create and destroy operators in the
!!>>> perturbation expansion series
  subroutine ctqmc_remove_kink()
     use constants, only : dp, zero, one
     use spring, only : spring_sfmt_stream

     use control, only : norbs
     use control, only : beta
     use context, only : ckink, csign, cnegs
     use context, only : remove_tcount, remove_accept, remove_reject
     use context, only : rank

     implicit none

! local variables
! whether the old create and destroy operators can be removed diagrammatically
     logical  :: lrmv

! whether the update operation is accepted
     logical  :: pass

! current flavor channel for both band and spin
     integer  :: flvr

! index address to remove old create and destroy operators
! is and ie are for create and destroy operators, respectively
! cis and cie are for the colour part, and fis and fie are for the flavor part
     integer  :: cis, cie
     integer  :: fis, fie

! transition probability for remove old create and destroy operators
     real(dp) :: p

! random number
     real(dp) :: r

! \tau_s, imaginary time point of the create operator
     real(dp) :: tau_start

! \tau_e, imaginary time point of the destroy operator
     real(dp) :: tau_end

! ratio between old and new configurations, the local trace part
     real(dp) :: trace_ratio

! ratio between old and new configurations, the determinant part
     real(dp) :: deter_ratio

! initialize logical variables
     lrmv = .false.
     pass = .false.

! select the flavor channel randomly among 1 ~ norbs
     flvr = ceiling( spring_sfmt_stream() * norbs )

! get the perturbation expansion order ( number of existing create or
! destroy operators ) for current flavor channel
     ckink = rank(flvr)
     if ( ckink == 0 ) then
!<         call s_print_exception('ctqmc_remove_kink','can not remove any operators')
         remove_tcount = remove_tcount + one
         remove_reject = remove_reject + one
         if ( csign < 0 )  cnegs = cnegs + 1
         RETURN
     endif ! back if ( ckink == 0 ) block

! randomly generate cis and cie at selected flvr channel, and then determine
! tau_start and tau_end for them
     call try_remove_colour(flvr, cis, cie, tau_start, tau_end)

! fast look up the flavor part of perturbation expansion series, determine
! corresponding fis and fie, and determine whether the operators trace is
! not equal to zero
     call try_remove_flavor(fis, fie, tau_start, tau_end, lrmv)

! calculate the transition ratio between old and new configurations,
! for the local trace part
     if ( lrmv .eqv. .true. ) then
         call cat_remove_ztrace(fis, fie, tau_start, tau_end, trace_ratio)
     else
         trace_ratio = zero
     endif ! back if ( lrmv .eqv. .true. ) block

! calculate the transition ratio between old and new configurations,
! for the determinant part
     if ( lrmv .eqv. .true. ) then
         call cat_remove_detrat(flvr, cis, cie, deter_ratio)
     else
         deter_ratio = zero
     endif ! back if ( lrmv .eqv. .true. ) block

! we will determine the pass by lazy trace evalution
! if lrmv is false, we set the pass as false immediately
     r = spring_sfmt_stream()
     trace_ratio = deter_ratio * ( real( ckink ) / beta ) ** 2
     if ( lrmv .eqv. .true. ) then
         call ctqmc_lazy_ztrace( 1, 2*sum(rank) - 2, trace_ratio, tau_start, tau_end, r, p, pass )
     else
         pass = .false.
     endif ! back if ( lrmv .eqv. .true. ) block

! if update action is accepted
     if ( pass .eqv. .true. ) then

! update the flavor part of perturbation expansion series
         call cat_remove_flavor(fis, fie, tau_start, tau_end)

! update the mmat matrix and gmat matrix, respectively,
! cat_remove_colour() subroutine is invoked internally to update the colour
! part of perturbation expansion series
         call cat_remove_matrix(flvr, cis, cie)

! update the operators trace
         call ctqmc_make_evolve()

! decrease ckink for current flavor channel
         ckink = ckink - 1

! update rank for current flavor channel
         rank(flvr) = rank(flvr) - 1

! determine the sign, TO BE CHECKED
         csign = csign * int ( sign(one, p) )

     endif ! back if ( pass .eqv. .true. ) block

! record negative sign
     if ( csign < 0 ) then
         cnegs = cnegs + 1
!<         call s_print_exception('ctqmc_remove_kink','csign is negative')
     endif ! back if ( csign < 0 ) block

! update the remove statistics
     remove_tcount = remove_tcount + one
     if ( pass .eqv. .true. ) then
         remove_accept = remove_accept + one
     else
         remove_reject = remove_reject + one
     endif ! back if ( pass .eqv. .true. ) block

     return
  end subroutine ctqmc_remove_kink

!!>>> ctqmc_lshift_kink: shift old create operators in the perturbation
!!>>> expansion series
  subroutine ctqmc_lshift_kink()
     use constants, only : dp, zero, one
     use spring, only : spring_sfmt_stream

     use control, only : norbs
     use context, only : ckink, csign, cnegs
     use context, only : lshift_tcount, lshift_accept, lshift_reject
     use context, only : rank

     implicit none

! local variables
! whether the old create operators can be shifted diagrammatically
     logical  :: lshf

! whether the update operation is accepted
     logical  :: pass

! current flavor channel for both band and spin
     integer  :: flvr

! index address to shift old create operators
! iso and isn are for old and new indices, respectively
! ciso and cisn are for the colour part, and fiso and fisn are for the flavor part
     integer  :: ciso, cisn
     integer  :: fiso, fisn

! transition probability for shift old create operators
     real(dp) :: p

! random number
     real(dp) :: r

! \tau_s, imaginary time point of the old create operator
     real(dp) :: tau_start1

! \tau_s, imaginary time point of the new create operator
     real(dp) :: tau_start2

! ratio between old and new configurations, the local trace part
     real(dp) :: trace_ratio

! ratio between old and new configurations, the determinant part
     real(dp) :: deter_ratio

! initialize logical variables
     lshf = .false.
     pass = .false.

! select the flavor channel randomly among 1 ~ norbs
     flvr = ceiling( spring_sfmt_stream() * norbs )

! get the perturbation expansion order ( number of existing create or
! destroy operators ) for current flavor channel
     ckink = rank(flvr)
     if ( ckink == 0 ) then
!<         call s_print_exception('ctqmc_lshift_kink','can not lshift any operators')
         lshift_tcount = lshift_tcount + one
         lshift_reject = lshift_reject + one
         if ( csign < 0 )  cnegs = cnegs + 1
         RETURN
     endif ! back if ( ckink == 0 ) block

! at first, we select ciso randomly, and then obtain tau_start1. according
! to the existing operators, we determine tau_start2 and related index cisn
     call try_lshift_colour(flvr, ciso, cisn, tau_start1, tau_start2)

! fast look up the flavor part of perturbation expansion series, determine
! corresponding fiso and fisn, and determine whether the operators trace is
! not equal to zero
     call try_lshift_flavor(flvr, fiso, fisn, tau_start1, tau_start2, lshf)

! calculate the transition ratio between old and new configurations,
! for the local trace part
     if ( lshf .eqv. .true. ) then
         call cat_lshift_ztrace(flvr, fiso, fisn, tau_start1, tau_start2, trace_ratio)
     else
         trace_ratio = zero
     endif ! back if ( lshf .eqv. .true. ) block

! calculate the transition ratio between old and new configurations,
! for the determinant part
     if ( lshf .eqv. .true. ) then
         call cat_lshift_detrat(flvr, ciso, tau_start1, tau_start2, deter_ratio)
     else
         deter_ratio = zero
     endif ! back if ( lshf .eqv. .true. ) block

! we will determine the pass by lazy trace evalution
! if lshf is false, we set the pass as false immediately
     r = spring_sfmt_stream()
     trace_ratio = deter_ratio * one
     if ( lshf .eqv. .true. ) then
         call ctqmc_lazy_ztrace( 1, 2*sum(rank), trace_ratio, tau_start1, tau_start2, r, p, pass )
     else
         pass = .false.
     endif ! back if ( lshf .eqv. .true. ) block

! if update action is accepted
     if ( pass .eqv. .true. ) then

! update the flavor part of perturbation expansion series
         call cat_lshift_flavor(flvr, fiso, fisn, tau_start2)

! update the mmat matrix and gmat matrix, respectively,
! cat_lshift_colour() subroutine is invoked internally to update the colour
! part of perturbation expansion series
         call cat_lshift_matrix(flvr, ciso, cisn, tau_start1, tau_start2, deter_ratio)

! update the operators trace
         call ctqmc_make_evolve()

! determine the sign, TO BE CHECKED
         csign = csign * int ( sign(one, p) )

     endif ! back if ( pass .eqv. .true. ) block

! record negative sign
     if ( csign < 0 ) then
         cnegs = cnegs + 1
!<         call s_print_exception('ctqmc_lshift_kink','csign is negative')
     endif ! back if ( csign < 0 ) block

! update the lshift statistics
     lshift_tcount = lshift_tcount + one
     if ( pass .eqv. .true. ) then
         lshift_accept = lshift_accept + one
     else
         lshift_reject = lshift_reject + one
     endif ! back if ( pass .eqv. .true. ) block

     return
  end subroutine ctqmc_lshift_kink

!!>>> ctqmc_rshift_kink: shift old destroy operators in the perturbation
!!>>> expansion series
  subroutine ctqmc_rshift_kink()
     use constants, only : dp, zero, one
     use spring, only : spring_sfmt_stream

     use control, only : norbs
     use context, only : ckink, csign, cnegs
     use context, only : rshift_tcount, rshift_accept, rshift_reject
     use context, only : rank

     implicit none

! local variables
! whether the old destroy operators can be shifted diagrammatically
     logical  :: rshf

! whether the update operation is accepted
     logical  :: pass

! current flavor channel for both band and spin
     integer  :: flvr

! index address to shift old destroy operators
! ieo and ien are for old and new indices, respectively
! cieo and cien are for the colour part, and fieo and fien are for the flavor part
     integer  :: cieo, cien
     integer  :: fieo, fien

! transition probability for shift old destroy operators
     real(dp) :: p

! random number
     real(dp) :: r

! \tau_e, imaginary time point of the old destroy operator
     real(dp) :: tau_end1

! \tau_e, imaginary time point of the new destroy operator
     real(dp) :: tau_end2

! ratio between old and new configurations, the local trace part
     real(dp) :: trace_ratio

! ratio between old and new configurations, the determinant part
     real(dp) :: deter_ratio

! initialize logical variables
     rshf = .false.
     pass = .false.

! select the flavor channel randomly among 1 ~ norbs
     flvr = ceiling( spring_sfmt_stream() * norbs )

! get the perturbation expansion order ( number of existing create or
! destroy operators ) for current flavor channel
     ckink = rank(flvr)
     if ( ckink == 0 ) then
!<         call s_print_exception('ctqmc_rshift_kink','can not rshift any operators')
         rshift_tcount = rshift_tcount + one
         rshift_reject = rshift_reject + one
         if ( csign < 0 )  cnegs = cnegs + 1
         RETURN
     endif ! back if ( ckink == 0 ) block

! at first, we select cieo randomly, and then obtain tau_end1. according
! to the existing operators, we determine tau_end2 and related index cien
     call try_rshift_colour(flvr, cieo, cien, tau_end1, tau_end2)

! fast look up the flavor part of perturbation expansion series, determine
! corresponding fieo and fien, and determine whether the operators trace is
! not equal to zero
     call try_rshift_flavor(flvr, fieo, fien, tau_end1, tau_end2, rshf)

! calculate the transition ratio between old and new configurations,
! for the local trace part
     if ( rshf .eqv. .true. ) then
         call cat_rshift_ztrace(flvr, fieo, fien, tau_end1, tau_end2, trace_ratio)
     else
         trace_ratio = zero
     endif ! back if ( rshf .eqv. .true. ) block

! calculate the transition ratio between old and new configurations,
! for the determinant part
     if ( rshf .eqv. .true. ) then
         call cat_rshift_detrat(flvr, cieo, tau_end1, tau_end2, deter_ratio)
     else
         deter_ratio = zero
     endif ! back if ( rshf .eqv. .true. ) block

! we will determine the pass by lazy trace evalution
! if rshf is false, we set the pass as false immediately
     r = spring_sfmt_stream()
     trace_ratio = deter_ratio * one
     if ( rshf .eqv. .true. ) then
         call ctqmc_lazy_ztrace( 1, 2*sum(rank), trace_ratio, tau_end1, tau_end2, r, p, pass )
     else
         rshf = .false.
     endif ! back if ( rshf .eqv. .true. ) block

! if update action is accepted
     if ( pass .eqv. .true. ) then

! update the flavor part of perturbation expansion series
         call cat_rshift_flavor(flvr, fieo, fien, tau_end2)

! update the mmat matrix and gmat matrix, respectively,
! cat_rshift_colour() subroutine is invoked internally to update the colour
! part of perturbation expansion series
         call cat_rshift_matrix(flvr, cieo, cien, tau_end1, tau_end2, deter_ratio)

! update the operators trace
         call ctqmc_make_evolve()

! determine the sign, TO BE CHECKED
         csign = csign * int ( sign(one, p) )

     endif ! back if ( pass .eqv. .true. ) block

! record negative sign
     if ( csign < 0 ) then
         cnegs = cnegs + 1
!<         call s_print_exception('ctqmc_rshift_kink','csign is negative')
     endif ! back if ( csign < 0 ) block

! update the rshift statistics
     rshift_tcount = rshift_tcount + one
     if ( pass .eqv. .true. ) then
         rshift_accept = rshift_accept + one
     else
         rshift_reject = rshift_reject + one
     endif ! back if ( pass .eqv. .true. ) block

     return
  end subroutine ctqmc_rshift_kink

!!>>> ctqmc_reflip_kink: perform a global update, exchange the states
!!>>> between spin up and spin down, it maybe useful for magnetic systems
  subroutine ctqmc_reflip_kink(cflip)
     use constants, only : dp, zero, one
     use spring, only : spring_sfmt_stream
     use stack, only : istack_getrest

     use control, only : nband, norbs
     use context, only : reflip_tcount, reflip_accept, reflip_reject
     use context, only : empty_v, index_t, index_v, flvr_v
     use context, only : rank, symm

     implicit none

! external arguments
! control flag
! if cflip = 1, flip inter-orbital spins randomly;
! if cflip = 2, flip intra-orbital spins one by one;
! if cflip = 3, flip intra-orbital spins globally
     integer, intent(in) :: cflip

! local variables
! whether the update operation is accepted
     logical  :: pass

! loop index
     integer  :: i

! selected flavor pairs
     integer  :: fup, fdn

! loop index for flavor channel
     integer  :: flvr

! maximum rank order
     integer  :: kmax

! total number of operators
     integer  :: nsize

! transition probability for global spin flip
     real(dp) :: p

! random number
     real(dp) :: r

! global flip determinant ratio
     real(dp) :: ratup
     real(dp) :: ratdn

! initialize logical variables
     pass = .false.

! initialize transition probability
     p = one

! get total number of operators
     nsize = istack_getrest( empty_v )

! not need to perform global flip if there are no operators at all
     if ( nsize == 0 ) then
!<         call s_print_exception('ctqmc_reflip_kink','can not reflip any operators')
         reflip_tcount = reflip_tcount + one
         reflip_reject = reflip_reject + one
         RETURN
     endif ! back if ( nsize == 0 ) block

     if ( cflip == 1 ) then
! determine fup and fdn, and fup /= fdn
         fup = ceiling( spring_sfmt_stream() * norbs )
         do while ( .true. )
             fdn = ceiling( spring_sfmt_stream() * norbs )
             if ( fup /= fdn .and. symm(fup) == symm(fdn) ) EXIT
         enddo ! over do while loop

! calculate the transition ratio between old and new configurations,
! for the determinant part, spin up case
         call cat_reflip_detrat(fup, fdn, ratup)

! calculate the transition ratio between old and new configurations,
! for the determinant part, spin dn case
         call cat_reflip_detrat(fdn, fup, ratdn)

! calculate the transition probability for global spin flip
         p = ratup * ratdn

! make a trial swap for flvr_v
         do i=1,nsize
             if ( flvr_v ( index_v(i) ) == fup ) then
                 flvr_v ( index_v(i) ) = fdn; CYCLE
             endif ! back if ( flvr_v ( index_v(i) ) == fup ) block
             if ( flvr_v ( index_v(i) ) == fdn ) then
                 flvr_v ( index_v(i) ) = fup; CYCLE
             endif ! back if ( flvr_v ( index_v(i) ) == fdn ) block
         enddo ! over i={1,nsize} loop

! make a copy of index_v, index_t is need by ctqmc_make_ztrace()
         do i=1,nsize
             index_t(i) = index_v(i)
         enddo ! over i={1,nsize} loop

! calculate the transition ratio between old and new configurations,
! for the local trace part, by lazy trace evaluation
         r = spring_sfmt_stream()
         ratup = p
         call ctqmc_lazy_ztrace( 3, nsize, ratup, zero, zero, r, p, pass )

! if update action is accepted
         if ( pass .eqv. .true. ) then

! get maximum rank order in spin up and spin down states
             kmax = max( rank(fup), rank(fdn) )

! swap global variables between spin up and spin down states
             call cat_reflip_matrix(fup, fdn, kmax)

! update the operators trace
             call ctqmc_make_evolve()

! if this update action can not be accepted, reset it
         else

! recover the original status of flvr_v
             do i=1,nsize
                 if ( flvr_v ( index_v(i) ) == fup ) then
                     flvr_v ( index_v(i) ) = fdn; CYCLE
                 endif ! back if ( flvr_v ( index_v(i) ) == fup ) block
                 if ( flvr_v ( index_v(i) ) == fdn ) then
                     flvr_v ( index_v(i) ) = fup; CYCLE
                 endif ! back if ( flvr_v ( index_v(i) ) == fdn ) block
             enddo ! over i={1,nsize} loop

! print exception information
!<             call s_print_exception('ctqmc_reflip_kink','quantum impurity solver refuse to reflip')

         endif ! back if ( pass .eqv. .true. ) block

! update the reflip statistics
         reflip_tcount = reflip_tcount + one
         if ( pass .eqv. .true. ) then
             reflip_accept = reflip_accept + one
         else
             reflip_reject = reflip_reject + one
         endif ! back if ( pass .eqv. .true. ) block

     else if ( cflip == 2 ) then ! cflip = 2, local flip
         do flvr=1,nband

! get fup and fdn
             fup = flvr; fdn = flvr + nband

! calculate the transition ratio between old and new configurations,
! for the determinant part, spin up case
             call cat_reflip_detrat(fup, fdn, ratup)

! calculate the transition ratio between old and new configurations,
! for the determinant part, spin dn case
             call cat_reflip_detrat(fdn, fup, ratdn)

! calculate the transition probability for global spin flip
             p = ratup * ratdn

! make a trial swap for flvr_v
             do i=1,nsize
                 if ( flvr_v ( index_v(i) ) == fup ) then
                     flvr_v ( index_v(i) ) = fdn; CYCLE
                 endif ! back if ( flvr_v ( index_v(i) ) == fup ) block
                 if ( flvr_v ( index_v(i) ) == fdn ) then
                     flvr_v ( index_v(i) ) = fup; CYCLE
                 endif ! back if ( flvr_v ( index_v(i) ) == fdn ) block
             enddo ! over i={1,nsize} loop

! make a copy of index_v, index_t is need by ctqmc_make_ztrace()
             do i=1,nsize
                 index_t(i) = index_v(i)
             enddo ! over i={1,nsize} loop

! calculate the transition ratio between old and new configurations,
! for the local trace part, by lazy trace evaluation
             r = spring_sfmt_stream()
             ratup = p
             call ctqmc_lazy_ztrace( 3, nsize, ratup, zero, zero, r, p, pass )

! if update action is accepted
             if ( pass .eqv. .true. ) then

! get maximum rank order in spin up and spin down states
                 kmax = max( rank(fup), rank(fdn) )

! swap global variables between spin up and spin down states
                 call cat_reflip_matrix(fup, fdn, kmax)

! update the operators trace
                 call ctqmc_make_evolve()

! if this update action can not be accepted, reset it
             else

! recover the original status of flvr_v
                 do i=1,nsize
                     if ( flvr_v ( index_v(i) ) == fup ) then
                         flvr_v ( index_v(i) ) = fdn; CYCLE
                     endif ! back if ( flvr_v ( index_v(i) ) == fup ) block
                     if ( flvr_v ( index_v(i) ) == fdn ) then
                         flvr_v ( index_v(i) ) = fup; CYCLE
                     endif ! back if ( flvr_v ( index_v(i) ) == fdn ) block
                 enddo ! over i={1,nsize} loop

! print exception information
!<                 call s_print_exception('ctqmc_reflip_kink','quantum impurity solver refuse to reflip')

             endif ! back if ( pass .eqv. .true. ) block

! update the reflip statistics
             reflip_tcount = reflip_tcount + one
             if ( pass .eqv. .true. ) then
                 reflip_accept = reflip_accept + one
             else
                 reflip_reject = reflip_reject + one
             endif ! back if ( pass .eqv. .true. ) block

         enddo ! over flvr={1,nband} loop

     else if ( cflip == 3 ) then ! cflip = 3, global flip
         do flvr=1,nband

! get fup and fdn
             fup = flvr; fdn = flvr + nband

! calculate the transition ratio between old and new configurations,
! for the determinant part, spin up case
             call cat_reflip_detrat(fup, fdn, ratup)

! calculate the transition ratio between old and new configurations,
! for the determinant part, spin dn case
             call cat_reflip_detrat(fdn, fup, ratdn)

! calculate the transition probability for global spin flip
             p = p * ( ratup * ratdn )

         enddo ! over flvr={1,nband} loop

! make a trial swap for flvr_v
         do i=1,nsize
             flvr = flvr_v( index_v(i) )
             if ( flvr <= nband ) then
                 flvr_v ( index_v(i) ) = flvr + nband
             else
                 flvr_v ( index_v(i) ) = flvr - nband
             endif ! back if ( flvr <= nband ) block
         enddo ! over i={1,nsize} loop

! make a copy of index_v, index_t is need by ctqmc_make_ztrace()
         do i=1,nsize
             index_t(i) = index_v(i)
         enddo ! over i={1,nsize} loop

! calculate the transition ratio between old and new configurations,
! for the local trace part, by lazy trace evaluation
         r = spring_sfmt_stream()
         ratup = p
         call ctqmc_lazy_ztrace( 3, nsize, ratup, zero, zero, r, p, pass )

! if update action is accepted
         if ( pass .eqv. .true. ) then

             do flvr=1,nband

! get fup and fdn
                 fup = flvr; fdn = flvr + nband

! get maximum rank order in spin up and spin down states
                 kmax = max( rank(fup), rank(fdn) )

! swap global variables between spin up and spin down states
                 call cat_reflip_matrix(fup, fdn, kmax)

             enddo ! over flvr={1,nband} loop

! update the operators trace
             call ctqmc_make_evolve()

! if this update action can not be accepted, reset it
         else

! recover the original status of flvr_v
             do i=1,nsize
                 flvr = flvr_v( index_v(i) )
                 if ( flvr <= nband ) then
                     flvr_v ( index_v(i) ) = flvr + nband
                 else
                     flvr_v ( index_v(i) ) = flvr - nband
                 endif ! back if ( flvr <= nband ) block
             enddo ! over i={1,nsize} loop

! print exception information
!<             call s_print_exception('ctqmc_reflip_kink','quantum impurity solver refuse to reflip')

         endif ! back if ( pass .eqv. .true. ) block

! update the reflip statistics
         reflip_tcount = reflip_tcount + one
         if ( pass .eqv. .true. ) then
             reflip_accept = reflip_accept + one
         else
             reflip_reject = reflip_reject + one
         endif ! back if ( pass .eqv. .true. ) block

     endif ! back if ( cflip == 1 ) block

     return
  end subroutine ctqmc_reflip_kink

!!>>> ctqmc_reload_kink: global update all operators in the perturbation
!!>>> expansion series
  subroutine ctqmc_reload_kink()
     use control, only : norbs
     use context, only : rank

     implicit none

! local variables
! loop index for flavor channel
     integer :: flvr

     do flvr=1,norbs

! check the perturbation expansion order ( number of existing create or
! destroy operators ) for current flavor channel
         if ( rank(flvr) == 0 ) CYCLE

! regenerate the mmat matrix and gmat matrix from scratch
         call cat_reload_matrix(flvr)

     enddo ! over flvr={1,norbs} loop

     return
  end subroutine ctqmc_reload_kink

!!========================================================================
!!>>> service layer: update M and G matrices                           <<<
!!========================================================================

!!>>> cat_insert_matrix: update the mmat matrix and gmat matrix for insert
!!>>> new create and destroy operators
  subroutine cat_insert_matrix(flvr, is, ie, tau_start, tau_end, deter_ratio)
     use constants, only : dp, zero, one, czero

     use control, only : nfreq
     use control, only : beta
     use context, only : ckink
     use context, only : index_s, index_e, exp_s, exp_e
     use context, only : lspace, rspace, lsaves, rsaves, mmat, gmat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address for insert new create and destroy operators
     integer, intent(in)  :: is
     integer, intent(in)  :: ie

! imaginary time \tau_s for new create operator
     real(dp), intent(in) :: tau_start

! imaginary time \tau_e for new destroy operator
     real(dp), intent(in) :: tau_end

! previous calculated determinant ratio
     real(dp), intent(in) :: deter_ratio

! local variables
! loop index over operators
     integer  :: i
     integer  :: j

! loop index over frequencies
     integer  :: k

! real(dp) dummy variables
     real(dp) :: p

! evaluate p at first
     p = one / deter_ratio

! shift lspace and rspace, and then supplement them with -1 at the end
     do i=ckink,ie,-1
         lspace(i+1, flvr) = lspace(i, flvr)
     enddo ! over i={ckink,ie,-1} loop
     lspace(ie, flvr) = -one

     do j=ckink,is,-1
         rspace(j+1, flvr) = rspace(j, flvr)
     enddo ! over j={ckink,is,-1} loop
     rspace(is, flvr) = -one

! scale lspace with p
     do i=1,ckink+1
         lspace(i, flvr) = lspace(i, flvr) * p
     enddo ! over i={1,ckink+1} loop

! shift mmat matrix
     do j=ckink,is,-1
         do i=ckink,ie,-1
             mmat(i+1, j+1, flvr) = mmat(i, j, flvr)
         enddo ! over i={ckink,ie,-1} loop
     enddo ! over j={ckink,is,-1} loop

     do j=ckink,is,-1
         do i=1,ie-1
             mmat(i, j+1, flvr) = mmat(i, j, flvr)
         enddo ! over i={1,ie-1} loop
     enddo ! over j={ckink,is,-1} loop

     do j=1,is-1
         do i=ckink,ie,-1
             mmat(i+1, j, flvr) = mmat(i, j, flvr)
         enddo ! over i={ckink,ie,-1} loop
     enddo ! over j={1,is-1} loop

! supplement mmat matrix with zero
     do i=1,ckink+1
         mmat(i, is, flvr) = zero
     enddo ! over i={1,ckink+1} loop

     do j=1,ckink+1
         mmat(ie, j, flvr) = zero
     enddo ! over j={1,ckink+1} loop

! finally evaluate mmat matrix
     do j=1,ckink+1
         do i=1,ckink+1
             mmat(i, j, flvr) = mmat(i, j, flvr) + lspace(i, flvr) * rspace(j, flvr)
         enddo ! over i={1,ckink+1} loop
     enddo ! over j={1,ckink+1} loop

! update the colour part of perturbation expansion series
     call cat_insert_colour(flvr, is, ie, tau_start, tau_end)

! update gmat matrix
     lsaves(:, flvr) = czero
     rsaves(:, flvr) = czero

     do i=1,ckink+1
         do k=1,nfreq
             lsaves(k, flvr) = lsaves(k, flvr) +         exp_e(k, index_e(i, flvr), flvr)   * lspace(i, flvr)
             rsaves(k, flvr) = rsaves(k, flvr) + dconjg( exp_s(k, index_s(i, flvr), flvr) ) * rspace(i, flvr)
         enddo ! over k={1,nfreq} loop
     enddo ! over i={1,ckink+1} loop

     p = one / beta ! we redefine p here
     do k=1,nfreq
         gmat(k, flvr, flvr) = gmat(k, flvr, flvr) - lsaves(k, flvr) * rsaves(k, flvr) * p
     enddo ! over k={1,nfreq} loop

! only for debug
!<     do i=1,ckink+1
!<         do j=1,ckink+1
!<             print *, 'M:', i, j, mmat(i, j, flvr)
!<         enddo ! over j={1,ckink+1} loop
!<     enddo ! over i={1,ckink+1} loop
!<
!<     print *, 'G1:', flvr, gmat(1, flvr, flvr)
!<     print *, 'G2:', flvr, gmat(2, flvr, flvr)
!<     print *, 'G3:', flvr, gmat(3, flvr, flvr)
!<     print *, 'Gn:', flvr, gmat(nfreq, flvr, flvr)

     return
  end subroutine cat_insert_matrix

!!>>> cat_remove_matrix: update the mmat matrix and gmat matrix for remove
!!>>> old create and destroy operators
  subroutine cat_remove_matrix(flvr, is, ie)
     use constants, only : dp, one, czero

     use control, only : nfreq
     use control, only : beta
     use context, only : ckink
     use context, only : index_s, index_e, exp_s, exp_e
     use context, only : lsaves, rsaves, mmat, gmat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in) :: flvr

! index address for remove old create and destroy operators
     integer, intent(in) :: is
     integer, intent(in) :: ie

! local variables
! loop index over operators
     integer  :: i
     integer  :: j

! loop index over frequencies
     integer  :: k

! real(dp) dummy variables
     real(dp) :: p

! update gmat matrix
     lsaves(:, flvr) = czero
     rsaves(:, flvr) = czero

     do i=1,ckink
         do k=1,nfreq
             lsaves(k, flvr) = lsaves(k, flvr) +         exp_e(k, index_e(i, flvr), flvr)   * mmat(i, is, flvr)
             rsaves(k, flvr) = rsaves(k, flvr) + dconjg( exp_s(k, index_s(i, flvr), flvr) ) * mmat(ie, i, flvr)
         enddo ! over k={1,nfreq} loop
     enddo ! over i={1,ckink} loop

     p = one / ( mmat(ie, is, flvr) * beta )
     do k=1,nfreq
         gmat(k, flvr, flvr) = gmat(k, flvr, flvr) + lsaves(k, flvr) * rsaves(k, flvr) * p
     enddo ! over k={1,nfreq} loop

! update mmat matrix
     p = one / mmat(ie, is, flvr) ! we redefine p here
     do j=1,ckink
         do i=1,ckink
             if ( i /= ie .and. j /= is ) then
                 mmat(i, j, flvr) = mmat(i, j, flvr) - mmat(i, is, flvr) * mmat(ie, j, flvr) * p
             endif ! back if ( i /= ie .and. j /= is ) block
         enddo ! over i={1,ckink} loop
     enddo ! over j={1,ckink} loop

     do j=is,ckink-1
         do i=ie,ckink-1
             mmat(i, j, flvr) = mmat(i+1, j+1, flvr)
         enddo ! over i={ie,ckink-1} loop
     enddo ! over j={is,ckink-1} loop

     do j=is,ckink-1
         do i=1,ie-1
             mmat(i, j, flvr) = mmat(i, j+1, flvr)
         enddo ! over i={1,ie-1} loop
     enddo ! over j={is,ckink-1} loop

     do j=1,is-1
         do i=ie,ckink-1
             mmat(i, j, flvr) = mmat(i+1, j, flvr)
         enddo ! over i={ie,ckink-1} loop
     enddo ! over j={1,is-1} loop

! update the colour part of perturbation expansion series
     call cat_remove_colour(flvr, is, ie)

! only for debug
!<     do i=1,ckink
!<         do j=1,ckink
!<             print *, 'M:', i, j, mmat(i, j, flvr)
!<         enddo ! over j={1,ckink} loop
!<     enddo ! over i={1,ckink} loop
!<
!<     print *, 'G1:', flvr, gmat(1, flvr, flvr)
!<     print *, 'G2:', flvr, gmat(2, flvr, flvr)
!<     print *, 'G3:', flvr, gmat(3, flvr, flvr)
!<     print *, 'Gn:', flvr, gmat(nfreq, flvr, flvr)

     return
  end subroutine cat_remove_matrix

!!>>> cat_lshift_matrix: update the mmat matrix and gmat matrix for shift
!!>>> old create operators
  subroutine cat_lshift_matrix(flvr, iso, isn, tau_start1, tau_start2, deter_ratio)
     use constants, only : dp, zero, czero

     use control, only : mkink
     use control, only : nfreq
     use control, only : beta
     use context, only : ckink
     use context, only : index_s, index_e, time_e, exp_s, exp_e
     use context, only : rmesh
     use context, only : lspace, rspace, lsaves, rsaves, mmat, gmat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address to shift old create operators
! iso and isn are for old and new indices, respectively
     integer, intent(in)  :: iso
     integer, intent(in)  :: isn

! imaginary time \tau_s for create operator (the old one)
     real(dp), intent(in) :: tau_start1

! imaginary time \tau_s for create operator (the new one)
     real(dp), intent(in) :: tau_start2

! previous calculated determinant ratio
     real(dp), intent(in) :: deter_ratio

! external arguments
! used to interpolate the hybridization function
     procedure( real(dp) ) :: ctqmc_make_htau

! local variables
! loop index over operators
     integer  :: i
     integer  :: j

! loop index over frequencies
     integer  :: k

! used to store matrix element of mmat
     real(dp) :: md

! real(dp) dummy variables
     real(dp) :: xs
     real(dp) :: rs

! real(dp) dummy arrays, used to interpolate the hybridization function
     real(dp) :: lvec(mkink)
     real(dp) :: rvec(mkink)

! complex(dp) dummy arrays, used to calculate gmat matrix
     complex(dp) :: lexp(nfreq)
     complex(dp) :: gsum(nfreq)
     complex(dp) :: gdel(nfreq)

! evaluate lexp
     lexp = czero
     do k=1,nfreq
         xs = tau_start2 * rmesh(k)
         lexp(k) = - ( dcmplx( cos(xs), -sin(xs) ) - dconjg( exp_s(k, index_s(iso, flvr), flvr) ) ) / beta
     enddo ! over k={1,nfreq} loop

! evaluate gsum
     gsum = czero
     do i=1,ckink
         md = mmat(i, iso, flvr)
         do k=1,nfreq
             gsum(k) = gsum(k) + exp_e(k, index_e(i, flvr), flvr) * md
         enddo ! over k={1,nfreq} loop
     enddo ! over i={1,ckink} loop

! evaluate gdel, \delta G for gmat matrix
     gdel = czero
     do k=1,nfreq
         gdel(k) = gsum(k) * lexp(k)
     enddo ! over k={1,nfreq} loop

! calculate rvec by cubic spline interpolation
     do i=1,ckink
         if ( tau_start1 < time_e(index_e(i, flvr), flvr) ) then
             rvec(i) = -ctqmc_make_htau(flvr, tau_start1 - time_e(index_e(i, flvr), flvr) + beta)
         else
             rvec(i) =  ctqmc_make_htau(flvr, tau_start1 - time_e(index_e(i, flvr), flvr))
         endif ! back if ( tau_start1 < time_e(index_e(i, flvr), flvr) ) block
     enddo ! over i={1,ckink} loop

! calculate lvec by cubic spline interpolation
     do j=1,ckink
         if ( tau_start2 < time_e(index_e(j, flvr), flvr) ) then
             lvec(j) = -ctqmc_make_htau(flvr, tau_start2 - time_e(index_e(j, flvr), flvr) + beta)
         else
             lvec(j) =  ctqmc_make_htau(flvr, tau_start2 - time_e(index_e(j, flvr), flvr))
         endif ! back if ( tau_start2 < time_e(index_e(j, flvr), flvr) ) block
     enddo ! over j={1,ckink} loop

! adjust rvec
     do i=1,ckink
         rvec(i) = lvec(i) - rvec(i)
     enddo ! over i={1,ckink} loop

! prepare rspace
     do i=1,ckink
         rs = zero
         do j=1,ckink
             rs = rs + rvec(j) * mmat(j, i, flvr)
         enddo ! over j={1,ckink} loop
         rspace(i, flvr) = rs / deter_ratio
     enddo ! over i={1,ckink} loop

! prepare lspace
     do i=1,ckink
         lspace(i, flvr) = -mmat(i, iso, flvr)
     enddo ! over i={1,ckink} loop

! calculate mmat matrix
     do j=1,ckink
         do i=1,ckink
             mmat(i, j, flvr) = mmat(i, j, flvr) + lspace(i, flvr) * rspace(j, flvr)
         enddo ! over i={1,ckink} loop
     enddo ! over j={1,ckink} loop

! shuffle rows if time order changed because of move
     if ( isn /= iso ) then
         rs = rspace(iso, flvr)
         do i=1,ckink
             rvec(i) = mmat(i, iso, flvr)
         enddo ! over i={1,ckink} loop

         if ( isn < iso ) then
             do j=iso,isn+1,-1
                 do i=1,ckink
                     mmat(i, j, flvr) = mmat(i, j-1, flvr)
                 enddo ! over i={1,ckink} loop
                 rspace(j, flvr) = rspace(j-1, flvr)
             enddo ! over j={iso,isn+1,-1} loop
             do i=1,ckink
                 mmat(i, isn, flvr) = rvec(i)
             enddo ! over i={1,ckink} loop
             rspace(isn, flvr) = rs
         else
             do j=iso,isn-1
                 do i=1,ckink
                     mmat(i, j, flvr) = mmat(i, j+1, flvr)
                 enddo ! over i={1,ckink} loop
                 rspace(j, flvr) = rspace(j+1, flvr)
             enddo ! over j={iso,isn-1} loop
             do i=1,ckink
                 mmat(i, isn, flvr) = rvec(i)
             enddo ! over i={1,ckink} loop
             rspace(isn, flvr) = rs
         endif ! back if ( isn < iso ) block
     endif ! back if ( isn /= iso ) block

! update the colour part of perturbation expansion series
     call cat_lshift_colour(flvr, iso, isn, tau_start2)

! update gmat matrix
     lsaves(:, flvr) = czero
     rsaves(:, flvr) = czero

     do i=1,ckink
         do k=1,nfreq
             lsaves(k, flvr) = lsaves(k, flvr) +         exp_e(k, index_e(i, flvr), flvr)   * lspace(i, flvr)
             rsaves(k, flvr) = rsaves(k, flvr) + dconjg( exp_s(k, index_s(i, flvr), flvr) ) * rspace(i, flvr)
         enddo ! over k={1,nfreq} loop
     enddo ! over i={1,ckink} loop

     do k=1,nfreq
         gmat(k, flvr, flvr) = gmat(k, flvr, flvr) - lsaves(k, flvr) * rsaves(k, flvr) / beta + gdel(k)
     enddo ! over k={1,nfreq} loop

! only for debug
!<     do i=1,ckink
!<         do j=1,ckink
!<             print *,'M:',i, j, mmat(i, j, flvr)
!<         enddo ! over j={1,ckink} loop
!<     enddo ! over i={1,ckink} loop
!<
!<     print *, 'G1:', flvr, gmat(1, flvr, flvr)
!<     print *, 'G2:', flvr, gmat(2, flvr, flvr)
!<     print *, 'G3:', flvr, gmat(3, flvr, flvr)
!<     print *, 'Gn:', flvr, gmat(nfreq, flvr, flvr)

     return
  end subroutine cat_lshift_matrix

!!>>> cat_rshift_matrix: update the mmat matrix and gmat matrix for shift
!!>>> old destroy operators
  subroutine cat_rshift_matrix(flvr, ieo, ien, tau_end1, tau_end2, deter_ratio)
     use constants, only : dp, zero, czero

     use control, only : mkink
     use control, only : nfreq
     use control, only : beta
     use context, only : ckink
     use context, only : index_s, index_e, time_s, exp_s, exp_e
     use context, only : rmesh
     use context, only : lspace, rspace, lsaves, rsaves, mmat, gmat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)  :: flvr

! index address to shift old destroy operators
! ieo and ien are for old and new indices, respectively
     integer, intent(in)  :: ieo
     integer, intent(in)  :: ien

! imaginary time \tau_e for destroy operator (the old one)
     real(dp), intent(in) :: tau_end1

! imaginary time \tau_e for destroy operator (the new one)
     real(dp), intent(in) :: tau_end2

! previous calculated determinant ratio
     real(dp), intent(in) :: deter_ratio

! external arguments
! used to interpolate the hybridization function
     procedure( real(dp) ) :: ctqmc_make_htau

! local variables
! loop index over operators
     integer  :: i
     integer  :: j

! loop index over frequencies
     integer  :: k

! used to store matrix element of mmat
     real(dp) :: md

! real(dp) dummy variables
     real(dp) :: xe
     real(dp) :: ls

! real(dp) dummy arrays, used to interpolate the hybridization function
     real(dp) :: lvec(mkink)
     real(dp) :: rvec(mkink)

! complex(dp) dummy arrays, used to calculate gmat matrix
     complex(dp) :: rexp(nfreq)
     complex(dp) :: gsum(nfreq)
     complex(dp) :: gdel(nfreq)

! evaluate rexp
     rexp = czero
     do k=1,nfreq
         xe = tau_end2 * rmesh(k)
         rexp(k) = - ( dcmplx( cos(xe), sin(xe) ) - exp_e(k, index_e(ieo, flvr), flvr) ) / beta
     enddo ! over k={1,nfreq} loop

! evaluate gsum
     gsum = czero
     do i=1,ckink
         md = mmat(ieo, i, flvr)
         do k=1,nfreq
             gsum(k) = gsum(k) + dconjg( exp_s(k, index_s(i, flvr), flvr) ) * md
         enddo ! over k={1,nfreq} loop
     enddo ! over i={1,ckink} loop

! evaluate gdel, \delta G for gmat matrix
     gdel = czero
     do k=1,nfreq
         gdel(k) = gsum(k) * rexp(k)
     enddo ! over k={1,nfreq} loop

! calculate lvec by cubic spline interpolation
     do i=1,ckink
         if ( time_s(index_s(i, flvr), flvr) < tau_end1 ) then
             lvec(i) = -ctqmc_make_htau(flvr, time_s(index_s(i, flvr), flvr) - tau_end1 + beta)
         else
             lvec(i) =  ctqmc_make_htau(flvr, time_s(index_s(i, flvr), flvr) - tau_end1)
         endif ! back if ( time_s(index_s(i, flvr), flvr) < tau_end1 ) block
     enddo ! over i={1,ckink} loop

! calculate rvec by cubic spline interpolation
     do j=1,ckink
         if ( time_s(index_s(j, flvr), flvr) < tau_end2 ) then
             rvec(j) = -ctqmc_make_htau(flvr, time_s(index_s(j, flvr), flvr) - tau_end2 + beta)
         else
             rvec(j) =  ctqmc_make_htau(flvr, time_s(index_s(j, flvr), flvr) - tau_end2)
         endif ! back if ( time_s(index_s(j, flvr), flvr) < tau_end2 ) block
     enddo ! over j={1,ckink} loop

! adjust lvec
     do i=1,ckink
         lvec(i) = rvec(i) - lvec(i)
     enddo ! over i={1,ckink} loop

! prepare lspace
     do i=1,ckink
         ls = zero
         do j=1,ckink
             ls = ls + mmat(i, j, flvr) * lvec(j)
         enddo ! over j={1,ckink} loop
         lspace(i, flvr) = ls / deter_ratio
     enddo ! over i={1,ckink} loop

! prepare rspace
     do i=1,ckink
         rspace(i, flvr) = -mmat(ieo, i, flvr)
     enddo ! over i={1,ckink} loop

! calculate mmat matrix
     do j=1,ckink
         do i=1,ckink
             mmat(i, j, flvr) = mmat(i, j, flvr) + lspace(i, flvr) * rspace(j, flvr)
         enddo ! over i={1,ckink} loop
     enddo ! over j={1,ckink} loop

! shuffle columns if time order changed because of move
     if ( ien /= ieo ) then
         ls = lspace(ieo, flvr)
         do i=1,ckink
             lvec(i) = mmat(ieo, i, flvr)
         enddo ! over i={1,ckink} loop

         if ( ien < ieo ) then
             do j=ieo,ien+1,-1
                 do i=1,ckink
                     mmat(j, i, flvr) = mmat(j-1, i, flvr)
                 enddo ! over i={1,ckink} loop
                 lspace(j, flvr) = lspace(j-1, flvr)
             enddo ! over j={ieo,ien+1,-1} loop
             do i=1,ckink
                 mmat(ien, i, flvr) = lvec(i)
             enddo ! over i={1,ckink} loop
             lspace(ien, flvr) = ls
         else
             do j=ieo,ien-1
                 do i=1,ckink
                     mmat(j, i, flvr) = mmat(j+1, i, flvr)
                 enddo ! over i={1,ckink} loop
                 lspace(j, flvr) = lspace(j+1, flvr)
             enddo ! over j={ieo,ien-1} loop
             do i=1,ckink
                 mmat(ien, i, flvr) = lvec(i)
             enddo ! over i={1,ckink} loop
             lspace(ien, flvr) = ls
         endif ! back if ( ien < ieo ) block
     endif ! back if ( ien /= ieo ) block

! update the colour part of perturbation expansion series
     call cat_rshift_colour(flvr, ieo, ien, tau_end2)

! update gmat matrix
     lsaves(:, flvr) = czero
     rsaves(:, flvr) = czero

     do i=1,ckink
         do k=1,nfreq
             lsaves(k, flvr) = lsaves(k, flvr) +         exp_e(k, index_e(i, flvr), flvr)   * lspace(i, flvr)
             rsaves(k, flvr) = rsaves(k, flvr) + dconjg( exp_s(k, index_s(i, flvr), flvr) ) * rspace(i, flvr)
         enddo ! over k={1,nfreq} loop
     enddo ! over i={1,ckink} loop

     do k=1,nfreq
         gmat(k, flvr, flvr) = gmat(k, flvr, flvr) - lsaves(k, flvr) * rsaves(k, flvr) / beta + gdel(k)
     enddo ! over k={1,nfreq} loop

! only for debug
!<     do i=1,ckink
!<         do j=1,ckink
!<             print *,'M:',i, j, mmat(i, j, flvr)
!<         enddo ! over j={1,ckink} loop
!<     enddo ! over i={1,ckink} loop
!<
!<     print *, 'G1:', flvr, gmat(1, flvr, flvr)
!<     print *, 'G2:', flvr, gmat(2, flvr, flvr)
!<     print *, 'G3:', flvr, gmat(3, flvr, flvr)
!<     print *, 'Gn:', flvr, gmat(nfreq, flvr, flvr)

     return
  end subroutine cat_rshift_matrix

!!>>> cat_reflip_matrix: global flip the time_s, time_e, mmat matrix, gmat
!!>>> matrix, and other related global variables between spin up and spin
!!>>> down states. it is used to avoid trapped by unphysical phase
  subroutine cat_reflip_matrix(fup, fdn, kmax)
     use stack, only : istack, istack_create, istack_copyer, istack_destroy

     use control, only : mkink
     use control, only : nfreq
     use context, only : empty_s, empty_e, index_s, index_e, time_s, time_e, exp_s, exp_e
     use context, only : rank
     use context, only : gmat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in) :: fup
     integer, intent(in) :: fdn

! maximum rank order for current flavor channel
     integer, intent(in) :: kmax

! local variables
! maximum memory index accessed by index_s and index_e
     integer :: ismax
     integer :: iemax

! dummy copy for rank
     integer :: Trank

! dummy copy for empty_s and empty_e
     type (istack) :: Tempty_s
     type (istack) :: Tempty_e

! allocate memory for Tempty_s and Tempty_e
     call istack_create(Tempty_s, mkink)
     call istack_create(Tempty_e, mkink)

! swap empty_s and empty_e
     call istack_copyer(empty_s(fup), Tempty_s)
     call istack_copyer(empty_e(fup), Tempty_e)

     call istack_copyer(empty_s(fdn), empty_s(fup))
     call istack_copyer(empty_e(fdn), empty_e(fup))

     call istack_copyer(Tempty_s, empty_s(fdn))
     call istack_copyer(Tempty_e, empty_e(fdn))

! deallocate memory for Tempty_s and Tempty_e
     call istack_destroy(Tempty_s)
     call istack_destroy(Tempty_e)

! swap rank
     Trank = rank(fup)
     rank(fup) = rank(fdn)
     rank(fdn) = Trank

! swap gmat matrix when needed
     call s_swap_z(nfreq, gmat(1:nfreq, fup, fup), gmat(1:nfreq, fdn, fdn))

     if ( kmax > 0 ) then

! determine ismax and iemax
         ismax = max( maxval( index_s(1:kmax, fup) ), maxval( index_s(1:kmax, fdn) ) )
         iemax = max( maxval( index_e(1:kmax, fup) ), maxval( index_e(1:kmax, fdn) ) )

! swap index_s and index_e
         call s_swap_i(kmax, index_s(1:kmax, fup), index_s(1:kmax, fdn))
         call s_swap_i(kmax, index_e(1:kmax, fup), index_e(1:kmax, fdn))

! swap time_s and time_e
         call s_swap_d(ismax, time_s(1:ismax, fup), time_s(1:ismax, fdn))
         call s_swap_d(iemax, time_e(1:iemax, fup), time_e(1:iemax, fdn))

! swap exp_s and exp_e
         call s_swap_z(nfreq*ismax, exp_s(1:nfreq, 1:ismax, fup), exp_s(1:nfreq, 1:ismax, fdn))
         call s_swap_z(nfreq*iemax, exp_e(1:nfreq, 1:iemax, fup), exp_e(1:nfreq, 1:iemax, fdn))

! update mmat and gmat matrix when needed
         if ( rank(fup) > 0 ) call cat_reload_matrix(fup)
         if ( rank(fdn) > 0 ) call cat_reload_matrix(fdn)

     endif ! back if ( kmax > 0 ) block

     return
  end subroutine cat_reflip_matrix

!!>>> cat_reload_matrix: global update the mmat matrix and gmat matrix
!!>>> from scratch
  subroutine cat_reload_matrix(flvr)
     use constants, only : dp, zero, czero

     use control, only : nfreq
     use control, only : beta
     use context, only : index_s, index_e, time_s, time_e, exp_s, exp_e
     use context, only : rank
     use context, only : mmat, gmat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in) :: flvr

! external functions
! used to interpolate the hybridization function
     procedure( real(dp) ) :: ctqmc_make_htau

! local variables
! loop index over operators
     integer  :: i
     integer  :: j

! loop index over frequencies
     integer  :: k

! dummy perturbation expansion order
     integer  :: kaux

! used to store matrix element of mmat
     real(dp) :: maux

! imaginary time for create and destroy operators
     real(dp) :: tau_start
     real(dp) :: tau_end

! complex(dp) dummy variables
     complex(dp) :: x_start
     complex(dp) :: x_end

! evaluate kaux
     kaux = rank(flvr)

! reset mmat matrix
     mmat(1:kaux, 1:kaux, flvr) = zero

! recalculate mmat from scratch
     do j=1,kaux
         tau_end = time_e(index_e(j, flvr), flvr)
         do i=1,kaux
             tau_start = time_s(index_s(i, flvr), flvr)
             if ( tau_start < tau_end ) then
                 mmat(i, j, flvr) = -ctqmc_make_htau(flvr, tau_start - tau_end + beta)
             else
                 mmat(i, j, flvr) =  ctqmc_make_htau(flvr, tau_start - tau_end)
             endif ! back if ( tau_start < tau_end ) block
         enddo ! over i={1,kaux} loop
     enddo ! over j={1,kaux} loop

! now we obtain dmat matrix, while what we need is its inversion
     call s_inv_d(kaux, mmat(1:kaux, 1:kaux, flvr))

! reset gmat matrix
     gmat(:, flvr, flvr) = czero

! recalculate gmat from scratch
     do j=1,kaux
         do i=1,kaux
             maux = -mmat(i, j, flvr) / beta
             do k=1,nfreq
                 x_start = dconjg( exp_s(k, index_s(j, flvr), flvr) )
                 x_end   =         exp_e(k, index_e(i, flvr), flvr)
                 gmat(k, flvr, flvr) = gmat(k, flvr, flvr) + x_end * maux * x_start
             enddo ! over k={1,nfreq} loop
         enddo ! over i={1,kaux} loop
     enddo ! over j={1,kaux} loop

     return
  end subroutine cat_reload_matrix

!!========================================================================
!!>>> service layer: evaluate the determinant ratio                    <<<
!!========================================================================

!!>>> cat_insert_detrat: calculate the determinant ratio for insert new
!!>>> create and destroy operators
  subroutine cat_insert_detrat(flvr, tau_start, tau_end, deter_ratio)
     use constants, only : dp, zero

     use control, only : mkink
     use control, only : beta
     use context, only : ckink
     use context, only : index_s, index_e, time_s, time_e
     use context, only : lspace, rspace, mmat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! imaginary time \tau_s for new create operator
     real(dp), intent(in)  :: tau_start

! imaginary time \tau_e for new destroy operator
     real(dp), intent(in)  :: tau_end

! the desired determinant ratio
     real(dp), intent(out) :: deter_ratio

! external arguments
! used to interpolate the hybridization function
     procedure( real(dp) ) :: ctqmc_make_htau

! local variables
! loop index over operators
     integer  :: i
     integer  :: j

! real(dp) dummy variables
     real(dp) :: sl
     real(dp) :: sr

! real(dp) dummy arrays, used to interpolate the hybridization function
     real(dp) :: lvec(mkink)
     real(dp) :: rvec(mkink)

! calculate lvec by cubic spline interpolation
     do i=1,ckink
         if ( time_s(index_s(i, flvr), flvr) < tau_end   ) then
             lvec(i) = -ctqmc_make_htau(flvr, time_s(index_s(i, flvr), flvr) - tau_end + beta)
         else
             lvec(i) =  ctqmc_make_htau(flvr, time_s(index_s(i, flvr), flvr) - tau_end)
         endif ! back if ( time_s(index_s(i, flvr), flvr) < tau_end   ) block
     enddo ! over i={1,ckink} loop

! calculate rvec by cubic spline interpolation
     do j=1,ckink
         if ( tau_start < time_e(index_e(j, flvr), flvr) ) then
             rvec(j) = -ctqmc_make_htau(flvr, tau_start - time_e(index_e(j, flvr), flvr) + beta)
         else
             rvec(j) =  ctqmc_make_htau(flvr, tau_start - time_e(index_e(j, flvr), flvr))
         endif ! back if ( tau_start < time_e(index_e(j, flvr), flvr) ) block
     enddo ! over j={1,ckink} loop

! calculate deter_ratio by cubic spline interpolation
     if ( tau_start > tau_end ) then
         deter_ratio =  ctqmc_make_htau(flvr, tau_start - tau_end)
     else
         deter_ratio = -ctqmc_make_htau(flvr, tau_start - tau_end + beta)
     endif ! back if ( tau_start > tau_end ) block

! calculate lspace and rspace
     do i=1,ckink
         sl = zero
         sr = zero

         do j=1,ckink
             sl = sl + mmat(i, j, flvr) * lvec(j)
             sr = sr + rvec(j) * mmat(j, i, flvr)
         enddo ! over j={1,ckink} loop

         lspace(i, flvr) = sl
         rspace(i, flvr) = sr
     enddo ! over i={1,ckink} loop

! calculate final determinant ratio
     do i=1,ckink
         deter_ratio = deter_ratio - rvec(i) * lspace(i, flvr)
     enddo ! over i={1,ckink} loop

     return
  end subroutine cat_insert_detrat

!!>>> cat_remove_detrat: calculate the determinant ratio for remove old
!!>>> create and destroy operators
  subroutine cat_remove_detrat(flvr, is, ie, deter_ratio)
     use constants, only : dp

     use context, only : mmat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address to remove old create and destroy operators
! is and ie are for create and destroy operators, respectively
     integer, intent(in)   :: is
     integer, intent(in)   :: ie

! the desired determinant ratio
     real(dp), intent(out) :: deter_ratio

     deter_ratio = mmat(ie, is, flvr)

     return
  end subroutine cat_remove_detrat

!!>>> cat_lshift_detrat: calculate the determinant ratio for shift old
!!>>> create operators
  subroutine cat_lshift_detrat(flvr, addr, tau_start1, tau_start2, deter_ratio)
     use constants, only : dp, one

     use control, only : mkink
     use control, only : beta
     use context, only : ckink
     use context, only : index_e, time_e
     use context, only : mmat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address for shift old create operator (old index = iso)
     integer, intent(in)   :: addr

! imaginary time \tau_s for create operator (the old one)
     real(dp), intent(in)  :: tau_start1

! imaginary time \tau_s for create operator (the new one)
     real(dp), intent(in)  :: tau_start2

! the desired determinant ratio
     real(dp), intent(out) :: deter_ratio

! external functions
! used to interpolate the hybridization function
     procedure( real(dp) ) :: ctqmc_make_htau

! local variables
! loop index over operators
     integer  :: i
     integer  :: j

! real(dp) dummy arrays, used to interpolate the hybridization function
     real(dp) :: lvec(mkink)
     real(dp) :: rvec(mkink)

! calculate rvec by cubic spline interpolation
     do i=1,ckink
         if ( tau_start1 < time_e(index_e(i, flvr), flvr) ) then
             rvec(i) = -ctqmc_make_htau(flvr, tau_start1 - time_e(index_e(i, flvr), flvr) + beta)
         else
             rvec(i) =  ctqmc_make_htau(flvr, tau_start1 - time_e(index_e(i, flvr), flvr))
         endif ! back if ( tau_start1 < time_e(index_e(i, flvr), flvr) ) block
     enddo ! over i={1,ckink} loop

! calculate lvec by cubic spline interpolation
     do j=1,ckink
         if ( tau_start2 < time_e(index_e(j, flvr), flvr) ) then
             lvec(j) = -ctqmc_make_htau(flvr, tau_start2 - time_e(index_e(j, flvr), flvr) + beta)
         else
             lvec(j) =  ctqmc_make_htau(flvr, tau_start2 - time_e(index_e(j, flvr), flvr))
         endif ! back if ( tau_start2 < time_e(index_e(j, flvr), flvr) ) block
     enddo ! over j={1,ckink} loop

! adjust rvec
     do i=1,ckink
         rvec(i) = lvec(i) - rvec(i)
     enddo ! over i={1,ckink} loop

! calculate final determinant ratio
     deter_ratio = one
     do i=1,ckink
         deter_ratio = deter_ratio + rvec(i) * mmat(i, addr, flvr)
     enddo ! over i={1,ckink} loop

     return
  end subroutine cat_lshift_detrat

!!>>> cat_rshift_detrat: calculate the determinant ratio for shift old
!!>>> destroy operators
  subroutine cat_rshift_detrat(flvr, addr, tau_end1, tau_end2, deter_ratio)
     use constants, only : dp, one

     use control, only : mkink
     use control, only : beta
     use context, only : ckink
     use context, only : index_s, time_s
     use context, only : mmat

     implicit none

! external arguments
! current flavor channel
     integer, intent(in)   :: flvr

! index address for shift old destroy operator (old index = ieo)
     integer, intent(in)   :: addr

! imaginary time \tau_e for destroy operator (the old one)
     real(dp), intent(in)  :: tau_end1

! imaginary time \tau_e for destroy operator (the new one)
     real(dp), intent(in)  :: tau_end2

! the desired determinant ratio
     real(dp), intent(out) :: deter_ratio

! external functions
! used to interpolate the hybridization function
     procedure( real(dp) ) :: ctqmc_make_htau

! local variables
! loop index over operators
     integer  :: i
     integer  :: j

! real(dp) dummy arrays, used to interpolate the hybridization function
     real(dp) :: lvec(mkink)
     real(dp) :: rvec(mkink)

! calculate lvec by cubic spline interpolation
     do i=1,ckink
         if ( time_s(index_s(i, flvr), flvr) < tau_end1 ) then
             lvec(i) = -ctqmc_make_htau(flvr, time_s(index_s(i, flvr), flvr) - tau_end1 + beta)
         else
             lvec(i) =  ctqmc_make_htau(flvr, time_s(index_s(i, flvr), flvr) - tau_end1)
         endif ! back if ( time_s(index_s(i, flvr), flvr) < tau_end1 ) block
     enddo ! over i={1,ckink} loop

! calculate rvec by cubic spline interpolation
     do j=1,ckink
         if ( time_s(index_s(j, flvr), flvr) < tau_end2 ) then
             rvec(j) = -ctqmc_make_htau(flvr, time_s(index_s(j, flvr), flvr) - tau_end2 + beta)
         else
             rvec(j) =  ctqmc_make_htau(flvr, time_s(index_s(j, flvr), flvr) - tau_end2)
         endif ! back if ( time_s(index_s(j, flvr), flvr) < tau_end2 ) block
     enddo ! over j={1,ckink} loop

! adjust lvec
     do i=1,ckink
         lvec(i) = rvec(i) - lvec(i)
     enddo ! over i={1,ckink} loop

! calculate final determinant ratio
     deter_ratio = one
     do i=1,ckink
         deter_ratio = deter_ratio + mmat(addr, i, flvr) * lvec(i)
     enddo ! over i={1,ckink} loop

     return
  end subroutine cat_rshift_detrat

!!>>> cat_reflip_detrat: calculate the determinant ratio for global
!!>>> spin flip
  subroutine cat_reflip_detrat(up, dn, ratio)
     use constants, only : dp, zero, one

     use control, only : beta
     use context, only : index_s, index_e, time_s, time_e
     use context, only : rank
     use context, only : mmat

     implicit none

! external arguments
! band index for spin up state
     integer, intent(in)   :: up

! band index for spin dn state
     integer, intent(in)   :: dn

! the desired determinant ratio
     real(dp), intent(out) :: ratio

! external functions
! used to interpolate the hybridization function
     procedure( real(dp) ) :: ctqmc_make_htau

! local variables
! loop index over operators
     integer  :: i
     integer  :: j

! dummy perturbation expansion order
     integer  :: kaux

! status flag
     integer  :: istat

! imaginary time for create and destroy operators
     real(dp) :: tau_start
     real(dp) :: tau_end

! dummy mmat matrix
     real(dp), allocatable :: Dmm(:,:)
     real(dp), allocatable :: Tmm(:,:)

! evaluate kaux
     kaux = rank(up)

! check the status of kaux, if there does not exist any operators in up
! state ( kaux == 0 ), we need to return immediately and the ratio is one
     if ( kaux == 0 ) then
         ratio = one
         RETURN
     endif ! back if ( kaux == 0 ) block

! allocate memory
     allocate(Dmm(kaux,kaux), stat=istat)
     allocate(Tmm(kaux,kaux), stat=istat)
     if ( istat /= 0 ) then
         call s_print_error('cat_reflip_detrat','can not allocate enough memory')
     endif ! back if ( istat /= 0 ) block

! init Dmm and Tmm matrix
     Dmm = zero
     Tmm = zero

! recalculate Dmm from scratch
     do j=1,kaux
         tau_end = time_e(index_e(j, up), up)
         do i=1,kaux
             tau_start = time_s(index_s(i, up), up)
             if ( tau_start < tau_end ) then
                 Dmm(i, j) = -ctqmc_make_htau(dn, tau_start - tau_end + beta)
             else
                 Dmm(i, j) =  ctqmc_make_htau(dn, tau_start - tau_end)
             endif ! back if ( tau_start < tau_end ) block
         enddo ! over i={1,kaux} loop
     enddo ! over j={1,kaux} loop

! calculate Tmm: Tmm = Dmm . Mmat
     call dgemm('N', 'N', kaux, kaux, kaux, one, Dmm, kaux, mmat(1:kaux, 1:kaux, up), kaux, zero, Tmm, kaux)

! calculate the determinant of Tmm, it is the desired ratio
     call s_det_d(kaux, Tmm, ratio)

! deallocate memory
     deallocate(Dmm)
     deallocate(Tmm)

     return
  end subroutine cat_reflip_detrat
