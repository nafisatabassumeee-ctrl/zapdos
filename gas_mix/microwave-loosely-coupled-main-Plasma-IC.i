dom0Scale = 1.0

[GlobalParams]
  potential_units = V
  use_moles = true
[]

# Mesh or Previous Output file: Need to change for continued runs
[Mesh]
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

  coord_type = RZ
  rz_coord_axis = Y
  second_order = true
[]

[Problem]
  type = FEProblem
[]

# IC functions
[Functions]
  [density_profile_log]
    type = ParsedFunction
    expression = 'log(1e12 / 6.022e23)'
  []
  [energy_profile_log]
    type = ParsedFunction
    symbol_names = 'density_profile_log'
    symbol_values = 'density_profile_log'
    expression = 'log(4.0 * 3/2) + density_profile_log'
  []

  # Coefficient to change current-power: Need to change during power sweep
  [alpha]
    type = ParsedFunction
    symbol_names = 'heating time_step'
    symbol_values = 'Volume_Average_Power time_step'
    # expression = '25 / heating'

    expression = 'if(time_step > 1e-7, 25 / heating, 0.1 * (time_step / 1e-7) * (25 / heating))'
  []
[]

[Outputs]
  print_linear_residuals = true
  [exo_out]
    type = Exodus
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [csv_out]
    type = CSV
    execute_on = 'FINAL'
  []
[]

[Variables]
  [Dummy]
    block = 'Resonator_Pin Ceramic'
  []

  [em]
    block = Plasma
  []
  # [Ar+]
  #   block = Plasma
  # []
  [mean_en]
    block = Plasma
  []

  # [potential]
  #   block = Plasma
  # []

  [efield]
    family = LAGRANGE_VEC
    order = FIRST
    block = Plasma
  []
[]

[Kernels]

  ########################################################################

  # Dummy varible in the pinand ceramic to keep the mesh the same between
  # plasma and EM solves
  [Dummy]
    type = NullKernel
    variable = Dummy
    block = 'Resonator_Pin Ceramic'
  []

  ########################################################################

  #Time Derivative term of electron
  [em_time_deriv]
    type = ElectronTimeDerivative
    variable = em
    block = Plasma
  []
  #Advection term of electron
  [em_advection]
    type = EFieldAdvection
    variable = em
    position_units = ${dom0Scale}
    block = Plasma
  []
  #Diffusion term of electrons
  [em_diffusion]
    type = CoeffDiffusion
    variable = em
    position_units = ${dom0Scale}
    block = Plasma
  []
  #Net electron production from ionization
  [em_ionization]
    type = ADEEDFReactionLog
    variable = em
    electrons = em
    target = Ar
    reaction = 'em + Ar -> em + em + Ar+'
    coefficient = 1
    block = Plasma
  []

  ########################################################################

  # #Time Derivative term of the ions
  # [Ar+_time_deriv]
  #   type = ElectronTimeDerivative
  #   variable = Ar+
  #   block = Plasma
  # []
  # #Advection term of ions
  # [Ar+_advection]
  #   type = EFieldAdvection
  #   variable = Ar+
  #   position_units = ${dom0Scale}
  #   block = Plasma
  # []
  # [Ar+_diffusion]
  #   type = CoeffDiffusion
  #   variable = Ar+
  #   position_units = ${dom0Scale}
  #   block = Plasma
  # []
  # #Net ion production from ionization
  # [Ar+_ionization]
  #   type = ADEEDFReactionLog
  #   variable = Ar+
  #   electrons = em
  #   target = Ar
  #   reaction = 'em + Ar -> em + em + Ar+'
  #   coefficient = 1
  #   block = Plasma
  # []

  ######################################################################

  #Time Derivative term of electron energy
  [mean_en_time_deriv]
    type = ElectronTimeDerivative
    variable = mean_en
    block = Plasma
  []
  #Advection term of electron energy
  [mean_en_advection]
    type = EFieldAdvection
    variable = mean_en
    position_units = ${dom0Scale}
    block = Plasma
  []
  #Diffusion term of electrons energy
  [mean_en_diffusion]
    type = CoeffDiffusion
    variable = mean_en
    position_units = ${dom0Scale}
    block = Plasma
  []

  #Joule Heating term
  [mean_en_joule_heating]
    type = JouleHeating
    variable = mean_en
    em = em
    position_units = ${dom0Scale}
    block = Plasma
  []
  #Heating from Microwave Fields
  [Microwave_heating]
    type = CoupledHeating
    variable = mean_en
    heating_term = conductive_heating
  []

  #Energy loss from ionization
  [Ionization_Loss]
    type = ADEEDFEnergyLog
    variable = mean_en
    electrons = em
    target = Ar
    reaction = 'em + Ar -> em + em + Ar+'
    threshold_energy = -15.8
    block = Plasma
  []
  #Energy loss from excitation
  [Excitation_Loss]
    type = ADEEDFEnergyLog
    variable = mean_en
    electrons = em
    target = Ar
    reaction = 'em + Ar -> em + Ar*'
    threshold_energy = -11.5
    block = Plasma
  []
  # Energy loss from elastic collisions
  [Elastic_loss]
    type = ADEEDFElasticLog
    variable = mean_en
    electrons = em
    target = Ar
    reaction = 'em + Ar -> em + Ar'
    block = Plasma
  []

  #########################################################

  # #Voltage term in Poissons Eqaution
  # [potential_diffusion_dom0]
  #   type = CoeffDiffusionLin
  #   variable = potential
  #   position_units = ${dom0Scale}
  #   block = Plasma
  # []
  # #Ion term in Poissons Equation
  # [Ar+_charge_source]
  #   type = ChargeSourceMoles_KV
  #   variable = potential
  #   charged = Ar+
  #   block = Plasma
  # []
  # #Electron term in Poissons Equation
  # [em_charge_source]
  #   type = ChargeSourceMoles_KV
  #   variable = potential
  #   charged = em
  #   block = Plasma
  # []

  [ambipolar_Efield]
    type = AmbipolarEField
    variable = efield
    em = em
    # Pressure dependent coefficents default 1 Torr: Need to change during pressure sweep
    ion_mobility = 0.144409938
    ion_diffusion = 6.428571e-3
    block = Plasma
  []
