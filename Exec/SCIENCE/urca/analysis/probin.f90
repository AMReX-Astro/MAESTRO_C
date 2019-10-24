! DO NOT EDIT THIS FILE!!!
!
! This file is automatically generated by write_probin.py at
! compile-time.
!
! To add a runtime parameter, do so by editting the appropriate _parameters
! file.

! This module stores the runtime parameters.  The probin_init() routine is
! used to initialize the runtime parameters

! this version is a stub -- useful for when we only need a container for 
! parameters, but not for MAESTRO use.

module probin_module

  use amrex_fort_module, only : rt => amrex_real

  implicit none

  private

  integer, save, public :: a_dummy_var = 0

#ifdef AMREX_USE_CUDA  
#endif

end module probin_module


module extern_probin_module

  use amrex_fort_module, only : rt => amrex_real

  implicit none

  private

  real (kind=rt), save, public :: small_x = 0.0
  !$acc declare create(small_x)
  logical, save, public :: use_eos_coulomb = .true.
  !$acc declare create(use_eos_coulomb)
  logical, save, public :: eos_input_is_constant = .true.
  !$acc declare create(eos_input_is_constant)
  real (kind=rt), save, public :: eos_ttol = 1.0d-8
  !$acc declare create(eos_ttol)
  real (kind=rt), save, public :: eos_dtol = 1.0d-8
  !$acc declare create(eos_dtol)
  logical, save, public :: disable_fermi_heating = .false.
  !$acc declare create(disable_fermi_heating)
  logical, save, public :: use_tables = .false.
  !$acc declare create(use_tables)
  logical, save, public :: use_c12ag_deboer17 = .false.
  !$acc declare create(use_c12ag_deboer17)
  integer, save, public :: ode_max_steps = 150000
  !$acc declare create(ode_max_steps)
  integer, save, public :: scaling_method = 2
  !$acc declare create(scaling_method)
  logical, save, public :: use_timestep_estimator = .false.
  !$acc declare create(use_timestep_estimator)
  real (kind=rt), save, public :: ode_scale_floor = 1.d-6
  !$acc declare create(ode_scale_floor)
  integer, save, public :: ode_method = 1
  !$acc declare create(ode_method)
  real (kind=rt), save, public :: safety_factor = 1.d9
  !$acc declare create(safety_factor)
  logical, save, public :: do_constant_volume_burn = .false.
  !$acc declare create(do_constant_volume_burn)
  logical, save, public :: call_eos_in_rhs = .false.
  !$acc declare create(call_eos_in_rhs)
  real (kind=rt), save, public :: dT_crit = 1.0d20
  !$acc declare create(dT_crit)
  integer, save, public :: burning_mode = 1
  !$acc declare create(burning_mode)
  real (kind=rt), save, public :: burning_mode_factor = 1.d-1
  !$acc declare create(burning_mode_factor)
  logical, save, public :: integrate_temperature = .true.
  !$acc declare create(integrate_temperature)
  logical, save, public :: integrate_energy = .true.
  !$acc declare create(integrate_energy)
  integer, save, public :: jacobian = 1
  !$acc declare create(jacobian)
  logical, save, public :: centered_diff_jac = .false.
  !$acc declare create(centered_diff_jac)
  logical, save, public :: burner_verbose = .false.
  !$acc declare create(burner_verbose)
  real (kind=rt), save, public :: rtol_spec = 1.d-12
  !$acc declare create(rtol_spec)
  real (kind=rt), save, public :: rtol_temp = 1.d-6
  !$acc declare create(rtol_temp)
  real (kind=rt), save, public :: rtol_enuc = 1.d-6
  !$acc declare create(rtol_enuc)
  real (kind=rt), save, public :: atol_spec = 1.d-12
  !$acc declare create(atol_spec)
  real (kind=rt), save, public :: atol_temp = 1.d-6
  !$acc declare create(atol_temp)
  real (kind=rt), save, public :: atol_enuc = 1.d-6
  !$acc declare create(atol_enuc)
  logical, save, public :: retry_burn = .false.
  !$acc declare create(retry_burn)
  real (kind=rt), save, public :: retry_burn_factor = 1.25d0
  !$acc declare create(retry_burn_factor)
  real (kind=rt), save, public :: retry_burn_max_change = 1.0d2
  !$acc declare create(retry_burn_max_change)
  logical, save, public :: abort_on_failure = .true.
  !$acc declare create(abort_on_failure)
  logical, save, public :: renormalize_abundances = .false.
  !$acc declare create(renormalize_abundances)
  real (kind=rt), save, public :: SMALL_X_SAFE = 1.0d-30
  !$acc declare create(SMALL_X_SAFE)
  real (kind=rt), save, public :: MAX_TEMP = 1.0d11
  !$acc declare create(MAX_TEMP)
  real (kind=rt), save, public :: react_boost = -1.d0
  !$acc declare create(react_boost)
  real (kind=rt), save, public :: reactions_density_scale = 1.d0
  !$acc declare create(reactions_density_scale)
  real (kind=rt), save, public :: reactions_temperature_scale = 1.d0
  !$acc declare create(reactions_temperature_scale)
  real (kind=rt), save, public :: reactions_energy_scale = 1.d0
  !$acc declare create(reactions_energy_scale)

