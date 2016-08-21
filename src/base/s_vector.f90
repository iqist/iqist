!!!-----------------------------------------------------------------------
!!! project : CSSL (Common Service Subroutines Library)
!!! program : s_linspace_d
!!!           s_logspace_d
!!!           s_linspace_z
!!!           s_sum_i
!!!           s_sum_d
!!1           s_sum_z
!!!           s_cumsum_i
!!!           s_cumsum_d
!!!           s_cumsum_z
!!!           s_prod_i
!!!           s_prod_d
!!!           s_prod_z
!!!           s_cumprod_i
!!!           s_cumprod_d
!!!           s_cumprod_z
!!!           s_swap_i
!!!           s_swap_d
!!!           s_swap_z
!!!           s_mix_i
!!!           s_mix_d
!!!           s_mix_z
!!!           s_legendre
!!!           s_chebyshev
!!!           s_sbessel
!!!           s_bezier
!!! source  : s_vector.f90
!!! type    : subroutines
!!! author  : li huang (email:lihuang.dmft@gmail.com)
!!! history : 07/10/2014 by li huang (created)
!!!           08/17/2015 by li huang (last modified)
!!! purpose : these subroutines are designed for vectors or arrays. They
!!!           can be used to manipulate grid and mesh, to generate the
!!!           Legendre polynomial and Chebyshev polynomial, etc.
!!! status  : unstable
!!! comment :
!!!-----------------------------------------------------------------------

!!
!!
!! Introduction
!! ============
!!
!! 1. mesh generation
!! ------------------
!!
!! subroutine s_linspace_d(...)
!! subroutine s_logspace_d(...)
!! subroutine s_linspace_z(...)
!!
!! 2. sum of vector
!! ----------------
!!
!! subroutine s_sum_i(...)
!! subroutine s_sum_d(...)
!! subroutine s_sum_z(...)
!!
!! subroutine s_cumsum_i(...)
!! subroutine s_cumsum_d(...)
!! subroutine s_cumsum_z(...)
!!
!! 3. product of vector
!! --------------------
!!
!! subroutine s_prod_i(...)
!! subroutine s_prod_d(...)
!! subroutine s_prod_z(...)
!!
!! subroutine s_cumprod_i(...)
!! subroutine s_cumprod_d(...)
!! subroutine s_cumprod_z(...)
!!
!! 4. swap two vectors
!! -------------------
!!
!! subroutine s_swap_i(...)
!! subroutine s_swap_d(...)
!! subroutine s_swap_z(...)
!!
!! 5. linear mixing for vectors
!! ----------------------------
!!
!! subroutine s_mix_i(...)
!! subroutine s_mix_d(...)
!! subroutine s_mix_z(...)
!!
!! 6. orthogonal polynomial
!! ------------------------
!!
!! subroutine s_legendre(...)
!! subroutine s_chebyshev(...)
!!
!! 7. spheric Bessel function
!! --------------------------
!!
!! subroutine s_sbessel(...)
!!
!! 8. bernstein polynomial
!! -----------------------
!!
!! subroutine s_bezier(...)
!!
!!

!!========================================================================
!!>>> mesh generation                                                  <<<
!!========================================================================

!!>>> s_linspace_d: create a linear mesh x in interval [xmin, xmax], real(dp) version
  subroutine s_linspace_d(xmin, xmax, n, x)
     use constants, only : dp

     implicit none

! external arguments
! left boundary
     real(dp), intent(in)  :: xmin

! right boundary
     real(dp), intent(in)  :: xmax

! size of array x
     integer,  intent(in)  :: n

! output array, containing the linear mesh
     real(dp), intent(out) :: x(n)

! local variables
! loop index
     integer :: i

     do i=1,n
         x(i) = ( xmax - xmin ) * real(i - 1, dp) / real(n - 1, dp) + xmin
     enddo ! over i={1,n} loop

     return
  end subroutine s_linspace_d

!!>>> s_logspace_d: create a log mesh x in interval [xmin, xmax], real(dp) version
  subroutine s_logspace_d(xmin, xmax, n, x)
     use constants, only : dp

     implicit none

! external arguments
! left boundary
     real(dp), intent(in)  :: xmin

