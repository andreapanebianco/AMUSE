# AMUSE: Multi-Armed Bandit-based Smart Modulation Adaptation

## Introduction
UnderWater (UW) communications present significant challenges due to their harsh environment, leading to high data corruption and loss. UW communication channels experience:
- Limited bandwidth
- High time variability
- Much longer delays compared to traditional terrestrial channels

These factors result in frequent retransmissions, which consume valuable energy for network nodes and shorten their lifetime. A promising solution to these issues is the use of **reliable smart protocols** that optimize packet routing, enhancing transmission efficiency, minimizing latency, saving energy, and ensuring network robustness.

## AMUSE: Adaptive Modulation for Underwater Acoustic Networks
Our research introduces **AMUSE**, the first **Multi-Armed Bandit-based algorithm** for smart modulation adaptation in Underwater Acoustic Networks. AMUSE is specifically designed for **resource-constrained UW nodes** due to its simplicity and low computational complexity.

### Key Features
- **Real-time adaptation:** AMUSE selects the best modulation technique based on current **Packet Delivery Ratio (PDR) statistics**.
- **Multi-hop transmission:** Optimizes signal transmission across multiple hops in UW networks.
- **Lightweight implementation:** Ensures efficiency for devices with limited resources.

## Prerequisites
To run AMUSE, you need:
- **Ubuntu 22.04**
- **Underwater DESERT simulator**, developed by the University of Padova, available at: [DESERT Underwater](https://desert-underwater.dei.unipd.it/)

## Implementation Details
The **AMUSE agent** is implemented in **Python** and runs as a separate module, external to the **DESERT simulator**. It includes:
- **UCB1 algorithm** for decision-making.
- **Interfaces** to communicate with the DESERT framework.
- **Packet statistics processing** to identify the best modulation based on historical data.
- **Feedback broadcasting** to inform network nodes about the selected modulation for the next decision epoch.

## File Structure
The repository consists of the following files:

| File                          | Description |
|--------------------------------|-------------|
| `AMUSE.py`                     | AMUSE agent implementation |
| `AMUSE_DESERT_simulation.tcl`  | DESERT simulation script |
| `Bash_simulation.sh`           | Script to repeat `n` training epochs for AMUSE |
| `rewards.csv`                  | Stores reward values for AMUSE |
| `actions.csv`                  | Logs suggested modulation arms |
| `synchronization.csv`          | Synchronization between DESERT & AMUSE at each simulation step |
| `done.csv`                     | Ensures synchronization between DESERT & AMUSE at the end of each epoch |

## Setup and Usage
### 1. Install Required Dependencies
Ensure you have Python and necessary libraries installed:
```bash
sudo apt update && sudo apt install -y python3 python3-pip
```

Install the **Weights & Biases** API (optional for logging experiments):
```bash
pip install wandb
wandb login
```

### 2. Clone the Repository
```bash
git clone https://github.com/your-repo/amuse.git
cd amuse
```

### 3. Configure DESERT Simulation
Ensure you have the **DESERT simulator** installed and configured. Modify file paths in the synchronization scripts if needed.

### 4. Run the Simulation
#### Open two terminals:
##### **Terminal 1: Start AMUSE**
```bash
python3 AMUSE.py
```
##### **Terminal 2: Start the Simulation**
```bash
chmod +x Bash_simulation.sh  # Make the script executable
./Bash_simulation.sh         # Start the simulation for n epochs
```
**Important:** Always start AMUSE before running the bash script.

## Citation
AMUSE was designed and developed as part of our research. The following publications provide a detailed explanation of its implementation, methodology, and performance evaluation:
```
@inproceedings{busacca2024adaptive,
  title={Adaptive modulation in underwater acoustic networks (AMUSE): A multi-armed bandit approach},
  author={Busacca, F and Galluccio, L and Palazzo, S and Panebianco, A and Raftopoulos, R},
  booktitle={ICC 2024-IEEE International Conference on Communications},
  pages={2336--2341},
  year={2024},
  organization={IEEE}
}

@article{busacca2025amuse,
  title={AMUSE: a Multi-Armed Bandit Framework for Energy-Efficient Modulation Adaptation in Underwater Acoustic Networks},
  author={Busacca, Fabio and Galluccio, Laura and Palazzo, Sergio and Panebianco, Andrea and Raftopoulos, Raoul},
  journal={IEEE Open Journal of the Communications Society},
  year={2025},
  publisher={IEEE}
}
```
For a comprehensive understanding of AMUSE and its applications, we encourage citing these works.
