import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# 1. Load the data
df = pd.read_csv('mandel_raw_data.csv')

# 2. Geometric Midpoints
mid_x, mid_y, mid_z = df['X'].median(), df['Y'].median(), df['Z'].median()
y_span = df['Y'].max() - df['Y'].min()
z_span = df['Z'].max() - df['Z'].min()

# --- FIGURE 1: PRESSURE VS TIME (The reliable one) ---
unique_cells = df[['X', 'Y', 'Z']].drop_duplicates().copy()
unique_cells['dist'] = np.sqrt((unique_cells['X']-mid_x)**2 + (unique_cells['Y']-mid_y)**2 + (unique_cells['Z']-mid_z)**2)
target_cell = unique_cells.sort_values('dist').iloc[0]
time_history = df[(df['X'] == target_cell['X']) & (df['Y'] == target_cell['Y']) & (df['Z'] == target_cell['Z'])].sort_values('Time_s')

plt.figure(figsize=(10, 4))
plt.plot(time_history['Time_s'], time_history['Pressure_Pa'], 'o-', label='Center Point')
plt.title("Figure 1: Center Point Pressure History")
plt.xlabel("Time (s)")
plt.ylabel("Pressure (Pa)")
plt.grid(True)
plt.show()

# --- FIGURE 2: RAW PRESSURE VS X ---
# We use a very wide lane to ensure we are not missing data
lane_mask = (np.abs(df['Y'] - mid_y) <= 0.3 * y_span) & (np.abs(df['Z'] - mid_z) <= 0.3 * z_span)
lane_df = df[lane_mask].copy()

target_times = [0.05, 0.5, 5.0, 10.0]
available_times = sorted(df['Time_s'].unique())
plot_times = [available_times[np.argmin(np.abs(np.array(available_times) - t))] for t in target_times]

plt.figure(figsize=(10, 5))
# Using a "Lines + Markers" style so we can see if data points exist
for t in sorted(list(set(plot_times))):
    step_data = lane_df[lane_df['Time_s'] == t]
    
    # Average points at the same X to get a clean line
    profile = step_data.groupby('X')['Pressure_Pa'].mean().reset_index().sort_values('X')
    
    # Using RAW Pressure on Y-axis to see the actual values
    plt.plot(profile['X'], profile['Pressure_Pa'], marker='.', label=f't ≈ {t:.2f} s')

plt.title("Figure 2: Raw Pressure Profiles across X-axis")
plt.xlabel("Coordinate X")
plt.ylabel("Pressure (Pa)")
plt.legend()
plt.grid(True)
plt.show()

# --- DEBUG PRINT ---
print("Mean pressure per time step in Figure 2:")
for t in plot_times:
    mean_p = lane_df[lane_df['Time_s'] == t]['Pressure_Pa'].mean()
    print(f"Time {t:.2f}s: Mean P = {mean_p:.2f} Pa")
    