! right boundary
     real(dp), intent(in)  :: xmax

! size of array x
     integer,  intent(in)  :: n

! output array, containing the linear mesh
     real(dp), intent(out) :: x(n)

! we can use the s_linspace_d() subroutine
     call s_linspace_d(log10(xmin), log10(xmax), n, x)
     x = 10.0_dp**x

     return
  end subroutine s_logspace_d

!!>>> s_linspace_z: create a linear mesh x in interval [xmin, xmax], complex(dp) version
  subroutine s_linspace_z(xmin, xmax, n, x)
     use constants, only : dp

     implicit none

! external arguments
! left boundary
     complex(dp), intent(in)  :: xmin

! right boundary
     complex(dp), intent(in)  :: xmax

! size of array x
     integer,  intent(in)     :: n

! output array, containing the linear mesh
     complex(dp), intent(out) :: x(n)

! local variables
! loop index
     integer :: i

     do i=1,n
         x(i) = ( xmax - xmin ) * real(i - 1, dp) / real(n - 1, dp) + xmin
     enddo ! over i={1,n} loop

     return
  end subroutine s_linspace_z

!!========================================================================
!!>>> sum operations                                                   <<<
!!========================================================================

!!>>> s_sum_i: return the sum of an integer array
  subroutine s_sum_i(n, v, vsum)
     implicit none

! external arguments
! size of array v
     integer, intent(in)  :: n

! sum of array v
     integer, intent(out) :: vsum

! input integer array
     integer, intent(in)  :: v(n)

     vsum = sum(v)

     return
  end subroutine s_sum_i

!!>>> s_sum_d: return the sum of a real(dp) array
  subroutine s_sum_d(n, v, vsum)
     use constants, only : dp

     implicit none

! external arguments
! size of array v
     integer, intent(in)   :: n

! sum of array v
     real(dp), intent(out) :: vsum

! input real(dp) array
     real(dp), intent(in)  :: v(n)

     vsum = sum(v)

     return
  end subroutine s_sum_d

!!>>> s_sum_z: return the sum of a complex(dp) array
  subroutine s_sum_z(n, v, vsum)
     use constants, only : dp

     implicit none

! external arguments
! size of array v
     integer, intent(in)      :: n

! sum of array v
     complex(dp), intent(out) :: vsum

! input complex(dp) array
     complex(dp), intent(in)  :: v(n)

     vsum = sum(v)

     return
  end subroutine s_sum_z

!!>>> s_cumsum_i: return the cumsum of an integer array
  subroutine s_cumsum_i(n, v, vsum)
     implicit none

! external arguments
! size of array v
     integer, intent(in)  :: n

! input integer array
     integer, intent(in)  :: v(n)

! cumsum of array v
     integer, intent(out) :: vsum(n)

! local variables
! loop index
     integer :: i

     vsum(1) = v(1)
     do i=2,n
         vsum(i) = vsum(i-1) + v(i)
     enddo ! over i={2,n} loop

     return
  end subroutine s_cumsum_i

!!>>> s_cumsum_d: return the cumsum of a real(dp) array
  subroutine s_cumsum_d(n, v, vsum)
     use constants, only : dp

     implicit none

! external arguments
! size of array v
     integer, intent(in)   :: n

! input real(dp) array
     real(dp), intent(in)  :: v(n)

! cumsum of array v
     real(dp), intent(out) :: vsum(n)

! local variables
! loop index
     integer :: i

     vsum(1) = v(1)
     do i=2,n
         vsum(i) = vsum(i-1) + v(i)
     enddo ! over i={2,n} loop

     return
  end subroutine s_cumsum_d

!!>>> s_cumsum_z: return the cumsum of a complex(dp) array
  subroutine s_cumsum_z(n, v, vsum)
     use constants, only : dp

     implicit none

! external arguments
! size of array v
     integer, intent(in)      :: n

! input complex(dp) array
     complex(dp), intent(in)  :: v(n)

! cumsum of array v
     complex(dp), intent(out) :: vsum(n)

! local variables
! loop index
     integer :: i

     vsum(1) = v(1)
     do i=2,n
         vsum(i) = vsum(i-1) + v(i)
     enddo ! over i={2,n} loop

     return
  end subroutine s_cumsum_z

