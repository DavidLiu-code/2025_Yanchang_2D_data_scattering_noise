Based on the contents of your folder (as seen in the image), here's a `README.md` file that explains the structure and purpose of your MATLAB scripts and folders:

---

### `README.md`

# Seismic Data Sorting and Conversion Tools

This repository contains a set of custom MATLAB scripts for sorting and converting seismic data gathered in SEG-Y format. The workflows are designed to avoid reliance on external libraries and instead directly manipulate binary data. These tools are useful for converting between common seismic gather types: **shot gathers**, **CMP gathers**, and **offset gathers**.

---

## 📁 Folder Structure

```
.
├── 09YCEW180-cmp-gather/         # Output CMP gathers (automatically generated)
├── 09YCEW180-offset-gather/      # Output offset gathers (automatically generated)
├── 09YCEW180-shot-gather/        # Output shot gathers (automatically generated)
├── 2025_Yanchang_2D_data_scattering_noise.zip  # Sample seismic dataset (zipped)
├── cmp2offset.m                  # Convert CMP gathers to Offset gathers
├── cmp2shot.m                    # Convert CMP gathers to Shot gathers
├── offset2cmp.m                  # Convert Offset gathers to CMP gathers
├── offset2shot.m                 # Convert Offset gathers to Shot gathers
├── shot2cmp.m                    # Convert Shot gathers to CMP gathers
├── shot2offset.m                 # Convert Shot gathers to Offset gathers
└── LICENSE                       # License for this repository
```

---

## 📌 Script Descriptions

### ➤ `shot2cmp.m`

Reads shot gathers and converts them into common midpoint (CMP) gathers by calculating CMP coordinates from source and receiver positions.

### ➤ `shot2offset.m`

Groups traces from shot gathers into common-offset gathers based on calculated source-receiver distance.

### ➤ `cmp2shot.m`

Reorganizes CMP-gathered traces back into shot gathers.

### ➤ `cmp2offset.m`

Converts CMP gathers into offset gathers based on calculated offsets between sources and receivers.

### ➤ `offset2cmp.m`

Converts offset gathers back into CMP gathers. Useful for visualizing CMP-stacked data after processing.

### ➤ `offset2shot.m`

Reconstructs shot gathers from offset-based sorting.

---

## 🧪 Dataset

* **2025\_Yanchang\_2D\_data\_scattering\_noise.zip**: A sample seismic dataset containing SEG-Y data simulating scattering interference in the near surface.

---

## 🚀 How to Use

1. Extract your raw SEG-Y data and place it in the corresponding folder (e.g., `09YCEW180-shot-gather`).
2. Run the appropriate script in MATLAB. For example:

   ```matlab
   shot2cmp
   ```
3. The script will process the traces and create a new folder (e.g., `09YCEW180-cmp-gather`) containing sorted SEG-Y files.

Each script reads binary headers manually, calculates required attributes (CMP, offset, etc.), and sorts traces accordingly without relying on third-party packages.

---

## ⚠ Notes

* All scripts are implemented using raw binary reading (`fread`) and do not require the Seismic Toolbox or other packages.
* Headers are manually parsed using byte offsets from the SEG-Y standard.
* Output is typically saved as `.sgy` files with the same formatting as the input.

---

## 📄 License

This project is licensed under the terms of the included `LICENSE` file.

---

Would you like this in Chinese or want to include example outputs (like plots or log messages)?