#ifdef AMREX_USE_CUDA  
#endif

end module extern_probin_module


module runtime_init_module

  use amrex_error_module
  use amrex_fort_module, only : rt => amrex_real
  use probin_module
  use extern_probin_module

  implicit none

  namelist /probin/ small_x
  namelist /probin/ use_eos_coulomb
  namelist /probin/ eos_input_is_constant
  namelist /probin/ eos_ttol
  namelist /probin/ eos_dtol
  namelist /probin/ disable_fermi_heating
  namelist /probin/ use_tables
  namelist /probin/ use_c12ag_deboer17
  namelist /probin/ ode_max_steps
  namelist /probin/ scaling_method
  namelist /probin/ use_timestep_estimator
  namelist /probin/ ode_scale_floor
  namelist /probin/ ode_method
  namelist /probin/ safety_factor
  namelist /probin/ do_constant_volume_burn
  namelist /probin/ call_eos_in_rhs
  namelist /probin/ dT_crit
  namelist /probin/ burning_mode
  namelist /probin/ burning_mode_factor
  namelist /probin/ integrate_temperature
  namelist /probin/ integrate_energy
  namelist /probin/ jacobian
  namelist /probin/ centered_diff_jac
  namelist /probin/ burner_verbose
  namelist /probin/ rtol_spec
  namelist /probin/ rtol_temp
  namelist /probin/ rtol_enuc
  namelist /probin/ atol_spec
  namelist /probin/ atol_temp
  namelist /probin/ atol_enuc
  namelist /probin/ retry_burn
  namelist /probin/ retry_burn_factor
  namelist /probin/ retry_burn_max_change
  namelist /probin/ abort_on_failure
  namelist /probin/ renormalize_abundances
  namelist /probin/ SMALL_X_SAFE
  namelist /probin/ MAX_TEMP
  namelist /probin/ react_boost
  namelist /probin/ reactions_density_scale
  namelist /probin/ reactions_temperature_scale
  namelist /probin/ reactions_energy_scale

  private

  public :: probin

  public :: runtime_init, runtime_close, runtime_pretty_print