!!========================================================================
!!>>> prod operations                                                  <<<
!!========================================================================

!!>>> s_prod_i: return the product of an integer array
  subroutine s_prod_i(n, v, vprod)
     implicit none

! external arguments
! size of array v
     integer, intent(in)  :: n

! product of array v
     integer, intent(out) :: vprod

! input integer array
     integer, intent(in)  :: v(n)

     vprod = product(v)

     return
  end subroutine s_prod_i

!!>>> s_prod_d: return the product of a real(dp) array
  subroutine s_prod_d(n, v, vprod)
     use constants, only : dp

     implicit none

! external arguments
! size of array v
     integer, intent(in)   :: n

! product of array v
     real(dp), intent(out) :: vprod

! input real(dp) array
     real(dp), intent(in)  :: v(n)

     vprod = product(v)

     return
  end subroutine s_prod_d

!!>>> s_prod_z: return the product of a complex(dp) array
  subroutine s_prod_z(n, v, vprod)
     use constants, only : dp

     implicit none

! external arguments
! size of array v
     integer, intent(in)      :: n

! product of array v
     complex(dp), intent(out) :: vprod

! input complex(dp) array
     complex(dp), intent(in)  :: v(n)

     vprod = product(v)

     return
  end subroutine s_prod_z

!!>>> s_cumprod_i: return the cumproduct of an integer array
  subroutine s_cumprod_i(n, v, vprod)
     implicit none

! external arguments
! size of array v
     integer, intent(in)  :: n

! input integer array
     integer, intent(in)  :: v(n)

! cumproduct of array v
     integer, intent(out) :: vprod(n)

! local variables
! loop index
     integer :: i

     vprod(1) = v(1)
     do i=2,n
         vprod(i) = vprod(i-1) * v(i)
     enddo ! over i={2,n} loop

     return
  end subroutine s_cumprod_i

!!>>> s_cumprod_d: return the cumproduct of a real(dp) array
  subroutine s_cumprod_d(n, v, vprod)
     use constants, only : dp

     implicit none

! external arguments
! size of array v
     integer, intent(in)   :: n

! input real(dp) array
     real(dp), intent(in)  :: v(n)

! cumproduct of array v
     real(dp), intent(out) :: vprod(n)

! local variables
! loop index
     integer :: i

     vprod(1) = v(1)
     do i=2,n
         vprod(i) = vprod(i-1) * v(i)
     enddo ! over i={2,n} loop

     return
  end subroutine s_cumprod_d

!!>>> s_cumprod_z: return the cumproduct of a complex(dp) array
  subroutine s_cumprod_z(n, v, vprod)
     use constants, only : dp

     implicit none

! external arguments
! size of array v
     integer, intent(in)      :: n

! input complex(dp) array
     complex(dp), intent(in)  :: v(n)

! cumproduct of array v
     complex(dp), intent(out) :: vprod(n)

! local variables
! loop index
     integer :: i

     vprod(1) = v(1)
     do i=2,n
         vprod(i) = vprod(i-1) * v(i)
     enddo ! over i={2,n} loop

     return
  end subroutine s_cumprod_z

!!========================================================================
!!>>> swap operations                                                  <<<
!!========================================================================

!!>>> s_swap_i: exchange two integer vectors
  subroutine s_swap_i(n, ix, iy)
     implicit none

! external arguments
! dimension of integer vector
     integer, intent(in)    :: n

! integer vector X
     integer, intent(inout) :: ix(n)

! integer vector Y
     integer, intent(inout) :: iy(n)

! local variables
! dummy integer vector
     integer :: it(n)

     it = ix
     ix = iy
     iy = it

     return
  end subroutine s_swap_i

!!>>> s_swap_d: exchange two real(dp) vectors
  subroutine s_swap_d(n, dx, dy)
     use constants, only : dp

     implicit none

! external arguments
! dimension of real(dp) vector
     integer, intent(in)     :: n

! real(dp) vector X
     real(dp), intent(inout) :: dx(n)

! real(dp) vector Y
     real(dp), intent(inout) :: dy(n)

! local variables
! dummy real(dp) vector
     real(dp) :: dt(n)

     dt = dx
     dx = dy
     dy = dt

     return
  end subroutine s_swap_d

