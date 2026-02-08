import h5py
import matplotlib.pyplot as plt
import numpy as np

# --- Configuration ---
file_path = 'results/mandel_complete.h5'
MID_PLANE_TOL = 0.01 

with h5py.File(file_path, 'r') as f:
    centers = f['geometry_cells'][()] 
    steps = sorted([k for k in f.keys() if k.startswith('step_')])
    
    # --- 1. COORDINATE CALCULATION (x/a) ---
    x_min, x_max = np.min(centers[:, 0]), np.max(centers[:, 0])
    x_mid = (x_max + x_min) / 2.0
    a = (x_max - x_min) / 2.0  # Half-width
    
    # Setup Figure
    plt.style.use('default')
    fig, ax = plt.subplots(figsize=(8, 5))
    
    # Using 'magma' or 'viridis' for a high-contrast time series
    colors = plt.cm.magma(np.linspace(0.1, 0.9, len(steps)))

    # Slice for the mid-height (Y-axis)
    y_mid = np.mean(centers[:, 1])
    mask = np.abs(centers[:, 1] - y_mid) < MID_PLANE_TOL

    print(f"Normalizing x-axis by half-width a={a:.2f} centered at x={x_mid:.2f}...")

    for i, step_name in enumerate(steps):
        p_data = f[step_name]['pressure'][()]
        time = f[step_name].attrs.get('time', 0.0)

        x_coords = centers[mask, 0]
        p_vals = p_data[mask]

        # Sorting for line continuity
        sort_idx = np.argsort(x_coords)
        x_raw = x_coords[sort_idx]
        
        # --- NORMALIZATION TO x/a ---
        # Centering at 0, ranging from -1 to 1
        x_norm = (x_raw - x_mid) / a
        p_plot = p_vals[sort_idx]

        label = f"t = {time:.1e}" if i % 5 == 0 or i == len(steps)-1 else ""
        ax.plot(x_norm, p_plot, color=colors[i], label=label, linewidth=1.8)

    # 2. Documentation Style Formatting
    ax.set_title("Mandel Effect: Pore Pressure Evolution", fontsize=13, fontweight='bold')
    ax.set_xlabel("Dimensionless Distance ($x/a$)", fontsize=11)
    ax.set_ylabel("Pore Pressure $p$ (Pa)", fontsize=11)
    
    ax.set_xlim(-1, 1)  # The bounds of the Mandel specimen
    ax.axvline(0, color='black', linestyle='--', alpha=0.3) # Center line
    ax.grid(True, linestyle=':', alpha=0.7)
    ax.legend(title="Time", loc='upper right', fontsize='small', frameon=True)
    
    plt.tight_layout()
    plt.savefig('mandel_xa_pressure.png', dpi=300)
    plt.show()