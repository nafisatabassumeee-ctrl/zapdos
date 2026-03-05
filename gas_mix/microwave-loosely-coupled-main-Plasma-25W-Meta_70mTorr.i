dom0Scale = 1.0

[GlobalParams]
  potential_units = V
  use_moles = true
[]

# Mesh or Previous Output file: Need to change for continued runs
[Mesh]
  [fmg]
    type = FileMeshGenerator
    # file = NCSU_chamber-edits-WO-lid-sepWalls.msh
    file = microwave-loosely-coupled-main-Plasma-IC-Meta_200mTorr_exo_out.e
    use_for_exodus_restart = true
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
  # [density_profile_log]
  #   type = ParsedFunction
  #   expression = 'log(1e12 / 6.022e23)'
  # []
  # [energy_profile_log]
  #   type = ParsedFunction
  #   symbol_names = 'density_profile_log'
  #   symbol_values = 'density_profile_log'
  #   expression = 'log(4.0 * 3/2) + density_profile_log'
  # []

  # Coefficient to change current-power: Need to change during power sweep
  [alpha]
    type = ParsedFunction
    symbol_names = 'heating time_step'
    symbol_values = 'Volume_Average_Power time_step'
    # expression = '25 / heating'

    # expression = 'if(time_step > 1e-7, 25 / heating, 0.1 * (time_step / 1e-7) * (25 / heating))'
    expression = '40 / heating'
  []
[]

[Outputs]
  print_linear_residuals = true
  checkpoint = true
  [exo_out]
    type = Exodus
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [fail_out]
    type = Exodus
    # execute_on = 'INITIAL TIMESTEP_END'
    execute_on = 'FAILED'
  []
  #[csv_out]
  #  type = CSV
  #  execute_on = 'FINAL'
  #[]
[]

