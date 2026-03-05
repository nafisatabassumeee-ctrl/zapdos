# dom0Scale = 1.0

[GlobalParams]
  potential_units = V
  use_moles = true
[]

[Mesh]
  # Mesh or Previous Output file: Need to change for continued runs
  [fmg]
    type = FileMeshGenerator
    file = NCSU_chamber-edits-WO-lid-sepWalls.msh
  []

  [interface]
    type = SideSetsBetweenSubdomainsGenerator
    primary_block = 'Ceramic'
    paired_block = 'Plasma'
    new_boundary = 'ceramic_side'
    input = fmg
  []
  [interface_again]
    type = SideSetsBetweenSubdomainsGenerator
    primary_block = 'Plasma'
    paired_block = 'Ceramic'
    new_boundary = 'plasma_side'
    input = interface
  []
  second_order = true
  coord_type = RZ
  rz_coord_axis = Y
[]

[Problem]
  type = FEProblem
[]

[Variables]
  [Dummy]
    block = 'Resonator_Pin Ceramic'
  []

  [Ar*]
    block = Plasma
  []
[]

[AuxVariables]
  [Ar*S]
    block = Plasma
  []
  [Ar*T]
    block = Plasma
  []

  [SM_Ar*]
    block = Plasma
  []
  [SM_Ar*Reset]
    initial_condition = 1.0
    block = Plasma
  []

  [Residual]
    block = Plasma
  []
[]

[Kernels]
  # Dummy varible in the pinand ceramic to keep the mesh the same between
  # plasma and EM solves
  [Dummy]
    type = NullKernel
    variable = Dummy
    block = 'Resonator_Pin Ceramic'
  []

  ##################################################################

  [Shoot_Method]
    type = ShootMethodLog
    variable = Ar*
    density_at_start_cycle = Ar*S
    density_at_end_cycle = Ar*T
    sensitivity_variable = SM_Ar*
    growth_limit = 100
    block = Plasma
  []
[]

[AuxKernels]
  [Constant_SM_Ar*Reset]
    type = ConstantAux
    variable = SM_Ar*Reset
    value = 1.0
    execute_on = 'TIMESTEP_BEGIN'
    block = Plasma
  []

  [Residual]
    type = DebugResidualAux
    variable = Residual
    debug_variable = Ar*
  []
[]

[BCs]
  [Ar*_physical_left_diffusion]
    # type = LogDensityDirichletBC
    # variable = Ar*
    # # boundary = 'chamber_walls plasma_side'
    # boundary = 'chamber_walls'
    # value = 100
    type = PenaltyDirichletBC
    variable = Ar*
    # boundary = 'chamber_walls plasma_side'
    boundary = 'chamber_walls'
    value = -50
    penalty = 1
  []
  # [Ar*_do_nothing]
  #   type = DriftDiffusionDoNothingBC
  #   variable = Ar*
  #   mu = 0
  #   diff = 0
  #   sign = 0
  #   use_material_props = true
  #   # boundary = 'chamber_bottom'
  #   boundary = 'chamber_bottom plasma_side'
  #   position_units = ${dom0Scale}
  # []
  [Ar*_do_nothing]
    type = ADPenaltyShootingMethodBC
    variable = Ar*
    density_at_start_cycle = Ar*S
    density_at_end_cycle = Ar*T
    sensitivity_variable = SM_Ar*
    growth_limit = 100
    # boundary = 'chamber_bottom plasma_side'
    boundary = 'chamber_bottom plasma_side'
  []
[]

[Materials]
  [Pin_Basic]
    type = GasElectronMoments
    interp_trans_coeffs = false
    interp_elastic_coeff = false
    ramp_trans_coeffs = false

    # Pressure dependent coefficents default 1 Torr: Need to change during pressure sweep
    user_p_gas = 26.665
    user_drive_freq = 2.45e9

    user_T_gas = 300
    property_tables_file = electron_moments.txt
    block = Resonator_Pin
  []
  [Ceramic_Basic]
    type = GasElectronMoments
    interp_trans_coeffs = false
    interp_elastic_coeff = false
    ramp_trans_coeffs = false

    # Pressure dependent coefficents default 1 Torr: Need to change during pressure sweep
    user_p_gas = 26.665
    user_drive_freq = 2.45e9

    user_T_gas = 300
    property_tables_file = electron_moments.txt
    block = Ceramic
  []
  [Plasma_Basic]
    type = GasElectronMoments
    interp_trans_coeffs = true
    interp_elastic_coeff = false
    ramp_trans_coeffs = false

    # Pressure dependent coefficents default 1 Torr: Need to change during pressure sweep
    user_p_gas = 26.665
    user_drive_freq = 2.45e9
    pressure_dependent_electron_coeff = true

    user_T_gas = 300
    em = -20
    mean_en = -22
    property_tables_file = electron_moments.txt
    block = Plasma
  []

  [field_solver]
    type = FieldSolverMaterial
    # potential = potential
    # solver = electrostatic
    electric_field = 5
    solver = electromagnetic
    block = Plasma
  []

  [ADWaveCoeffPlasma]
    type = WaveEquationCoefficient
    prop_name_real = plasma_wave_coeff_real
    prop_name_imaginary = plasma_wave_coeff_imag
    k_real = ang_freq
    mu_rel_real = mu_vacuum
    mu_rel_imag = 0
    eps_rel_real = plasma_dielectric_constant_real
    eps_rel_imag = plasma_dielectric_constant_imag
    block = Plasma
  []
  [ADPlasmaDielectic]
    type = PlasmaDielectricConstant
    driving_frequency = 2.45e9
    em = -20
    electron_neutral_collision_frequency = nu_neutral
    electron_neutral_collision_frequency_gradient = grad_nu_neutral
    block = Plasma
  []

  [ADCollisionFreq]
    type = DependentCollisionFreq
    field_property_name = field_solver_interface_property
    electrons = -20
    mean_energy = -22
    use_mean_energy = true
    driving_frequency = 2.45e9
    # Need to change during delta sweep
    delta = 20
    file_location = ''
    property_file = collision_frequency.txt
    block = Plasma
  []

  [gas_species_1]
    type = ADHeavySpecies
    heavy_species_name = Ar*
    heavy_species_mass = 6.64e-26
    heavy_species_charge = 0.0
    diffusivity = 3.7577e-02
    mobility = 0.0
  []
[]

[Postprocessors]
  [Meta_Relative_Diff]
    type = RelativeElementL2Difference
    variable = Ar*
    other_variable = Ar*S
    execute_on = 'TIMESTEP_END'
    block = Plasma
  []
[]

[Preconditioning]
  active = 'smp'
  [smp]
    type = SMP
    full = true
  []

  [fdp]
    type = FDP
    full = true
  []
[]

[Executioner]
  type = Steady

  petsc_options = '-snes_converged_reason -snes_linesearch_monitor'
  solve_type = NEWTON

  petsc_options_iname = '-pc_type -pc_factor_shift_type -pc_factor_shift_amount'
  petsc_options_value = 'lu NONZERO 1.e-10'

  nl_abs_tol = 1e-12
  nl_forced_its = 1
[]

[Outputs]
  print_perf_log = true
  [out]
    type = Exodus
  []
[]
