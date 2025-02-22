unit version_vscope;

{$mode ObjFPC}{$H+}

interface

const
  VSCOPE_VERSION = '2.1.6';

(* Version Log

v2.1.6:
  - Handling VIEW.ZERO_MICROTIME
v2.1.5:
  - Time displayed in days, hour and mins when the time unit is 's'
  - Autoscale fix for more than 20 Waves
v2.1.4:
  - vscope_data unit can load and save both formats
  - Merging .bscope files
v2.1.3:
  - Wave stretching with lo-res wave fixed
v2.1.2:
  - Exponential sampling time display/edit
v2.1.1:
  - Wave Syncronization can be applied to the wave group
v2.1.0:
  - Added visibility switches (hotkey V)
  - Added group selection (hotkey 1-9)

v2.0.2:
  - Processing RAW_DATA_SCALE json field

v2.0.1:
  - Running autoscale when no view parameters are defined
  - Saving binary format, keeping the original binary storage format

v2.0.0:
  - Reading binary format (.bscope)
  - fixed wave rendering performance at high sample counts

v1.2.4:
  - Wave looping
v1.2.3:
  - Setting wave color fix
v1.2.2:
  - Effective value added to the measurement window
  - Low-res waveform changed from /32 to /256 to support huge (>10M) waves
  - data overindexing fix at min-max calculation
v1.2.1:
  Fixed default alpha
v1.2.0:
  Cutting waves
  Synchronizing waves
  Duplicating waves
  Deleting waves
v1.1.2:
  Scaling with PGUP + PGDN
  base wave alpha changed from 0.5 to 0.8
v1.1.1:
  Show Full Time Range by default
  Save draw_steps
  Time Unit support
  Number Formatting improvements
v1.1.0:
  A-B Measurements
v1.0.3:
  Proper limiting of time divisions, allowing any time range with any time unit
v1.0.2:
  Y drag snapping to grid
  handling some key events: "A", "B", UP, DOWN
v1.0.1:
  Changed to full black background
v1.0.0:
  initial version

*)

implementation

end.