[Variables]
  [Dummy]
    block = 'Resonator_Pin Ceramic'
  []

  [em]
    block = Plasma
    initial_from_file_var = em
    initial_from_file_timestep = LATEST
  []
  # [Ar+]
  #   block = Plasma
  # []
  [mean_en]
    block = Plasma
    initial_from_file_var = mean_en
    initial_from_file_timestep = LATEST
  []

  [Ar*]
    block = Plasma
    initial_from_file_var = Ar*
    initial_from_file_timestep = LATEST
  []

  # [potential]
  #   block = Plasma
  # []

  [efield]
    family = LAGRANGE_VEC
    order = FIRST
    block = Plasma
  []

  [SM_Ar*]
    initial_condition = 1.0
    block = Plasma
    initial_from_file_var = SM_Ar*
    initial_from_file_timestep = LATEST
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
  #Net electron production from step-wise ionization
  [em_stepwise_ionization]
    type = ADEEDFReactionLog
    variable = em
    electrons = em
    target = Ar*
    reaction = 'em + Ar* -> em + em + Ar+'
    coefficient = 1
    block = Plasma
  []
  #Net electron production from metastable pooling
  [em_pooling]
    type = ADReactionSecondOrderLog
    variable = em
    v = Ar*
    w = Ar*
    reaction = 'Ar* + Ar* -> Ar+ + Ar + em'
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

  #Argon Excited Equations (Same as in paper)
  #Time Derivative term of excited Argon
  [Ar*_time_deriv]
    type = ElectronTimeDerivative
    variable = Ar*
    block = Plasma
  []
  #Diffusion term of excited Argon
  [Ar*_diffusion]
    type = CoeffDiffusion
    variable = Ar*
    position_units = ${dom0Scale}
    block = Plasma
  []
  #Net excited Argon production from excitation
  [Ar*_excitation]
    type = ADEEDFReactionLog
    variable = Ar*
    electrons = em
    target = Ar
    reaction = 'em + Ar -> em + Ar*'
    coefficient = 1
    block = Plasma
  []
  #Net excited Argon loss from step-wise ionization
  [Ar*_stepwise_ionization]
    type = ADEEDFReactionLog
    variable = Ar*
    electrons = em
    target = Ar*
    reaction = 'em + Ar* -> em + em + Ar+'
    coefficient = -1
    block = Plasma
  []
  #Net excited Argon loss from superelastic collisions
  [Ar*_collisions]
    type = ADEEDFReactionLog
    variable = Ar*
    electrons = em
    target = Ar*
    reaction = 'em + Ar* -> em + Ar'
    coefficient = -1
    block = Plasma
  []
  #Net excited Argon loss from quenching to resonant
  [Ar*_quenching]
    type = ADEEDFReactionLog
    variable = Ar*
    electrons = em
    target = Ar*
    reaction = 'em + Ar* -> em + Ar_r'
    coefficient = -1
    block = Plasma
  []
  #Net excited Argon loss from  metastable pooling
  [Ar*_pooling]
    type = ADReactionSecondOrderLog
    variable = Ar*
    v = Ar*
    w = Ar*
    reaction = 'Ar* + Ar* -> Ar+ + Ar + em'
    coefficient = -2
    _v_eq_u = true
    _w_eq_u = true
    block = Plasma
  []
  #Net excited Argon loss from two-body quenching
  [Ar*_2B_quenching]
    type = ADReactionSecondOrderLog
    variable = Ar*
    v = Ar*
    w = Ar
    reaction = 'Ar* + Ar -> Ar + Ar'
    coefficient = -1
    _v_eq_u = true
    block = Plasma
  []
  #Net excited Argon loss from three-body quenching
  [Ar*_3B_quenching]
    type = ADReactionThirdOrderLog
    variable = Ar*
    v = Ar*
    w = Ar
    x = Ar
    reaction = 'Ar* + Ar + Ar -> Ar_2 + Ar'
    coefficient = -1
    _v_eq_u = true
    block = Plasma
  []

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
  #Energy loss from step-wise ionization
  [Stepwise_Ionization_Loss]
    type = ADEEDFEnergyLog
    variable = mean_en
    electrons = em
    target = Ar*
    reaction = 'em + Ar* -> em + em + Ar+'
    threshold_energy = -4.14
    block = Plasma
  []
  #Energy gain from superelastic collisions
  [Collisions_Loss]
    type = ADEEDFEnergyLog
    variable = mean_en
    electrons = em
    target = Ar*
    reaction = 'em + Ar* -> em + Ar'
    threshold_energy = 11.56
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
    ion_mobility = 7.2205e-01
    ion_diffusion = 3.2143e-02
    block = Plasma
  []

  ##########################################################################
  #Argon Excited Equations
  #Time Derivative term of excited Argon
  [SM_Ar*_time_deriv]
    type = MassLumpedTimeDerivative
    variable = SM_Ar*
    enable = false
    block = Plasma
  []
  #Diffusion term of excited Argon
  [SM_Ar*_diffusion]
    type = CoeffDiffusionForShootMethod
    variable = SM_Ar*
    density = Ar*
    position_units = ${dom0Scale}
    enable = false
    block = Plasma
  []
  #Net excited Argon loss from step-wise ionization
  [SM_Ar*_stepwise_ionization]
    type = EEDFReactionLogForShootMethod
    variable = SM_Ar*
    electron = em
    density = Ar*
    reaction = 'em + Ar* -> em + em + Ar+'
    coefficient = -1
    enable = false
    block = Plasma
  []
  #Net excited Argon loss from superelastic collisions
  [SM_Ar*_collisions]
    type = EEDFReactionLogForShootMethod
    variable = SM_Ar*
    electron = em
    density = Ar*
    reaction = 'em + Ar* -> em + Ar'
    coefficient = -1
    enable = false
    block = Plasma
  []
  #Net excited Argon loss from quenching to resonant
  [SM_Ar*_quenching]
    type = ReactionSecondOrderLogForShootMethod
    variable = SM_Ar*
    density = Ar*
    v = em
    reaction = 'em + Ar* -> em + Ar_r'
    coefficient = -1
    enable = false
    block = Plasma
  []
  #Net excited Argon loss from  metastable pooling
  [SM_Ar*_pooling]
    type = ReactionSecondOrderLogForShootMethod
    variable = SM_Ar*
    density = Ar*
    v = Ar*
    reaction = 'Ar* + Ar* -> Ar+ + Ar + em'
    coefficient = -2
    enable = false
    block = Plasma
  []
  #Net excited Argon loss from two-body quenching
  [SM_Ar*_2B_quenching]
    type = ReactionSecondOrderLogForShootMethod
    variable = SM_Ar*
    density = Ar*
    v = Ar
    reaction = 'Ar* + Ar -> Ar + Ar'
    coefficient = -1
    enable = false
    block = Plasma
  []
  #Net excited Argon loss from three-body quenching
  [SM_Ar*_3B_quenching]
    type = ReactionThirdOrderLogForShootMethod
    variable = SM_Ar*
    density = Ar*
    v = Ar
    w = Ar
    reaction = 'Ar* + Ar + Ar -> Ar_2 + Ar'
    coefficient = -1
    enable = false
    block = Plasma
  []

  [SM_Ar*_Null]
    type = NullKernel
    variable = SM_Ar*
    block = Plasma
  []

[]

