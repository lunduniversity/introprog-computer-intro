import matplotlib.pyplot as plt
import pandas as pd

# Creating a DataFrame with the faked data
data = {
    "Algorithm": ["QuickSort"] * 9 + ["MergeSort"] * 9,
    "Input Size": [1000 * 10**i for i in range(3) for _ in range(3)] * 2,
    "Input Type": ["Random", "Sorted", "Reversed"] * 6,
    "Time (ms)": [
        12,
        1,
        30,
        150,
        2,
        450,
        1800,
        10,
        9000,
        20,
        20,
        20,
        200,
        200,
        200,
        2500,
        2500,
        2500,
    ],
    "Memory (MB)": [5] * 9 + [10] * 9,
}

df = pd.DataFrame(data)

# Plotting the data
plt.figure(figsize=(10, 6))

# Plot time vs. input size for each algorithm and input type
input_types = df["Input Type"].unique()
for algo in df["Algorithm"].unique():
    for input_type in input_types:
        df_filtered = df[(df["Algorithm"] == algo) & (df["Input Type"] == input_type)]
        plt.plot(
            df_filtered["Input Size"],
            df_filtered["Time (ms)"],
            marker="o",
            linestyle="-",
            label=f"{algo} - {input_type}",
        )

# Enhancing the plot
plt.xlabel("Input Size (n)")
plt.ylabel("Time (ms)")
plt.title("Comparison of QuickSort and MergeSort Performance by Input Type")
# plt.xscale("log")  # Using logarithmic scale for input size
# plt.yscale("log")  # Using logarithmic scale for time
plt.grid(True, which="both", linestyle="--", linewidth=0.5)
plt.legend()
plt.tight_layout()

# Display the plot
plt.show()