contains

  subroutine runtime_init(read_inputs_in)

    logical, intent(in), optional :: read_inputs_in

    integer :: farg, narg
    character(len=128) :: fname
    logical    :: lexist
    integer :: un

    logical :: read_inputs



    narg = command_argument_count()

    if (.not. present(read_inputs_in)) then
       read_inputs = .false.
    else
       read_inputs = read_inputs_in
    endif

    if (read_inputs) then
       farg = 1
       if ( narg >= 1 ) then
          call get_command_argument(farg, value = fname)
          inquire(file = fname, exist = lexist )
          if ( lexist ) then
             farg = farg + 1
             open(newunit=un, file = fname, status = 'old', action = 'read')
             read(unit=un, nml = probin)
             close(unit=un)
          else
             call amrex_error("ERROR: inputs file does not exist")
          endif
       else
          call amrex_error("ERROR: no inputs file specified")
       endif
    endif

    !$acc update &
    !$acc device(small_x, use_eos_coulomb, eos_input_is_constant) &
    !$acc device(eos_ttol, eos_dtol, disable_fermi_heating) &
    !$acc device(use_tables, use_c12ag_deboer17, ode_max_steps) &
    !$acc device(scaling_method, use_timestep_estimator, ode_scale_floor) &
    !$acc device(ode_method, safety_factor, do_constant_volume_burn) &
    !$acc device(call_eos_in_rhs, dT_crit, burning_mode) &
    !$acc device(burning_mode_factor, integrate_temperature, integrate_energy) &
    !$acc device(jacobian, centered_diff_jac, burner_verbose) &
    !$acc device(rtol_spec, rtol_temp, rtol_enuc) &
    !$acc device(atol_spec, atol_temp, atol_enuc) &
    !$acc device(retry_burn, retry_burn_factor, retry_burn_max_change) &
    !$acc device(abort_on_failure, renormalize_abundances, SMALL_X_SAFE) &
    !$acc device(MAX_TEMP, react_boost, reactions_density_scale) &
    !$acc device(reactions_temperature_scale, reactions_energy_scale)

  end subroutine runtime_init

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  subroutine runtime_close()

    use probin_module


  end subroutine runtime_close

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  subroutine runtime_pretty_print(unit)

    use amrex_constants_module
    use probin_module
    use extern_probin_module

    integer, intent(in) :: unit

    write (unit, *) "[*] indicates overridden default"

