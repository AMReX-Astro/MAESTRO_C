
module initdata_module

  use amrex_error_module
  use amrex_mempool_module, only : bl_allocate, bl_deallocate
  use amrex_paralleldescriptor_module, only: parallel_IOProcessor => amrex_pd_ioprocessor
  use amrex_constants_module
  use network, only: nspec
  use amrex_fort_module, only : amrex_spacedim, amrex_random
  use base_state_geometry_module, only: nr_fine, max_radial_level
  use meth_params_module, only: nscal, rho_comp, rhoh_comp, temp_comp, spec_comp, pi_comp, &
       prob_lo, prob_hi
  use probin_module, only: vel_fuel
  use eos_module
  use eos_type_module
  use fill_3d_data_module, only: put_1d_array_on_cart_sphr

  implicit none

  private

contains

  subroutine initdata(lev, time, lo, hi, &
       scal, scal_lo, scal_hi, nc_s, &
       vel, vel_lo, vel_hi, nc_v, &
       s0_init, p0_init, dx) bind(C, name="initdata")

    integer         , intent(in   ) :: lev, lo(3), hi(3)
    integer         , intent(in   ) :: scal_lo(3), scal_hi(3), nc_s
    integer         , intent(in   ) :: vel_lo(3), vel_hi(3), nc_v
    double precision, intent(in   ) :: time
    double precision, intent(inout) :: scal(scal_lo(1):scal_hi(1), &
         scal_lo(2):scal_hi(2), &
         scal_lo(3):scal_hi(3), 1:nc_s)
    double precision, intent(inout) :: vel(vel_lo(1):vel_hi(1), &
         vel_lo(2):vel_hi(2), &
         vel_lo(3):vel_hi(3), 1:nc_v)
    double precision, intent(in   ) :: s0_init(0:max_radial_level,0:nr_fine-1,1:nscal)
    double precision, intent(in   ) :: p0_init(0:max_radial_level,0:nr_fine-1)
    double precision, intent(in   ) :: dx(3)

    integer          :: i,j,k,r

    ! set velocity to zero
    vel(lo(1):hi(1),lo(2):hi(2),lo(3):hi(3),1:nc_v) = 0.d0
    vel(lo(1):hi(1),lo(2):hi(2),lo(3):hi(3),2) = vel_fuel

    do k=lo(3),hi(3)
       do j=lo(2),hi(2)
          do i=lo(1),hi(1)

             if (amrex_spacedim .eq. 1) then
                r = i
             else if (amrex_spacedim .eq. 2) then
                r = j
             else if (amrex_spacedim .eq. 3) then
                r = k
             end if

             ! set scalars using s0
             scal(i,j,k,rho_comp)  = s0_init(lev,r,rho_comp)
             scal(i,j,k,rhoh_comp) = s0_init(lev,r,rhoh_comp)
             scal(i,j,k,temp_comp) = s0_init(lev,r,temp_comp)
             scal(i,j,k,spec_comp:spec_comp+nspec-1) = &
                  s0_init(lev,r,spec_comp:spec_comp+nspec-1)

             ! initialize pi to zero for now
             scal(i,j,k,pi_comp) = 0.d0

          end do
       end do
    end do

  end subroutine initdata

  subroutine initdata_sphr(time, lo, hi, &
       scal, scal_lo, scal_hi, nc_s, &
       vel, vel_lo, vel_hi, nc_v, &
       s0_init, p0_init, &
       dx, r_cc_loc, r_edge_loc, &
       cc_to_r, ccr_lo, ccr_hi) bind(C, name="initdata_sphr")

    integer         , intent(in   ) :: lo(3), hi(3)
    integer         , intent(in   ) :: scal_lo(3), scal_hi(3), nc_s
    integer         , intent(in   ) :: vel_lo(3), vel_hi(3), nc_v
    integer         , intent(in   ) :: ccr_lo(3), ccr_hi(3)
    double precision, intent(in   ) :: time
    double precision, intent(inout) :: scal(scal_lo(1):scal_hi(1), &
         scal_lo(2):scal_hi(2), &
         scal_lo(3):scal_hi(3), nc_s)
    double precision, intent(inout) :: vel(vel_lo(1):vel_hi(1), &
         vel_lo(2):vel_hi(2), &
         vel_lo(3):vel_hi(3), nc_v)
    double precision, intent(in   ) :: s0_init(0:max_radial_level,0:nr_fine-1,1:nscal)
    double precision, intent(in   ) :: p0_init(0:max_radial_level,0:nr_fine-1)
    double precision, intent(in   ) :: dx(3)
    double precision, intent(in   ) :: r_cc_loc  (0:max_radial_level,0:nr_fine-1)
    double precision, intent(in   ) :: r_edge_loc(0:max_radial_level,0:nr_fine)
    double precision, intent(in   ) :: cc_to_r   (ccr_lo(1):ccr_hi(1), &
         ccr_lo(2):ccr_hi(2),ccr_lo(3):ccr_hi(3))

    !     Local variables
    integer          :: i,j,k,comp
    double precision, pointer :: p0_cart(:,:,:,:)

    type (eos_t) :: eos_state
    integer :: pt_index(3)

    double precision :: rand

    ! random numbers between -1 and 1
    double precision :: alpha(3,3,3), beta(3,3,3), gamma(3,3,3)

    ! random numbers between 0 and 2*pi
    double precision :: phix(3,3,3), phiy(3,3,3), phiz(3,3,3)

    ! L2 norm of k
    double precision :: normk(3,3,3)

    integer :: iloc, jloc, kloc

    ! cos and sin of (2*pi*kx/L + phix), etc
    double precision :: cx(3,3,3), cy(3,3,3), cz(3,3,3)
    double precision :: sx(3,3,3), sy(3,3,3), sz(3,3,3)

    ! location of center of star
    double precision :: xc(3)

    ! radius, or distance, to center of star
    double precision :: rloc

    ! the point we're at
    double precision :: xloc(3)

    ! perturbational velocity to add
    double precision :: vpert(3)


    ! initialize the domain with the base state
    scal(lo(1):hi(1),lo(2):hi(2),lo(3):hi(3),1:nc_s) = 0.d0

    ! if we are spherical, we want to make sure that p0 is good, since that is
    ! what is needed for HSE.  Therefore, we will put p0 onto a cart array and
    ! then initialize h from rho, X, and p0.
    call bl_allocate(p0_cart,lo,hi,1)

    ! initialize temp
    call put_1d_array_on_cart_sphr(lo,hi,scal(:,:,:,temp_comp),scal_lo,scal_hi,1, &
         s0_init(0,:,temp_comp),dx,0,0,r_cc_loc,r_edge_loc, &
         cc_to_r,ccr_lo,ccr_hi)

    ! initialize p0_cart
    call put_1d_array_on_cart_sphr(lo,hi,p0_cart,lo,hi,1,p0_init,dx,0,0,r_cc_loc,r_edge_loc, &
         cc_to_r,ccr_lo,ccr_hi)

    ! initialize species
    do comp = spec_comp, spec_comp+nspec-1
       call put_1d_array_on_cart_sphr(lo,hi,scal(:,:,:,comp),scal_lo,scal_hi,1, &
            s0_init(0,:,comp),dx,0,0,r_cc_loc,r_edge_loc, &
            cc_to_r,ccr_lo,ccr_hi)
    end do

    ! initialize rho as sum of partial densities rho*X_i
    do k = lo(3), hi(3)
       do j = lo(2), hi(2)
          do i = lo(1), hi(1)
             scal(i,j,k,rho_comp) = 0.d0
             do comp = spec_comp, spec_comp+nspec-1
                scal(i,j,k,rho_comp) = scal(i,j,k,rho_comp) + scal(i,j,k,comp)
             enddo
          enddo
       enddo
    enddo

    ! initialize (rho h) and T using the EOS
    do k = lo(3), hi(3)
       do j = lo(2), hi(2)
          do i = lo(1), hi(1)

             eos_state%T     = scal(i,j,k,temp_comp)
             eos_state%p     = p0_cart(i,j,k,1)
             eos_state%rho   = scal(i,j,k,rho_comp)
             eos_state%xn(:) = scal(i,j,k,spec_comp:spec_comp+nspec-1)/eos_state%rho

             pt_index = (/ i, j, k /)

             call eos(eos_input_rp, eos_state, pt_index)

             scal(i,j,k,rhoh_comp) = eos_state%rho*eos_state%h
             scal(i,j,k,temp_comp) = eos_state%T

          enddo
       enddo
    enddo

    call bl_deallocate(p0_cart)

    ! initialize the velocity to zero everywhere
    vel(lo(1):hi(1),lo(2):hi(2),lo(3):hi(3),1:nc_v) = 0.d0

  end subroutine initdata_sphr

end module initdata_module
