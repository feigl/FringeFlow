import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# 1. Load the data
df = pd.read_csv('mandel_raw_data.csv')

# 2. Pinpoint the Center Cell
# We find the midpoints of the spatial coordinates
mid_x = (df['X'].min() + df['X'].max()) / 2
mid_y = (df['Y'].min() + df['Y'].max()) / 2
mid_z = (df['Z'].min() + df['Z'].max()) / 2

# Find the unique cell in the mesh closest to this geometric center
unique_cells = df[['X', 'Y', 'Z']].drop_duplicates().copy()
unique_cells['dist'] = np.sqrt(
    (unique_cells['X'] - mid_x)**2 + 
    (unique_cells['Y'] - mid_y)**2 + 
    (unique_cells['Z'] - mid_z)**2
)
target_cell = unique_cells.sort_values('dist').iloc[0]

# 3. Filter for just this cell's timeline
# This gives us P as a function of Time for ONE point
point_history = df[
    (df['X'] == target_cell['X']) & 
    (df['Y'] == target_cell['Y']) & 
    (df['Z'] == target_cell['Z'])
].sort_values('Time_s')

# 4. Plot P vs Time (Seconds)
plt.figure(figsize=(10, 6))
plt.plot(point_history['Time_s'], point_history['Pressure_Pa'], 
         marker='o', linestyle='-', color='blue', linewidth=2, label='Center Point')

# Labels and Styling
plt.title(f"Pore Pressure vs. Time (at X={target_cell['X']:.2f}, Y={target_cell['Y']:.2f}, Z={target_cell['Z']:.2f})", fontweight='bold')
plt.xlabel("Time (seconds)")
plt.ylabel("Pore Pressure (Pa)")
plt.grid(True, linestyle=':', alpha=0.6)

# Check if there is enough data for a trend
if len(point_history) < 2:
    plt.annotate('Only one time step found!', xy=(0.5, 0.5), xycoords='axes fraction', 
                 ha='center', color='red', fontsize=12, fontweight='bold')

plt.legend()
plt.show()

# 5. Data Dump to Console for Verification
print("--- Raw Time-Series Data for Center Point ---")
print(point_history[['Time_s', 'Pressure_Pa']].to_string(index=False))
