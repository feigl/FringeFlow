import h5py
import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import fsolve

# --- 1. Load Data ---
h5_file = 'results/mandel_complete.h5'
# Specific physical times from documentation
target_times = [0.05, 0.1, 0.5, 1.0, 5.0, 10.0]

with h5py.File(h5_file, 'r') as f:
    # Physical parameters from H5 attributes
    E     = f.attrs.get('YoungsModulus', 1.0e9)
    nu    = f.attrs.get('PoissonsRatio', 0.2)
    nu_u  = f.attrs.get('UndrainedPoissonsRatio', 0.44)
    k     = f.attrs.get('Permeability', 1.0e-15)
    mu    = f.attrs.get('FluidViscosity', 0.001)
    F     = f.attrs.get('AppliedLoad', 1.0e6)
    
    coords = f['geometry'][()]
    a = np.max(coords[:, 0])
    # Find the mid-height of the sample
    z_min, z_max = np.min(coords[:, 2]), np.max(coords[:, 2])
    z_mid = (z_max + z_min) / 2.0

    # Physics Constants
    G = E / (2 * (1 + nu))
    cv = (k / mu) * (2 * G * (nu_u - nu)) / ((1 - nu_u) * (1 - 2 * nu))
    p0 = (F / a) * (nu_u - nu) / (1 - nu)

    step_names = sorted([k for k in f.keys() if k.startswith('step_')], key=lambda x: int(x.split('_')[1]))
    available_times = np.array([f[s].attrs['time'] for s in step_names])

    # --- 2. Analytical Engine ---
    def root_func(x, nu, nu_u):
        return np.tan(x) - ((1 - nu) / (nu_u - nu)) * x
    roots = [fsolve(root_func, (i + 0.5) * np.pi, args=(nu, nu_u))[0] for i in range(20)]

    def get_ana_p_norm(x_norm, t):
        if t <= 0: return 1.0
        sum_term = 0
        for rn in roots:
            denom = (1 - nu) * (rn**2) - (nu_u - nu) * (np.sin(rn)**2)
            # Dimensionless time factor
            Tv = cv * t / a**2
            term = ((1 - nu) / denom) * (np.cos(rn * x_norm) - np.cos(rn)) * np.exp(-rn**2 * Tv)
            sum_term += term
        return sum_term

    # --- 3. Plotting ---
    plt.figure(figsize=(10, 6))
    colors = plt.cm.viridis(np.linspace(0, 0.9, len(target_times)))
    x_smooth = np.linspace(0, 1, 100)

    for i, t_req in enumerate(target_times):
        # Find nearest numerical snapshot
        idx = np.argmin(np.abs(available_times - t_req))
        step_name = step_names[idx]
        t_actual = available_times[idx]
        
        # Load Pressure Data
        # Pressure is usually cell data; we'll map it to the cell center coordinates
        p_data = f[step_name]['cell_data']['pressure'][()]
        
        # Determine slice tolerance (20% of height to ensure we grab enough points)
        z_tol = 0.2 * (z_max - z_min)
        
        # Match data points to the slice
        # Use first N coordinates where N is the length of p_data (cell count)
        x_pts = coords[:len(p_data), 0]
        z_pts = coords[:len(p_data), 2]
        mask = np.abs(z_pts - z_mid) < z_tol
        
        if np.any(mask):
            # 1. Plot Numerical as DOTS
            plt.plot(x_pts[mask] / a, p_data[mask] / p0, 'o', color=colors[i], 
                     markersize=4, alpha=0.5, label=f'GEOSX t={t_actual:.2f}s')
            
            # 2. Plot Analytical as CURVE
            ana_vals = [get_ana_p_norm(xn, t_req) for xn in x_smooth]
            plt.plot(x_smooth, ana_vals, '-', color=colors[i], linewidth=1.5)
        else:
            print(f"Skipping t={t_req}: No data in slice.")

    # Final Formatting to match Documentation
    plt.axhline(1.0, color='k', linestyle='--', alpha=0.3, label='Initial $p_0$')
    plt.xlabel('Normalized Distance ($x/a$)')
    plt.ylabel('Normalized Pore Pressure ($p/p_0$)')
    plt.title('Mandel Problem: Pressure Profiles (Physical Time Steps)')
    plt.legend(loc='upper right', fontsize='small')
    plt.grid(True, linestyle=':', alpha=0.5)
    plt.ylim(0, 1.3)
    plt.xlim(0, 1.05)
    plt.tight_layout()
    plt.show()