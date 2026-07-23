# Real-Time Density-Based Dynamic Traffic Light Controller (FPGA)

A real-time, density-based Traffic Light Controller (TLC) implemented in **Verilog** on an **Altera Cyclone II FPGA**. The system replaces conventional fixed-timer traffic lights with an adaptive controller that allocates green time based on live vehicle density, and automatically pre-empts signals for emergency vehicles.

## Overview

- **Vehicle detection:** 4× HC-SR04 ultrasonic sensors (one per lane), using time-of-flight distance measurement to classify traffic density as high / medium / low.
- **Emergency handling:** A sound sensor detects siren frequencies (500–2000 Hz) and triggers an automatic green corridor, pre-empting normal scheduling.
- **Control core:** A 27-state Finite State Machine (`traffic_fsm`) evaluates density and emergency signals in parallel, cycling lanes through GREEN → YELLOW phases with deterministic priority (A → B → C → D) for ties.
- **Platform:** Altera Cyclone II FPGA, chosen for parallel processing of multiple real-time sensor streams (vs. sequential microcontroller bottlenecks).

## Results

| Metric | Result |
|---|---|
| Average waiting time reduction (simulated) | Up to 30% vs. fixed-timer control |
| Sensor accuracy | Within 1% error margin |
| System response latency | Under 60 ms |

## Repository Structure

```
/rtl                — Verilog source modules
    ultrasonicdist.v     — 6-state FSM for HC-SR04 trigger/echo/distance measurement
    soundsensorled.v     — Siren edge-detection and emergency latch logic
    traffic_fsm.v        — Central controller FSM (lane selection + timing)
    smarttrafficcontroller.v — Top-level module instantiating all sub-modules
/sim                 — Testbenches and simulation waveform screenshots
/docs                — Full project report, block diagrams, FSM flowcharts, pin assignment
/constraints         — Quartus .qsf pin planner file
```

## System Architecture

Four HC-SR04 sensors and one sound sensor feed sensor-specific Verilog modules, which convert raw timing data into traffic-presence and emergency flags. A central FSM evaluates these flags each cycle and drives 3-bit red/yellow/green outputs per lane.

## Key Design Details

- **Ultrasonic timing:** 10 µs trigger pulse, distance computed via `343 m/s × t_echo / 2`. Distances under 10 cm = high density.
- **Signal timing:** 2 s green, 2 s yellow, with extendable green (up to 10 s) if a lane remains occupied — avoids starvation of low-traffic lanes.
- **Priority logic:** Emergency (siren) > highest-density lane > deterministic order A→B→C→D on ties.

## Tools Used
- Verilog HDL
- Quartus II (synthesis, pin planning)
- ModelSim (simulation & waveform verification)
- Altera Cyclone II (EP2C5) development board

## Full Report

See [`/docs/ENDSEM_Report.pdf`](./docs/ENDSEM_Report.pdf) for the complete methodology, literature survey, FSM diagrams, and simulation results.

## Future Scope
- Sensor fusion with camera/radar for vehicle classification and speed estimation
- ML-based predictive signal control (LSTM / reinforcement learning)
- IoT networking across junctions for city-wide green corridors
- Pedestrian detection and red-light violation capture
- IoT networking across junctions for city-wide green corridors
- Pedestrian detection and red-light violation capture
