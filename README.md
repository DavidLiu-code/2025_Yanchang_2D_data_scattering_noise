# Seismic Data Sorting and Conversion Tools

This repository contains a set of custom MATLAB scripts for sorting and converting seismic data gathered in SEG-Y format. The workflows are designed to avoid reliance on external libraries and instead directly manipulate binary data. These tools are useful for converting between common seismic gather types: **shot gathers**, **CMP gathers**, and **offset gathers**.

---

## 📁 Folder Structure

```
.
├── 09YCEW180-shot-gather/        # Input shot gather 
   ├── 09YCEW180-SCAMP1-gdm1700m-5s2ms.sgy        # Input shot gather (Put it here and combined to one file)
├── 09YCEW180-cmp-gather/         # Output CMP gathers (automatically generated multiple files)
├── 09YCEW180-offset-gather/      # Output offset gathers (automatically generated generated multiple files)
├── cmp2offset.m                  # Convert CMP gathers to separate Offset gathers
├── cmp2shot.m                    # Convert CMP gathers to one Shot file
├── offset2cmp.m                  # Convert Offset gathers to separate CMP gathers
├── offset2shot.m                 # Convert Offset gathers to one Shot file
├── shot2cmp.m                    # Convert the Shot gather to separate CMP gathers
├── shot2offset.m                 # Convert the Shot gather to separate Offset gathers
└── LICENSE                       # License for this repository
```

---

## 📌 Script Descriptions

### ➤ `shot2cmp.m`

Reads the input shot gather and converts them into common midpoint (CMP) gathers by reading the CMP byte in trace headers. Alternatively, we can calculate CMP coordinates from source and receiver positions. 

### ➤ `shot2offset.m`

Groups traces from the input shot gather into common-offset gathers based on calculated source-receiver distance.

### ➤ `cmp2shot.m`

Reorganizes CMP-gathered traces back into the shot file.

### ➤ `cmp2offset.m`

Converts CMP gathers into offset gathers based on calculated offsets between sources and receivers. The offset bin size is 50 m.

### ➤ `offset2cmp.m`

Converts offset gathers back into CMP gathers. Useful for visualizing CMP-stacked data after processing. 

### ➤ `offset2shot.m`

Reconstructs shot gathers from offset-based sorting.

---

## 🧪 Dataset

* **09YCEW180-SCAMP1-gdm1700m-5s2ms.sgy**: A sample seismic dataset containing SEG-Y data simulating scattering interference in the near surface.

---

## 🚀 How to Use

1. Extract your raw SEG-Y data (e.g., `09YCEW180-SCAMP1-gdm1700m-5s2ms.sgy`) and place it in the corresponding folder (e.g., `09YCEW180-shot-gather`).
2. Run the appropriate script depending on your desired conversion workflow in MATLAB. For example:

   ```matlab
   shot2offset
   offset2shot
   ```

3. This process not only converts shot gathers to offset gathers and then back, but also **reorganizes the traces in ascending shot order** based on FFID (Field File Identification).
   This is especially useful if your original file is disordered or contains a cluttered shot sequence—as is the case with `09YCEW180-SCAMP1-gdm1700m-5s2ms.sgy`.

4. The reconstructed SEG-Y file will be saved in a new folder (e.g., `09YCEW180-shot-gather/`) with clean, sequential FFID sorting.

Each script reads binary headers manually, calculates required attributes (CMP, offset, etc.), and sorts traces accordingly without relying on third-party packages.

---

## ⚠ Notes

* All scripts are implemented using raw binary reading (`fread`) and do not require the Seismic Toolbox or other packages.
* Headers are manually parsed using byte offsets from the SEG-Y standard. The original offset bytes in trace headers are not correct.
* Output is typically saved as `.sgy` files with the same formatting as the input.

---

## 📄 License

This project is licensed under the terms of the included `LICENSE` file.

