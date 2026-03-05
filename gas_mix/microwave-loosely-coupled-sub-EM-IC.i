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

[Postprocessors]
  [time_step]
    type = Receiver
  []

  [old_current]
    type = Receiver
  []
  [alpha]
    type = Receiver
  []

  [current_current]
    type = FunctionValuePostprocessor
    function = new_current
  []

  [Pin_Power]
    type = ElementAverageValue
    variable = pin_heating
    block = Resonator_Pin
    execute_on = 'TIMESTEP_END'
  []
[]

[Functions]
  # This function is used in the current density source equation.
  # In this case, the frequency is 2.45 GHz (omege = 2*pi*2.45e9)
  # and the relative magnetic permeability of stainless steel is about 1
  # (mu = 4*pi*1e-7)
  [omegaMu_steel]
    type = ParsedFunction
    value = '2*pi*2.45e9 * 4*pi*1e-7'
  []

  #beta is the wave number
  [beta]
    type = ParsedFunction
    value = '2*pi*2.45e9/3e8'
  []

  [new_current]
    type = ParsedFunction
    symbol_names = 'alpha old_current time_step'
    symbol_values = 'alpha old_current time_step'
    expression = 'if(time_step > 0.0, sqrt(alpha) * old_current, -1e12 * 1.02e-5)'
  []

  #the real current is 3.94 A (might need to change)
  [curr_real]
    type = ParsedVectorFunction
    symbol_names = 'new_current'
    symbol_values = 'new_current'
    value_y = 'new_current'
  []
  [curr_imag] # defaults to '0.0 0.0 0.0'
    type = ParsedVectorFunction
  []
[]

[Outputs]
  execute_on = 'INITIAL NONLINEAR TIMESTEP_END'
  exodus = true
  print_linear_residuals = true
[]

[Variables]
  [E_real]
    family = NEDELEC_ONE
    order = FIRST
  []
  [E_imag]
    family = NEDELEC_ONE
    order = FIRST
  []
[]

[Kernels]

  ########################################################################

  # Calculation the E-Field developed in the port needle
  # as it acts like a current source.
  # Real component calculations
  [pin_curlCurl_real]
    type = CurlCurlField
    variable = E_real
    block = Resonator_Pin
  []
  [pin_coeff_real]
    type = ADVectorMatReaction
    variable = E_real
    mat_prop_coef = pin_wave_coeff_real
    positive = false
    block = Resonator_Pin
  []
  [pin_source_real]
    type = VectorCurrentSource
    variable = E_real
    component = real
    source_real = curr_real
    source_imag = curr_imag
    function_coefficient = omegaMu_steel
    block = Resonator_Pin
  []
  # Imaginary component calculations
  [pin_curlCurl_imag]
    type = CurlCurlField
    variable = E_imag
    block = Resonator_Pin
  []
  [pin_coeff_imag]
    type = ADVectorMatReaction
    variable = E_imag
    mat_prop_coef = pin_wave_coeff_real
    positive = false
    block = Resonator_Pin
  []
  [pin_source_imaginary]
    type = VectorCurrentSource
    variable = E_imag
    component = imaginary
    source_real = curr_real
    source_imag = curr_imag
    function_coefficient = omegaMu_steel
    block = Resonator_Pin
  []

  ########################################################################

  # Calculation the E-Field developed in the aluminum oxide ceramic.
  # Real component calculations
  [ceramic_curlCurl_real]
    type = CurlCurlField
    variable = E_real
    block = Ceramic
  []
  [ceramic_coeff_real]
    type = ADVectorMatReaction
    variable = E_real
    # mat_prop_coef = 'ceramic'
    mat_prop_coef = ceramic_wave_coeff_real
    positive = false
    block = Ceramic
  []
  # Imaginary component calculations
  [ceramic_curlCurl_imag]
    type = CurlCurlField
    variable = E_imag
    block = Ceramic
  []
  [ceramic_coeff_imag]
    type = ADVectorMatReaction
    variable = E_imag
    # mat_prop_coef = 'ceramic'
    mat_prop_coef = ceramic_wave_coeff_real
    positive = false
    block = Ceramic
  []

  ##################################################################

  # Calculation the E-Field developed in vacuum
  # Real component calculations
  [vacuum_curlCurl_real]
    type = CurlCurlField
    variable = E_real
    block = Plasma
  []
  [vacuum_coeff_real]
    type = ADVectorMatReaction
    variable = E_real
    mat_prop_coef = wave_coeff_real
    positive = false
    block = Plasma
  []
  [vacuum_current_real]
    type = ADConductiveCurrent
    variable = E_real
    component = real
    E_real = E_real
    E_imag = E_imag
    conductivity_real = plasma_conductivity_real
    conductivity_imag = plasma_conductivity_imag
    ang_freq = ang_freq
    permeability = mu_vacuum
    block = Plasma
  []
  # Imaginary component calculations
  [vacuum_curlCurl_imag]
    type = CurlCurlField
    variable = E_imag
    block = Plasma
  []
  [vacuum_coeff_imag]
    type = ADVectorMatReaction
    variable = E_imag
    mat_prop_coef = wave_coeff_real
    positive = false
    block = Plasma
  []
  [vacuum_curent_imag]
    type = ADConductiveCurrent
    variable = E_imag
    component = imaginary
    E_real = E_real
    E_imag = E_imag
    conductivity_real = plasma_conductivity_real
    conductivity_imag = plasma_conductivity_imag
    ang_freq = ang_freq
    permeability = mu_vacuum
    block = Plasma
  []