[AuxVariables]
  [SM_Ar*Reset]
    initial_condition = 1.0
    block = Plasma
    initial_from_file_var = SM_Ar*Reset
    initial_from_file_timestep = LATEST
  []
  [Ar*S]
    block = Plasma
    initial_from_file_var = Ar*S
    initial_from_file_timestep = LATEST
  []

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
  [Ar*_density]
    order = CONSTANT
    family = MONOMIAL
    block = Plasma
  []

  [Ar]
  []

  [ne_log]
    block = Plasma
    initial_from_file_var = ne_log
    initial_from_file_timestep = LATEST
  []
  [mean_log]
    block = Plasma
    initial_from_file_var = mean_log
    initial_from_file_timestep = LATEST
  []
  [Ar_meta_log]
    block = Plasma
    initial_from_file_var = Ar_meta_log
    initial_from_file_timestep = LATEST
  []

  # [E_field]
  #   family = MONOMIAL_VEC
  #   order = FIRST
  #   block = Plasma
  # []
[]

[AuxKernels]
  [Ar*S_for_Shooting]
    type = QuotientAux
    variable = Ar*S
    numerator = Ar*
    denominator = 1.0
    enable = false
    execute_on = 'TIMESTEP_END'
    block = Plasma
  []

  [Constant_SM_Ar*Reset]
    type = ConstantAux
    variable = SM_Ar*Reset
    value = 1.0
    execute_on = INITIAL
    block = Plasma
  []

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
    function = 'log(6.4400e+21 / 6.022e23)'
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
  [Ar_meta_log]
    type = SelfAux
    variable = Ar_meta_log
    v = Ar*
    execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_END'
    block = Plasma
  []

  [Ar*_density]
    type = DensityMoles
    variable = Ar*_density
    density_log = Ar*
    block = Plasma
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
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

  [gas_species_1]
    type = ADHeavySpecies
    heavy_species_name = Ar*
    heavy_species_mass = 6.64e-26
    heavy_species_charge = 0.0
    diffusivity = 3.7577e-02
    mobility = 0.0
  []
  [reaction_2]
    type = ADZapdosEEDFRateConstant
    mean_energy = mean_en
    property_file = 'ar_deexcitation.txt'
    reaction = 'em + Ar* -> em + Ar'
    file_location = ''
    electrons = em
    block = Plasma
  []
  [reaction_3]
    type = ADZapdosEEDFRateConstant
    mean_energy = mean_en
    property_file = 'ar_excited_ionization.txt'
    reaction = 'em + Ar* -> em + em + Ar+'
    file_location = ''
    electrons = em
    block = Plasma
  []
  [reaction_4]
    type = ADGenericRateConstant
    reaction = 'em + Ar* -> em + Ar_r'
    #reaction_rate_value = 2e-13
    reaction_rate_value = 1.2044e11
    block = Plasma
  []
  [reaction_5]
    type = ADGenericRateConstant
    reaction = 'Ar* + Ar* -> Ar+ + Ar + em'
    #reaction_rate_value = 6.2e-16
    reaction_rate_value = 373364000
    block = Plasma
  []
  [reaction_6]
    type = ADGenericRateConstant
    reaction = 'Ar* + Ar -> Ar + Ar'
    #reaction_rate_value = 3e-21
    reaction_rate_value = 1806.6
    block = Plasma
  []
  [reaction_7]
    type = ADGenericRateConstant
    reaction = 'Ar* + Ar + Ar -> Ar_2 + Ar'
    #reaction_rate_value = 1.1e-43
    reaction_rate_value = 39890.9324
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
  [Ar*_do_nothing]
    type = DriftDiffusionDoNothingBC
    variable = Ar*
    mu = 0
    diff = 0
    sign = 0
    use_material_props = true
    # boundary = 'chamber_bottom'
    boundary = 'chamber_bottom plasma_side'
    position_units = ${dom0Scale}
  []

  [SM_Ar*_bottom]
    type = DirichletBC
    variable = SM_Ar*
    #boundary = 'chamber_bottom plasma_side chamber_walls'
    boundary = 'chamber_bottom plasma_side'
    value = 0
    preset = false
    enable = false
  []
[]

# [ICs]
#   [em_ic]
#     type = FunctionIC
#     variable = em
#     function = density_profile_log
#   []
#   # [Ar+_ic]
#   #   type = FunctionIC
#   #   variable = Ar+
#   #   function = density_profile_log
#   # []
#  [mean_en_ic]
#     type = FunctionIC
#     variable = mean_en
#     function = energy_profile_log
#   []
# 
#   [Ar*_ic]
#     type = FunctionIC
#     variable = Ar*
#     function = density_profile_log
#   []
# 
#   [ne_ic]
#     type = FunctionIC
#     variable = ne_log
#     function = density_profile_log
#   []
#   [energy_ic]
#     type = FunctionIC
#     variable = mean_log
#     function = energy_profile_log
#  []
# []

