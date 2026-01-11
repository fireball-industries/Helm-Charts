# Process Overview Sample Project

Industrial process monitoring HMI with tanks, pumps, and valves.

## Features

- Animated tank levels
- Pump controls (start/stop)
- Valve position indicators
- Temperature/pressure displays
- Flow rate trending
- Alarm viewer

## Screens

1. **Main Overview** - Full process view
2. **Tank Details** - Individual tank monitoring
3. **Pump Status** - Pump diagnostics
4. **Trends** - Historical data
5. **Alarms** - Active and historical alarms

## Variables

### Tanks
- `rTank1Level` (REAL): Tank 1 level (0-100%)
- `rTank2Level` (REAL): Tank 2 level (0-100%)
- `bTank1High` (BOOL): High level alarm
- `bTank1Low` (BOOL): Low level alarm

### Pumps
- `bPump1Run` (BOOL): Pump 1 running
- `bPump2Run` (BOOL): Pump 2 running
- `rPump1Speed` (REAL): Pump 1 speed (RPM)
- `rFlowRate` (REAL): Flow rate (L/min)

### Process
- `rTemperature` (REAL): Process temperature (°C)
- `rPressure` (REAL): Pressure (bar)
- `bAutoMode` (BOOL): Automatic control

## Installation

```powershell
.\scripts\project-deploy.ps1 -ProjectPath .\sample-projects\process-overview
```

---

**Made with 💀 by Fireball Industries**

*"Watch your process flow like a boss. Or watch it fail spectacularly. Either way, it's on screen."*