[]

[AuxVariables]
  [ne_log]
    block = Plasma
  []
  [mean_log]
    block = Plasma
  []

  [ne]
    family = MONOMIAL
    order = FIRST
    block = Plasma
  []
  [Te]
    order = FIRST
    family = MONOMIAL
    block = Plasma
  []

  [conductive_heating]
    family = MONOMIAL
    order = CONSTANT
    block = Plasma
  []

  [pin_heating]
    family = MONOMIAL
    order = CONSTANT
    block = Resonator_Pin
  []
[]

[AuxKernels]
  [ne]
    type = DensityMoles
    variable = ne
    density_log = ne_log
    use_moles = true
    block = Plasma
  []
  [Te]
    type = ElectronTemperature
    variable = Te
    electron_density = ne_log
    mean_en = mean_log
    block = Plasma
  []

  [microwave_heating]
    type = AuxComplexHeating
    variable = conductive_heating
    E_real = E_real
    E_imag = E_imag
    conductivity = plasma_conductivity_real
    block = Plasma
  []

  [pin_heating]
    type = SourceCurrentHeating
    variable = pin_heating
    E_real = E_real
    E_imag = E_imag
    source_real = curr_real
    source_imag = curr_imag
    block = Resonator_Pin
  []
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
    em = ne_log
    mean_en = mean_log
    property_tables_file = electron_moments.txt
    block = Plasma
  []

  [field_solver]
    type = FieldSolverMaterial
    electric_field = E_real
    solver = electromagnetic
  []

  [ADFunctionMaterials]
    type = ADGenericFunctionMaterial
    prop_names = 'steel_prop'
    prop_values = 'omegaMu_steel'
    block = Resonator_Pin
  []
  [ADWaveCoeffPin]
    type = WaveEquationCoefficient
    prop_name_real = pin_wave_coeff_real
    prop_name_imaginary = pin_wave_coeff_real
    k_real = ang_freq
    k_imag = 0
    mu_rel_real = mu_vacuum
    mu_rel_imag = 0
    eps_rel_real = 8.85e-12
    eps_rel_imag = 0
    block = Resonator_Pin
  []

  [ADWaveCoeffCeramic]
    type = WaveEquationCoefficient
    prop_name_real = ceramic_wave_coeff_real
    prop_name_imaginary = ceramic_wave_coeff_imag
    k_real = ang_freq
    mu_rel_real = mu_vacuum
    mu_rel_imag = 0
    eps_rel_real = 8.05714e-11
    eps_rel_imag = 0
    block = Ceramic
  []

  [ADPlasmaDielectic]
    type = PlasmaDielectricConstant
    driving_frequency = 2.45e9
    em = ne_log
    electron_neutral_collision_frequency = nu_neutral
    electron_neutral_collision_frequency_gradient = grad_nu_neutral
    block = Plasma
  []
  [ADCollisionFreq]
    type = DependentCollisionFreq
    field_property_name = field_solver_interface_property
    electrons = ne_log
    mean_energy = mean_log
    use_mean_energy = true
    driving_frequency = 2.45e9
    # Need to change during delta sweep
    delta = 20
    file_location = ''
    property_file = collision_frequency.txt
    block = Plasma
  []

  [ADWaveCoeff]
    type = WaveEquationCoefficient
    prop_name_real = wave_coeff_real
    prop_name_imaginary = wave_coeff_imag
    k_real = ang_freq
    k_imag = 0
    mu_rel_real = mu_vacuum
    mu_rel_imag = 0
    eps_rel_real = 8.85e-12
    eps_rel_imag = 0
    block = Plasma
  []
[]

[BCs]
  [absorbing_real]
    type = VectorEMRobinBC
    variable = E_real
    component = real
    beta = beta
    coupled_field = E_imag
    mode = absorbing
    boundary = 'ceramic_hat chamber_walls chamber_bottom'
  []
  [absorbing_imag]
    type = VectorEMRobinBC
    variable = E_imag
    component = imaginary
    beta = beta
    coupled_field = E_real
    mode = absorbing
    boundary = 'ceramic_hat chamber_walls chamber_bottom'
  []
[]

[Preconditioning]
  [SMP]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Steady
  solve_type = 'NEWTON'

  automatic_scaling = true
  compute_scaling_once = false
  line_search = none
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -pc_factor_shift_type -pc_factor_shift_amount'
  petsc_options_value = 'lu       superlu_dist                  NONZERO               1.e-10'

  l_max_its = 50
  nl_abs_tol = 1e-2
  nl_forced_its = 1
[]

[Debug]
  show_var_residual_norms = true
[]