[]

[AuxVariables]
  [conductive_heating]
    family = MONOMIAL
    order = CONSTANT
    block = Plasma
  []

  [e_temp]
    order = CONSTANT
    family = MONOMIAL
    block = Plasma
  []
  [em_density]
    order = CONSTANT
    family = MONOMIAL
    block = Plasma
  []
  # [Ar+_density]
  #   order = CONSTANT
  #   family = MONOMIAL
  #   block = Plasma
  # []

  [Ar]
  []

  [ne_log]
    block = Plasma
  []
  [mean_log]
    block = Plasma
  []

  # [E_field]
  #   family = MONOMIAL_VEC
  #   order = FIRST
  #   block = Plasma
  # []
[]

[AuxKernels]
  [e_temp]
    type = ElectronTemperature
    variable = e_temp
    electron_density = em
    mean_en = mean_en
    block = Plasma
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [em_density]
    type = DensityMoles
    variable = em_density
    density_log = em
    block = Plasma
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  # [Ar+_density]
  #   type = DensityMoles
  #   variable = Ar+_density
  #   density_log = Ar+
  #   block = Plasma
  #   execute_on = 'INITIAL LINEAR TIMESTEP_END'
  # []

  [Ar_val]
    type = FunctionAux
    variable = Ar
    # Pressure dependent coefficents default 1 Torr: Need to change during pressure sweep
    function = 'log(3.22e22 / 6.022e23)'
    execute_on = INITIAL
    block = Plasma
  []

  [ne_log]
    type = SelfAux
    variable = ne_log
    v = em
    execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_END'
    block = Plasma
  []
  [mean_log]
    type = SelfAux
    variable = mean_log
    v = mean_en
    block = Plasma
    execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_END'
  []

  # [E_field]
  #   type = AuxVectorCoupleGrad
  #   variable = E_field
  #   coupled_scalar = potential
  # []
[]