100 format (1x, a3, 2x, a32, 1x, "=", 1x, a)
101 format (1x, a3, 2x, a32, 1x, "=", 1x, i10)
102 format (1x, a3, 2x, a32, 1x, "=", 1x, g20.10)
103 format (1x, a3, 2x, a32, 1x, "=", 1x, l)
    write (unit,102) merge("   ", "[*]", small_x == 0.0), &
 "small_x", small_x
    write (unit,103) merge("   ", "[*]", use_eos_coulomb .eqv. .true.), &
 "use_eos_coulomb", use_eos_coulomb
    write (unit,103) merge("   ", "[*]", eos_input_is_constant .eqv. .true.), &
 "eos_input_is_constant", eos_input_is_constant
    write (unit,102) merge("   ", "[*]", eos_ttol == 1.0d-8), &
 "eos_ttol", eos_ttol
    write (unit,102) merge("   ", "[*]", eos_dtol == 1.0d-8), &
 "eos_dtol", eos_dtol
    write (unit,103) merge("   ", "[*]", disable_fermi_heating .eqv. .false.), &
 "disable_fermi_heating", disable_fermi_heating
    write (unit,103) merge("   ", "[*]", use_tables .eqv. .false.), &
 "use_tables", use_tables
    write (unit,103) merge("   ", "[*]", use_c12ag_deboer17 .eqv. .false.), &
 "use_c12ag_deboer17", use_c12ag_deboer17
    write (unit,101) merge("   ", "[*]", ode_max_steps == 150000), &
 "ode_max_steps", ode_max_steps
    write (unit,101) merge("   ", "[*]", scaling_method == 2), &
 "scaling_method", scaling_method
    write (unit,103) merge("   ", "[*]", use_timestep_estimator .eqv. .false.), &
 "use_timestep_estimator", use_timestep_estimator
    write (unit,102) merge("   ", "[*]", ode_scale_floor == 1.d-6), &
 "ode_scale_floor", ode_scale_floor
    write (unit,101) merge("   ", "[*]", ode_method == 1), &
 "ode_method", ode_method
    write (unit,102) merge("   ", "[*]", safety_factor == 1.d9), &
 "safety_factor", safety_factor
    write (unit,103) merge("   ", "[*]", do_constant_volume_burn .eqv. .false.), &
 "do_constant_volume_burn", do_constant_volume_burn
    write (unit,103) merge("   ", "[*]", call_eos_in_rhs .eqv. .false.), &
 "call_eos_in_rhs", call_eos_in_rhs
    write (unit,102) merge("   ", "[*]", dT_crit == 1.0d20), &
 "dT_crit", dT_crit
    write (unit,101) merge("   ", "[*]", burning_mode == 1), &
 "burning_mode", burning_mode
    write (unit,102) merge("   ", "[*]", burning_mode_factor == 1.d-1), &
 "burning_mode_factor", burning_mode_factor
    write (unit,103) merge("   ", "[*]", integrate_temperature .eqv. .true.), &
 "integrate_temperature", integrate_temperature
    write (unit,103) merge("   ", "[*]", integrate_energy .eqv. .true.), &
 "integrate_energy", integrate_energy
    write (unit,101) merge("   ", "[*]", jacobian == 1), &
 "jacobian", jacobian
    write (unit,103) merge("   ", "[*]", centered_diff_jac .eqv. .false.), &
 "centered_diff_jac", centered_diff_jac
    write (unit,103) merge("   ", "[*]", burner_verbose .eqv. .false.), &
 "burner_verbose", burner_verbose
    write (unit,102) merge("   ", "[*]", rtol_spec == 1.d-12), &
 "rtol_spec", rtol_spec
    write (unit,102) merge("   ", "[*]", rtol_temp == 1.d-6), &
 "rtol_temp", rtol_temp
    write (unit,102) merge("   ", "[*]", rtol_enuc == 1.d-6), &
 "rtol_enuc", rtol_enuc
    write (unit,102) merge("   ", "[*]", atol_spec == 1.d-12), &
 "atol_spec", atol_spec
    write (unit,102) merge("   ", "[*]", atol_temp == 1.d-6), &
 "atol_temp", atol_temp
    write (unit,102) merge("   ", "[*]", atol_enuc == 1.d-6), &
 "atol_enuc", atol_enuc
    write (unit,103) merge("   ", "[*]", retry_burn .eqv. .false.), &
 "retry_burn", retry_burn
    write (unit,102) merge("   ", "[*]", retry_burn_factor == 1.25d0), &
 "retry_burn_factor", retry_burn_factor
    write (unit,102) merge("   ", "[*]", retry_burn_max_change == 1.0d2), &
 "retry_burn_max_change", retry_burn_max_change
    write (unit,103) merge("   ", "[*]", abort_on_failure .eqv. .true.), &
 "abort_on_failure", abort_on_failure
    write (unit,103) merge("   ", "[*]", renormalize_abundances .eqv. .false.), &
 "renormalize_abundances", renormalize_abundances
    write (unit,102) merge("   ", "[*]", SMALL_X_SAFE == 1.0d-30), &
 "SMALL_X_SAFE", SMALL_X_SAFE
    write (unit,102) merge("   ", "[*]", MAX_TEMP == 1.0d11), &
 "MAX_TEMP", MAX_TEMP
    write (unit,102) merge("   ", "[*]", react_boost == -1.d0), &
 "react_boost", react_boost
    write (unit,102) merge("   ", "[*]", reactions_density_scale == 1.d0), &
 "reactions_density_scale", reactions_density_scale
    write (unit,102) merge("   ", "[*]", reactions_temperature_scale == 1.d0), &
 "reactions_temperature_scale", reactions_temperature_scale
    write (unit,102) merge("   ", "[*]", reactions_energy_scale == 1.d0), &
 "reactions_energy_scale", reactions_energy_scale

  end subroutine runtime_pretty_print


end module runtime_init_module