!!>>> s_swap_z: exchange two complex(dp) vectors
  subroutine s_swap_z(n, zx, zy)
     use constants, only : dp

     implicit none

! external arguments
! dimension of complex(dp) vector
     integer, intent(in)        :: n

! complex(dp) vector X
     complex(dp), intent(inout) :: zx(n)

! complex(dp) vector Y
     complex(dp), intent(inout) :: zy(n)

! local variables
! dummy complex(dp) vector
     complex(dp) :: zt(n)

     zt = zx
     zx = zy
     zy = zt

     return
  end subroutine s_swap_z

!!========================================================================
!!>>> mix operations                                                   <<<
!!========================================================================

!!>>> s_mix_i: linear mixing for two integer vectors
  subroutine s_mix_i(n, ix, iy, alpha)
     use constants, only : dp, one

     implicit none

! external arguments
! dimension of integer vector
     integer, intent(in)    :: n

! mixing parameter
     real(dp), intent(in)   :: alpha

! integer vector X
     integer, intent(in)    :: ix(n)

! integer vector Y
     integer, intent(inout) :: iy(n)

     iy = int( real(ix) * (one - alpha) + real(iy) * alpha )

     return
  end subroutine s_mix_i

!!>>> s_mix_d: linear mixing for two real(dp) vectors
  subroutine s_mix_d(n, dx, dy, alpha)
     use constants, only : dp, one

     implicit none

! external arguments
! dimension of real(dp) vector
     integer, intent(in)     :: n

! mixing parameter
     real(dp), intent(in)    :: alpha

! real(dp) vector X
     real(dp), intent(in)    :: dx(n)

! real(dp) vector Y
     real(dp), intent(inout) :: dy(n)

     dy = dx * (one - alpha) + dy * alpha

     return
  end subroutine s_mix_d

!!>>> s_mix_z: linear mixing for two complex(dp) vectors
  subroutine s_mix_z(n, zx, zy, alpha)
     use constants, only : dp, one

     implicit none

! external arguments
! dimension of complex(dp) vector
     integer, intent(in)        :: n

! mixing parameter
     real(dp), intent(in)       :: alpha

! complex(dp) vector X
     complex(dp), intent(in)    :: zx(n)

! complex(dp) vector Y
     complex(dp), intent(inout) :: zy(n)

     zy = zx * (one - alpha) + zy * alpha

     return
  end subroutine s_mix_z

!!========================================================================
!!>>> Legendre and Chebyshev polynomials                               <<<
!!========================================================================

!!>>> s_legendre: build legendre polynomial in [-1,1]
  subroutine s_legendre(lemax, legrd, pmesh, ppleg)
     use constants, only : dp, one

     implicit none

! external arguments
! maximum order for legendre polynomial
     integer, intent(in)   :: lemax

! number of mesh points for legendre polynomial
     integer, intent(in)   :: legrd

! mesh for legendre polynomial in [-1,1]
     real(dp), intent(in)  :: pmesh(legrd)

! legendre polynomial defined on [-1,1]
     real(dp), intent(out) :: ppleg(legrd,lemax)

! local variables
! loop index
     integer :: i
     integer :: j
     integer :: k

! check lemax
     if ( lemax <= 2 ) then
         call s_print_error('s_legendre','lemax must be larger than 2')
     endif ! back if ( lemax <= 2 ) block

! the legendre polynomials obey the three term recurrence relation known
! as Bonnet’s recursion formula:
!     $P_0(x) = 1$
!     $P_1(x) = x$
!     $(n+1) P_{n+1}(x) = (2n+1) P_n(x) - n P_{n-1}(x)$
     do i=1,legrd
         ppleg(i,1) = one
         ppleg(i,2) = pmesh(i)
         do j=3,lemax
             k = j - 1
             ppleg(i,j) = ( real(2*k-1) * pmesh(i) * ppleg(i,j-1) - real(k-1) * ppleg(i,j-2) ) / real(k)
         enddo ! over j={3,lemax} loop
     enddo ! over i={1,legrd} loop

     return
  end subroutine s_legendre

