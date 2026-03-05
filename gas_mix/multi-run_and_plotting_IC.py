import os
import copy
import mooseutils

import pyhit
import moosetree

import numpy as np
import matplotlib.pyplot as plt


# Define arrays for plotting
#pressures_Torr = np.array([200,    300,    400,    500,    600,    700,    800,     900,    1000,    1200,    1500,    2000]) # in mTorr
#pressures =      np.array([26.665, 39.997, 53.329, 66.661, 79.993, 93.326, 106.658, 119.99, 133.322, 159.987, 199.984, 266.645])

#pressures_inverse = np.array([1000/200, 1000/300, 1000/400, 1000/500, 1000/600, 1000/700, 1000/800, 1000/900, 1000/1000, 1000/1200, 1000/1500, 1000/2000])
#pressures_linear = np.array([200/1000, 300/1000, 400/1000, 500/1000, 600/1000, 700/1000, 800/1000, 900/1000, 1000/1000, 1200/1000, 1500/1000, 2000/1000])

pressures_Torr = np.array([70,  85, 100]) # in mTorr
pressures =      np.array([9.33  ,  11.33,  13.33])

pressures_inverse = np.array([1000/70, 1000/85, 1000/100])
pressures_linear =  np.array([70/1000, 85/1000, 100/1000])

ion_mobi = 0.144409938 # @ 1 Torr
ion_diff = 6.428571e-3 # @ 1 Torr
n_g_base = 3.22e22 # @ 1 Torr

mobi = ion_mobi * pressures_inverse
diff = ion_diff * pressures_inverse
n_g = n_g_base * pressures_linear

ne = []
Te = []

# For cases that adds 0 - 5 to the Reduce E-field
for i in range(0, 3):

    # Read the file
    root_main = pyhit.load('microwave-loosely-coupled-main-Plasma-IC.i')
    root_sub = pyhit.load('microwave-loosely-coupled-sub-EM-IC.i')

    # Rewrite Ambipolar Ion Coeff.
    input_parameters = moosetree.find(root_main, func=lambda n: n.fullpath == '/Kernels/ambipolar_Efield')
    input_parameters["ion_mobility"] = "{:.4e}".format(mobi[i])
    input_parameters["ion_diffusion"] = "{:.4e}".format(diff[i])

    # Rewrite Background Gas Density
    input_parameters = moosetree.find(root_main, func=lambda n: n.fullpath == '/AuxKernels/Ar_val')
    input_parameters["function"] = 'log('+"{:.4e}".format(n_g[i])+' / 6.022e23)'

    # Rewrite Sub File Name
    input_parameters = moosetree.find(root_main, func=lambda n: n.fullpath == '/MultiApps/EM_Heating')
    input_parameters["input_files"] = 'microwave-loosely-coupled-sub-EM-IC_'+str(pressures_Torr[i])+'mTorr.i'

    # Rewrite Pin Pressure
    input_parameters = moosetree.find(root_main, func=lambda n: n.fullpath == '/Materials/Pin_Basic')
    input_parameters["user_p_gas"] = pressures[i]

    input_parameters = moosetree.find(root_sub, func=lambda n: n.fullpath == '/Materials/Pin_Basic')
    input_parameters["user_p_gas"] = pressures[i]

    # Rewrite Ceramic Pressure
    input_parameters = moosetree.find(root_main, func=lambda n: n.fullpath == '/Materials/Ceramic_Basic')
    input_parameters["user_p_gas"] = pressures[i]

    input_parameters = moosetree.find(root_sub, func=lambda n: n.fullpath == '/Materials/Ceramic_Basic')
    input_parameters["user_p_gas"] = pressures[i]

    # Rewrite Plasma Pressure
    input_parameters = moosetree.find(root_main, func=lambda n: n.fullpath == '/Materials/Plasma_Basic')
    input_parameters["user_p_gas"] = pressures[i]

    input_parameters = moosetree.find(root_sub, func=lambda n: n.fullpath == '/Materials/Plasma_Basic')
    input_parameters["user_p_gas"] = pressures[i]

    # Write the modified file
    pyhit.write("microwave-loosely-coupled-main-Plasma-IC_"+str(pressures_Torr[i])+"mTorr.i", root_main)
    pyhit.write("microwave-loosely-coupled-sub-EM-IC_"+str(pressures_Torr[i])+"mTorr.i", root_sub)

    # This runs the modified input file
    input_files = ['microwave-loosely-coupled-main-Plasma-IC_'+str(pressures_Torr[i])+'mTorr.i']
    cli_args = ['-i'] + input_files
    a = copy.copy(cli_args)

    executable = mooseutils.find_moose_executable_recursive(os.getcwd())
    out  = mooseutils.run_executable(executable,*a, mpi=14, suppress_output=False)

    # read and store tabulated data, ignoring first line with strings
    data = np.genfromtxt("microwave-loosely-coupled-main-Plasma-IC_"+str(pressures_Torr[i])+"mTorr_csv_out.csv",skip_header=1,delimiter=',')
    
    # Populate the plotting arrays with current run data
    ne.append(data[6])
    Te.append(data[8])



fig = plt.figure()
plt.plot(pressures_Torr, ne)
#plt.yscale("log")
#plt.xscale("linear")
plt.xlabel("Pressure (mTorr)")
plt.ylabel("Plasma Density [m${}^{-3}$]")
plt.grid(linestyle='--',alpha=0.9)
plt.draw()
plt.savefig("Density_Vs_Pressure.png",dpi=600)

fig = plt.figure()
plt.plot(pressures_Torr, Te)
#plt.yscale("log")
#plt.xscale("linear")
plt.xlabel("Pressure (mTorr)")
plt.ylabel("Plasma Temp. [eV]")
plt.grid(linestyle='--',alpha=0.9)
plt.draw()
plt.savefig("Temp_Vs_Pressure.png",dpi=600)
