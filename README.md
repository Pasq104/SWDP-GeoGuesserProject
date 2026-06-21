# SWDP GeoGuesser Project

## Overview

This repository contains the development of the **SWDP GeoGuesser Project**, carried out for the Smart Wearables Design and Prototyping course.

The project focuses on the design of a compact sensing probe for smart glasses, together with the firmware and smartphone application required to use head movements as a motion-based pointer interface.

---

## Repository Structure

```text
.
├── electronics/
│   ├── materials/                      # Datasheets and component documentation
│   └── GEO_GUESSER_PROJECT_Finale/     # PCB design files developed in Altium Designer
│
├── software/
│   ├── FW_MainBoard_Logger/            # STM32 firmware for sensor acquisition and BLE transmission
│   └── Head_Pointer_app/               # Flutter application for head-based pointer control
│
└── README.md
```

---

## Electronics

The **electronics** section contains the hardware design of the sensing probe, including PCB files, schematics, component documentation, BOM, Gerber files, and manufacturing outputs.

---

## Software

The **software** section contains the embedded firmware and the smartphone application.

### FW_MainBoard_Logger

STM32U575 firmware responsible for sensor configuration, I²C data acquisition, BLE communication through the RN4871 module, and wireless transmission of sensor measurements.

### Head_Pointer_app

Flutter application used to receive sensor data, visualize IMU measurements, and implement the head-controlled cursor interface with gesture-based navigation.

---

## Demo

🎥 The application demo is available here:

[App demonstration video](https://polimi365-my.sharepoint.com/personal/10829345_polimi_it/_layouts/15/stream.aspx?id=%2Fpersonal%2F10829345%5Fpolimi%5Fit%2FDocuments%2FAttachments%2Fvideo%5Fapp%2Emp4&nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&ga=1&referrer=StreamWebApp%2EWeb&referrerScenario=AddressBarCopied%2Eview%2E0ad40910%2Da1f2%2D40bd%2D9075%2Dc23ccc0dd90b)

---

## Project Features

- Real-time IMU data acquisition
- Bluetooth Low Energy (BLE) communication
- Head-controlled cursor interface
- Gesture-based page navigation
- Live sensor visualization
- Target-based performance testing

---

## Tools and Technologies

- **Altium Designer** – PCB design
- **STM32CubeMX** – MCU peripheral configuration
- **STM32CubeIDE** – firmware development
- **C** – embedded software
- **Flutter** – smartphone application
- **Git & GitHub** – version control

---

## Contributors

- **Pasquale Ludovico Ignarra**
- **Fabio Cambedda**
- **Alessandro Lima**
- **Sofia Capozzi del Pozo**
- **Andrea Toselli**

---

## License

This project was developed for academic purposes as part of the Smart Wearables Design and Prototyping course.
```