!!>>> s_chebyshev: build chebyshev polynomial in [-1,1]
!!>>> note: it is the second kind chebyshev polynomial
  subroutine s_chebyshev(chmax, chgrd, qmesh, qqche)
     use constants, only : dp, one, two

     implicit none

! external arguments
! maximum order for chebyshev polynomial
     integer, intent(in)   :: chmax

! number of mesh points for chebyshev polynomial
     integer, intent(in)   :: chgrd

! mesh for chebyshev polynomial in [-1,1]
     real(dp), intent(in)  :: qmesh(chgrd)

! chebyshev polynomial defined on [-1,1]
     real(dp), intent(out) :: qqche(chgrd, chmax)

! local variables
! loop index
     integer :: i
     integer :: j

! check chmax
     if ( chmax <= 2 ) then
         call s_print_error('s_chebyshev','chmax must be larger than 2')
     endif ! back if ( chmax <= 2 ) block

! the chebyshev polynomials of the second kind can be defined by the
! following recurrence relation
!     $U_0(x) = 1$
!     $U_1(x) = 2x$
!     $U_{n+1}(x) = 2xU_n(x) - U_{n-1}(x)$
     do i=1,chgrd
         qqche(i,1) = one
         qqche(i,2) = two * qmesh(i)
         do j=3,chmax
             qqche(i,j) = two * qmesh(i) * qqche(i,j-1) - qqche(i,j-2)
         enddo ! over j={3,chmax} loop
     enddo ! over i={1,chgrd} loop

     return
  end subroutine s_chebyshev

!!========================================================================
!!>>> spherical Bessel functions                                       <<<
!!========================================================================

!!>>> s_sbessel: computes the spherical Bessel functions of the first
!!>>> kind, j_l(x), for argument x and l=0,1,\ldots,l_{max}.
  subroutine s_sbessel(lmax, x, jl)
     use constants, only : dp, zero, one, two, eps8

     implicit none

! external arguments
! maximum order of spherical Bessel function
     integer, intent(in)   :: lmax

! real argument
     real(dp), intent(in)  :: x

! array of returned values
     real(dp), intent(out) :: jl(0:lmax)

! local parameters
! staring value for l above lmax (suitable for lmax < 50)
     integer, parameter  :: lst  = 25

! rescale limit
     real(dp), parameter :: rsc  = 1.0D100
     real(dp), parameter :: rsci = one / rsc

! local variables
! loop index
     integer  :: l

! real(dp) dummy variables
     real(dp) :: xi, jt
     real(dp) :: j0, j1
     real(dp) :: t1, t2

! important note: the recursion relation
!     j_{l+1}(x)=\frac{2l+1}{x}j_l(x)-j_{l-1}(x)
! is used either downwards for x < l or upwards for x >= l. for x << 1,
! the asymtotic form is used:
!     j_l(x) \approx \frac{x^l}{(2l+1)!!}
! this procedure is numerically stable and accurate to near this machine
! precision for l <= 50

! check the range of input variables
     if ( lmax < 0 .or. lmax > 50 ) then
         call s_print_error('s_sbessel','lmax is out of range')
     endif ! back if ( lmax < 0 .or. lmax > 50 ) block

     if ( x < zero .or. x > 1.0E5 ) then
         call s_print_error('s_sbessel','x is out of range')
     endif ! back if ( x < zero .or. x > 1.0E5 ) block

! treat x << 1
     if ( x < eps8 ) then
         jl(0) = one
         t1 = one; t2 = one
         do l=1,lmax
             t1 = t1 / (two * l + one)
             t2 = t2 * x
             jl(l) = t2 * t1
         enddo ! over l={1,lmax} loop
         RETURN
     endif ! back if ( x < eps8 ) block

     xi = one / x

! for x < lmax recurse down
     if ( x < lmax ) then
         if ( lmax == 0 ) then
             jl(0) = sin(x) / x; RETURN
         endif ! back if ( lmax == 0 ) block

! start from truly random numbers
         j0 = 0.6370354636449841609d0 * rsci
         j1 = 0.3532702964695481204d0 * rsci
         do l=lmax+lst,lmax+1,-1
             jt = j0 * (two * l + one) * xi - j1
             j1 = j0
             j0 = jt