[MultiApps]
  [EM_Heating]
    type = FullSolveMultiApp
    input_files = microwave-loosely-coupled-sub-EM-IC_200mTorr.i
    execute_on = 'INITIAL TIMESTEP_END'
    # execute_on = 'INITIAL'
  []

  #MultiApp of Acceleration by Shooting Method
  [Shooting]
    type = FullSolveMultiApp
    input_files = microwave_Shooting-IC_200mTorr.i
    execute_on = 'TIMESTEP_END'
    enable = false
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
  [meta_to_EM]
    type = MultiAppCopyTransfer
    to_multi_app = EM_Heating
    source_variable = Ar_meta_log
    variable = Ar_meta_log
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

  ###################################################

  #MultiApp Transfers for Acceleration by Shooting Method
  [SM_Ar*Reset_to_Shooting]
    type = MultiAppCopyTransfer
    direction = to_multiapp
    multi_app = Shooting
    source_variable = SM_Ar*Reset
    variable = SM_Ar*Reset
    enable = false
  []

  [Ar*_to_Shooting]
    type = MultiAppCopyTransfer
    direction = to_multiapp
    multi_app = Shooting
    source_variable = Ar*
    variable = Ar*
    enable = false
  []
  [Ar*S_to_Shooting]
    type = MultiAppCopyTransfer
    direction = to_multiapp
    multi_app = Shooting
    source_variable = Ar*S
    variable = Ar*S
    enable = false
  []
  [Ar*T_to_Shooting]
    type = MultiAppCopyTransfer
    direction = to_multiapp
    multi_app = Shooting
    source_variable = Ar*
    variable = Ar*T
    enable = false
  []
  [SMDeriv_to_Shooting]
    type = MultiAppCopyTransfer
    direction = to_multiapp
    multi_app = Shooting
    source_variable = SM_Ar*
    variable = SM_Ar*
    enable = false
  []

  [Ar*New_from_Shooting]
    type = MultiAppCopyTransfer
    direction = from_multiapp
    multi_app = Shooting
    source_variable = Ar*
    variable = Ar*
    enable = false
  []
  [SM_Ar*Reset_from_Shooting]
    type = MultiAppCopyTransfer
    direction = from_multiapp
    multi_app = Shooting
    source_variable = SM_Ar*Reset
    variable = SM_Ar*
    enable = false
  []

  [Ar*Relative_Diff]
    type = MultiAppPostprocessorTransfer
    direction = from_multiapp
    multi_app = Shooting
    from_postprocessor = Meta_Relative_Diff
    to_postprocessor = Meta_Relative_Diff
    reduction_type = minimum
    enable = false
  []
[]

#The Action the add the TimePeriod Controls to turn off and on the MultiApps
[PeriodicControllers]
  [Shooting]
    Enable_at_cycle_start = '*::Ar*S_for_Shooting'

    Enable_during_cycle = '*::SM_Ar*_time_deriv *::SM_Ar*_diffusion *::SM_Ar*_stepwise_ionization
                           *::SM_Ar*_collisions *::SM_Ar*_quenching *::SM_Ar*_pooling
                           *::SM_Ar*_2B_quenching *::SM_Ar*_3B_quenching *::SM_Ar*_bottom'
    #Enable_during_cycle = '*::SM_Ar*_time_deriv *::SM_Ar*_diffusion *::SM_Ar*_stepwise_ionization
    #                       *::SM_Ar*_collisions *::SM_Ar*_quenching *::SM_Ar*_pooling
    #                       *::SM_Ar*_2B_quenching *::SM_Ar*_3B_quenching'

    Enable_at_cycle_end = 'MultiApps::Shooting
                           *::SM_Ar*Reset_to_Shooting *::Ar*_to_Shooting
                           *::Ar*S_to_Shooting *::Ar*T_to_Shooting
                           *::SMDeriv_to_Shooting *::Ar*New_from_Shooting
                           *::SM_Ar*Reset_from_Shooting *::Ar*Relative_Diff'
    cycle_frequency = 50e6
    # starting_cycle = 25
    # cycles_between_controls = 25
    #starting_cycle = 9
    #cycles_between_controls = 9

    starting_cycle = 24
    cycles_between_controls = 24

    #cycles_per_controls = 1
    num_controller_set = 2000
    name = Shooting
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

  ######################################

  #Hold the metastable relative difference during the
  #Shooting Method acceleration
  [Meta_Relative_Diff]
    type = Receiver
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
  # end_time = 1e-5
  start_time = 1e-5
  end_time = 2e-5
  scheme = newmark-beta

  solve_type = 'NEWTON'

  automatic_scaling = true
  compute_scaling_once = false
  line_search = none
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -pc_factor_shift_type -pc_factor_shift_amount'
  petsc_options_value = 'lu       superlu_dist                  NONZERO               1.e-10'

  l_max_its = 50
  nl_abs_tol = 1e-5
  nl_max_its = 25
[]

[Debug]
  show_var_residual_norms = true
[]
