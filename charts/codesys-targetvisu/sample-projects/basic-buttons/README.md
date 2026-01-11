# Basic Buttons Sample Project

This is a simple CODESYS TargetVisu project demonstrating basic button controls.

## Features

- Start/Stop buttons
- Emergency stop
- Status indicators (LEDs)
- Counter display
- Manual/Auto mode selection

## Installation

Deploy to your CODESYS TargetVisu instance:

```powershell
.\scripts\project-deploy.ps1 -ProjectPath .\sample-projects\basic-buttons
```

## Project Structure

```
basic-buttons/
├── project.xml          # Project metadata
├── visualization.xml    # Visualization configuration
├── variables.xml        # Variable definitions
└── README.md           # This file
```

## Variables

| Name | Type | Description |
|------|------|-------------|
| bStart | BOOL | Start button |
| bStop | BOOL | Stop button |
| bEStop | BOOL | Emergency stop |
| bRunning | BOOL | Running status |
| iCounter | INT | Counter value |
| bManual | BOOL | Manual mode |
| bAuto | BOOL | Auto mode |

## Usage

1. Open HMI in web browser
2. Click START button to begin
3. Monitor status LED (green = running)
4. Click STOP to halt
5. E-STOP for emergency shutdown

## Customization

Edit `visualization.xml` to customize:
- Button colors
- LED positions
- Font sizes
- Layout

---

**Made with 💀 by Fireball Industries**

*"Press buttons. Make things happen. Feel like a wizard."*