! check for overflow
             if ( abs(j0) > rsc ) then
! rescale
                 jt = jt * rsci
                 j1 = j1 * rsci
                 j0 = j0 * rsci
             endif ! back if ( abs(j0) > rsc ) block
         enddo ! over l={lmax+lst,lmax+1} loop

         do l=lmax,0,-1
             jt = j0 * (two * l + one) * xi - j1
             j1 = j0
             j0 = jt
! check for overflow
             if ( abs(j0) > rsc ) then
! rescale
                 jt = jt * rsci
                 j1 = j1 * rsci
                 j0 = j0 * rsci
                 jl(l+1:lmax) = jl(l+1:lmax) * rsci
             endif ! back if ( abs(j0) > rsc ) block
             jl(l) = j1
         enddo ! over l={lmax,0} loop
! rescaling constant
         t1 = one / ( ( jl(0) - x * jl(1) ) * cos(x) + x * jl(0) * sin(x) )
         jl = t1 * jl
     else
! for large x recurse up
         jl(0) = sin(x) * xi
         if ( lmax == 0 ) RETURN
         jl(1) = ( jl(0) - cos(x) ) * xi
         if ( lmax == 1 ) RETURN
         j0 = jl(0)
         j1 = jl(1)
         do l=2,lmax
             jt = (two * l - one ) * j1 * xi - j0
             j0 = j1
             j1 = jt
             jl(l) = j1
         enddo ! over l={2,lmax} loop
     endif ! back if ( x < lmax ) block

     return
  end subroutine s_sbessel

!!========================================================================
!!>>> Bernstein polynomials                                            <<<
!!========================================================================

!!>>> s_bezier: to evaluates the bernstein polynomials at a point x
  subroutine s_bezier(n, x, bern)
     use constants, only : dp, one

     implicit none

! external arguments
! the degree of the bernstein polynomials to be used. for any N, there
! is a set of N+1 bernstein polynomials, each of degree N, which form a
! basis for polynomials on [0,1].
     integer, intent(in)  :: n

! the evaluation point.
     real(dp), intent(in) :: x

! the values of the N+1 bernstein polynomials at X
     real(dp), intent(inout) :: bern(0:n)

! local variables
! loop index
     integer :: i
     integer :: j

! the bernstein polynomials are assumed to be based on [0,1].
! the formula is:
!
!    B(N,I)(X) = [N!/(I!*(N-I)!)] * (1-X)**(N-I) * X**I
!
! first values:
!
!    B(0,0)(X) = 1
!    B(1,0)(X) =      1-X
!    B(1,1)(X) =                X
!    B(2,0)(X) =     (1-X)**2
!    B(2,1)(X) = 2 * (1-X)    * X
!    B(2,2)(X) =                X**2
!    B(3,0)(X) =     (1-X)**3
!    B(3,1)(X) = 3 * (1-X)**2 * X
!    B(3,2)(X) = 3 * (1-X)    * X**2
!    B(3,3)(X) =                X**3
!    B(4,0)(X) =     (1-X)**4
!    B(4,1)(X) = 4 * (1-X)**3 * X
!    B(4,2)(X) = 6 * (1-X)**2 * X**2
!    B(4,3)(X) = 4 * (1-X)    * X**3
!    B(4,4)(X) =                X**4
!
! special values:
!
!    B(N,I)(X) has a unique maximum value at X = I/N.
!    B(N,I)(X) has an I-fold zero at 0 and and N-I fold zero at 1.
!    B(N,I)(1/2) = C(N,K) / 2**N
!    for a fixed X and N, the polynomials add up to 1:
!    sum ( 0 <= I <= N ) B(N,I)(X) = 1
!
     if ( n == 0 ) then
         bern(0) = one

     else if ( 0 < n ) then
         bern(0) = one - x
         bern(1) = x
         do i=2,n
             bern(i) = x * bern(i-1)
             do j=i-1,1,-1
                 bern(j) = x * bern(j-1) + ( one - x ) * bern(j)
             enddo ! over j={i-1,1} loop
             bern(0) = ( one - x ) * bern(0)
         enddo ! over i={2,n} loop

     endif ! back if ( n == 0 ) block

     return
  end subroutine s_bezier
