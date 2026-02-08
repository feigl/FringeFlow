import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# 1. Load the data
df = pd.read_csv('mandel_raw_data.csv')

# 2. Identify Center Point for Figure 1
mid_x, mid_y, mid_z = df['X'].median(), df['Y'].median(), df['Z'].median()
df['dist'] = np.sqrt((df['X']-mid_x)**2 + (df['Y']-mid_y)**2 + (df['Z']-mid_z)**2)
center_point = df.sort_values('dist').iloc[0]

# Extract history for that specific center cell
history = df[(df['X'] == center_point['X']) & 
             (df['Y'] == center_point['Y']) & 
             (df['Z'] == center_point['Z'])].sort_values('Time_s')

# =========================================================
# FIGURE 1: RAW PRESSURE VS TIME
# =========================================================
plt.figure(1, figsize=(10, 6))
plt.plot(history['Time_s'], history['Pressure_Pa'], 'o-', color='#1f77b4', linewidth=2, markersize=4)

plt.title("Figure 1: Raw Pressure vs. Time (Center Point)", fontweight='bold')
plt.xlabel("Time (s)")
plt.ylabel("Pressure (Pa)")
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()

# Save Figure 1
plt.savefig('figure1_pressure_vs_time.png', dpi=600)
print("Saved: figure1_pressure_vs_time.png (600 DPI)")

# =========================================================
# FIGURE 2: RAW PRESSURE VS X-COORDINATE
# =========================================================
plt.figure(2, figsize=(10, 6))

# Determine the time steps to plot
available_times = sorted(df['Time_s'].unique())
target_times = [0.05, 0.5, 5.0, 10.0]
plot_times = sorted(list(set([available_times[np.argmin(np.abs(np.array(available_times) - t))] for t in target_times])))

# Colormap for time progression
colors = plt.cm.viridis(np.linspace(0, 0.8, len(plot_times)))

for i, t in enumerate(plot_times):
    # Average across Y and Z to get the clean profile along the X-axis
    step_data = df[df['Time_s'] == t]
    profile = step_data.groupby('X')['Pressure_Pa'].mean().reset_index().sort_values('X')
    
    plt.plot(profile['X'], profile['Pressure_Pa'], 
             label=f't ≈ {t:.2f} s', color=colors[i], marker='.', markersize=6, linewidth=2)



plt.title("Figure 2: Raw Pressure vs. X-Coordinate", fontweight='bold')
plt.xlabel("X Coordinate (m)")
plt.ylabel("Pressure (Pa)")
plt.legend(title="Time (s)", loc='upper right')
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()

# Save Figure 2
plt.savefig('figure2_pressure_vs_x.png', dpi=600)
print("Saved: figure2_pressure_vs_x.png (600 DPI)")

# Display both to screen
plt.show()