[Materials]
  [Pin_Basic]
    type = GasElectronMoments
    interp_trans_coeffs = false
    interp_elastic_coeff = false
    ramp_trans_coeffs = false

    # Pressure dependent coefficents default 1 Torr: Need to change during pressure sweep
    user_p_gas = 133.322
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
    user_p_gas = 133.322
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
    user_p_gas = 133.322
    user_drive_freq = 2.45e9
    pressure_dependent_electron_coeff = true

    user_T_gas = 300
    em = em
    mean_en = mean_en
    property_tables_file = electron_moments.txt
    block = Plasma
  []

  [field_solver]
    type = FieldSolverMaterial
    # potential = potential
    # solver = electrostatic
    electric_field = efield
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
    em = em
    electron_neutral_collision_frequency = nu_neutral
    electron_neutral_collision_frequency_gradient = grad_nu_neutral
    block = Plasma
  []

  [ADCollisionFreq]
    type = DependentCollisionFreq
    field_property_name = field_solver_interface_property
    electrons = em
    mean_energy = mean_en
    use_mean_energy = true
    driving_frequency = 2.45e9
    # Need to change during delta sweep
    delta = 20
    file_location = ''
    property_file = collision_frequency.txt
    block = Plasma
  []

  # [gas_species_0]
  #   type = ADHeavySpecies
  #   heavy_species_name = Ar+
  #   heavy_species_mass = 6.64e-26
  #   heavy_species_charge = 1.0
  #   # Pressure dependent coefficents default 1 Torr: Need to change during pressure sweep
  #   mobility = 0.144409938
  #   diffusivity = 6.428571e-3
  #   # mobility = 0.48136646
  #   # diffusivity = 0.02142857
  #   block = Plasma
  # []
  [gas_species_2]
    type = ADHeavySpecies
    heavy_species_name = Ar
    heavy_species_mass = 6.64e-26
    heavy_species_charge = 0.0
    block = Plasma
  []
  [reaction_00]
    type = ADZapdosEEDFRateConstant
    mean_energy = mean_en
    property_file = 'ar_elastic.txt'
    reaction = 'em + Ar -> em + Ar'
    file_location = ''
    electrons = em
    block = Plasma
  []
  [reaction_0]
    type = ADZapdosEEDFRateConstant
    property_file = 'ar_excitation.txt'
    reaction = 'em + Ar -> em + Ar*'
    file_location = ''
    mean_energy = mean_en
    electrons = em
    block = Plasma
  []
  [reaction_1]
    type = ADZapdosEEDFRateConstant
    property_file = 'ar_ionization.txt'
    reaction = 'em + Ar -> em + em + Ar+'
    file_location = ''
    mean_energy = mean_en
    electrons = em
    block = Plasma
  []
[]

[BCs]
  #New Boundary conditions for electons, same as in paper
  [em_physical_diffusion]
    type = SakiyamaElectronDiffusionBC
    variable = em
    mean_en = mean_en
    boundary = 'chamber_walls  plasma_side'
    position_units = ${dom0Scale}
  []
  [em_do_nothing]
    type = DriftDiffusionDoNothingBC
    variable = em
    mu = 0
    diff = 0
    sign = 0
    use_material_props = true
    boundary = 'chamber_bottom'
    position_units = ${dom0Scale}
  []
  #[em_Ar+_second_emissions]
  #  type = SakiyamaSecondaryElectronBC
  #  variable = em
  #  ip = Ar+
  #  users_gamma = 0.01
  #  boundary = 'chamber_walls'
  #  position_units = ${dom0Scale}
  #[]

  # #New Boundary conditions for ions, should be the same as in paper
  # [Ar+_physical_advection]
  #   type = SakiyamaIonAdvectionBC
  #   variable = Ar+
  #   boundary = 'chamber_walls plasma_side'
  #   position_units = ${dom0Scale}
  # []

  #New Boundary conditions for mean energy, should be the same as in paper
  [mean_en_physical_diffusion]
    type = SakiyamaEnergyDiffusionBC
    variable = mean_en
    em = em
    boundary = 'chamber_walls plasma_side'
    position_units = ${dom0Scale}
  []
  [mean_en_do_nothing]
    type = DriftDiffusionDoNothingBC
    variable = mean_en
    mu = 0
    diff = 0
    sign = 0
    use_material_props = true
    boundary = 'chamber_bottom'
    position_units = ${dom0Scale}
  []
  #[mean_en_Ar+_second_emissions]
  #  type = SakiyamaEnergySecondaryElectronBC
  #  variable = mean_en
  #  em = em
  #  ip = Ar+
  #  Tse_equal_Te = true
  #  se_coeff = 0.01
  #  boundary = 'chamber_walls '
  #  position_units = ${dom0Scale}
  #[]

  # [grounded_wals]
  #   type = DirichletBC
  #   variable = potential
  #   value = 0
  #   preset = false
  #   boundary = 'chamber_walls'
  # []
