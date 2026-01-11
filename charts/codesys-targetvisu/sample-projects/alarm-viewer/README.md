# Alarm Viewer Sample Project

Comprehensive alarm management screen for industrial HMI.

## Features

- Active alarms table
- Alarm history
- Acknowledge buttons
- Filter by severity (Critical, Warning, Info)
- Alarm trending
- Sound notifications
- Email alerts (configurable)

## Alarm Severities

1. **Critical** (Red) - Immediate action required
2. **Warning** (Yellow) - Attention needed
3. **Info** (Blue) - Informational only

## Alarm States

- **Active** - Currently triggered
- **Acknowledged** - Operator acknowledged
- **Cleared** - Condition resolved
- **Historic** - Past alarms

## Usage

### Acknowledging Alarms

1. Select alarm in table
2. Click "Acknowledge" button
3. Alarm moves to acknowledged state
4. Clears when condition resolves

### Filtering

- Click severity buttons to filter
- Use search box for specific alarms
- Date range picker for history

## Configuration

Edit `alarm-config.xml`:
- Add custom alarm definitions
- Configure email settings
- Set retention periods
- Define alarm priorities

## Variables

- `aiActiveAlarms[100]` - Active alarm array
- `iAlarmCount` - Current alarm count
- `bCriticalAlarm` - Critical alarm present
- `bAlarmsAcked` - All alarms acknowledged

---

**Made with 💀 by Fireball Industries**

*"Your alarms are beeping. Everything is on fire. But at least you have a nice screen to watch it burn."*
