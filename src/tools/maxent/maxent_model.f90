!---------------------------------------------------------------
! project : maxent
! program : maxent_make_flat_model
!           maxent_make_gauss_model
!           maxent_make_file_model
! source  : maxent_model.f90
! type    : subroutine
! author  : yilin wang (email: qhwyl2006@126.com)
! history : 05/31/2013 by yilin wang
! purpose : subroutines used to generate default model 
! input   :
! output  :
! status  : unstable
! comment :
!---------------------------------------------------------------

!===============================================================
! subroutine maxent_make_flat_model generates a flat model
!===============================================================
  subroutine maxent_make_flat_model()
      use constants
      use control
      use context

      implicit none

! local variables
      integer :: iw

      do iw=1, nw
          aw_model(iw) = one / ( real(nw-1) * step)
      enddo

      return
  end subroutine maxent_make_flat_model

!===============================================================
! subroutine maxent_make_gauss_model generates a gauss model
!===============================================================
  subroutine maxent_make_gauss_model()
      use constants
      use control
      use context

      implicit none

! local variables
      integer :: iw

      do iw=1, nw
          aw_model(iw) = one / ( sqrt(twopi) * sigma ) * exp( -(fmesh(iw)/sigma)**2 )
      enddo

      return
  end subroutine maxent_make_gauss_model

!===============================================================
! subroutine maxent_make_file_model generates a default model from
! file maxent.model.in
!===============================================================
  subroutine maxent_make_file_model()
      use constants
      use control
      use context

      implicit none

! local variables
      integer :: iw

! dummy variables
      real(dp) :: dummy

      logical :: exists

      exists = .false.
      inquire(file="maxent.model.in", exist = exists )
      if ( exists .eqv. .true. ) then ! file exitsts, read from it
          open(mytmp, file="maxent.model.in", form="formatted", status="unknown")
          do iw=1, nw
              read(mytmp,*) dummy, aw_model(iw)
          enddo
      else ! file doesn't exists
          call maxent_print_error("maxent_make_file_model", &
                          "file maxent.model.in doesn't exist") 
      endif ! back if (exists .eqv. .true.) block

      return
  end subroutine maxent_make_file_model