[]

[ICs]
  [em_ic]
    type = FunctionIC
    variable = em
    function = density_profile_log
  []
  # [Ar+_ic]
  #   type = FunctionIC
  #   variable = Ar+
  #   function = density_profile_log
  # []
  [mean_en_ic]
    type = FunctionIC
    variable = mean_en
    function = energy_profile_log
  []

  [ne_ic]
    type = FunctionIC
    variable = ne_log
    function = density_profile_log
  []
  [energy_ic]
    type = FunctionIC
    variable = mean_log
    function = energy_profile_log
  []
[]

[MultiApps]
  [EM_Heating]
    type = FullSolveMultiApp
    input_files = 'microwave-loosely-coupled-sub-EM-IC.i'
    execute_on = 'INITIAL TIMESTEP_END'
    # execute_on = 'INITIAL'
  []
[]

[Transfers]
  [time_step_to_EM]
    type = MultiAppPostprocessorTransfer
    to_multi_app = EM_Heating
    from_postprocessor = time_step
    to_postprocessor = time_step
  []
  [alpha_to_EM]
    type = MultiAppPostprocessorTransfer
    to_multi_app = EM_Heating
    from_postprocessor = alpha
    to_postprocessor = alpha
  []

  [old_to_old]
    type = MultiAppPostprocessorTransfer
    to_multi_app = EM_Heating
    from_postprocessor = old_current
    to_postprocessor = old_current
  []

  [ne_to_EM]
    type = MultiAppCopyTransfer
    to_multi_app = EM_Heating
    source_variable = ne_log
    variable = ne_log
  []
  [energy_to_EM]
    type = MultiAppCopyTransfer
    to_multi_app = EM_Heating
    source_variable = mean_log
    variable = mean_log
  []

  [Heating_from_EM]
    type = MultiAppCopyTransfer
    from_multi_app = EM_Heating
    source_variable = conductive_heating
    variable = conductive_heating
  []

  [Pin_from_EM]
    type = MultiAppPostprocessorTransfer
    from_multi_app = EM_Heating
    from_postprocessor = Pin_Power
    to_postprocessor = Pin_Power
    reduction_type = average
  []
  [current_to_old]
    type = MultiAppPostprocessorTransfer
    from_multi_app = EM_Heating
    from_postprocessor = current_current
    to_postprocessor = old_current
    reduction_type = average
  []
[]

[Postprocessors]
  [Average_Power]
    type = ElementAverageValue
    # execute_on = 'TIMESTEP_BEGIN'
    variable = conductive_heating
    block = Plasma
  []

  [Volume_Average_Power]
    type = ElementIntegralVariablePostprocessor
    variable = conductive_heating
    block = Plasma
    execute_on = 'TIMESTEP_BEGIN'
  []

  #[Volume_Average_em_density]
  #  type = ElementIntegralVariablePostprocessor
  #  variable = em_density
  #  block = Plasma
  #  execute_on = 'TIMESTEP_BEGIN'
  #[]

  [Volume]
    type = VolumePostprocessor
    block = Plasma
  []

  [time_step]
    type = FunctionValuePostprocessor
    function = 't'
  []

  [Pin_Power]
    type = Receiver
    # execute_on = 'TIMESTEP_BEGIN'
  []
  [old_current]
    type = Receiver
  []

  [alpha]
    type = FunctionValuePostprocessor
    function = alpha
  []

  [ne_12below]
    type = PointValue
    point = '0 0.228 0'
    variable = em_density
  []
  [temp_12below]
    type = PointValue
    point = '0 0.228 0'
    variable = e_temp
  []
[]

[Preconditioning]
  [SMP]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient

  dt = 1e-9
  dtmin = 1e-15
  end_time = 1e-6
  scheme = newmark-beta

  solve_type = 'NEWTON'

  automatic_scaling = true
  compute_scaling_once = false
  line_search = none
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -pc_factor_shift_type -pc_factor_shift_amount'
  petsc_options_value = 'lu       superlu_dist                  NONZERO               1.e-10'

  l_max_its = 50
  nl_abs_tol = 1e-8
  nl_max_its = 15
[]

[Debug]
  show_var_residual_norms = true
[]
