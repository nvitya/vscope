(*-----------------------------------------------------------------------------
  This file is a part of the PASUTILS project: https://github.com/nvitya/pasutils
  Copyright (c) 2022 Viktor Nagy, nvitya

  This software is provided 'as-is', without any express or implied warranty.
  In no event will the authors be held liable for any damages arising from
  the use of this software. Permission is granted to anyone to use this
  software for any purpose, including commercial applications, and to alter
  it and redistribute it freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software in
     a product, an acknowledgment in the product documentation would be
     appreciated but is not required.

  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.

  3. This notice may not be removed or altered from any source distribution.
  --------------------------------------------------------------------------- */
   file:     util_nstime.pas
   brief:    Very simple high resolution timer (in nanoseconds)
   date:     2022-03-30
   authors:  nvitya
   notes:
     Work in progress, It is tested with Linux + FreePascal so far
*)

unit util_nstime;

{$ifdef FPC}
  {$mode Delphi}
{$endif}

interface

uses
  Classes, SysUtils;

type
  TNsTime = int64;

var
  nstime_sys_offset : TNsTime;

function nstime() : TNsTime;
procedure init_nstimer(astarttime : TNsTime);

implementation

{$ifdef WINDOWS}
uses
  windows;
{$else} // linux
uses
  BaseUnix, linux;
{$endif}

{$ifdef WINDOWS}

var
  qpcmsscale : double;

procedure init_nstimer(astarttime : TNsTime);
var
  freq : int64;
begin
  nstime_sys_offset := 0;

  freq := 0;
	QueryPerformanceFrequency(freq);
	qpcmsscale := 1000000000 / freq;

  nstime_sys_offset := 0;
  nstime_sys_offset := nstime() + astarttime;
end;

function nstime() : TNsTime;
var
  qpc : int64;
begin
  qpc := 0;
  QueryPerformanceCounter(qpc);
  result := trunc(qpcmsscale * qpc);
end;

{$else} // linux

procedure init_nstimer(astarttime : TNsTime);
begin
  nstime_sys_offset := 0;
  nstime_sys_offset := nstime() + astarttime;
end;

function nstime() : TNsTime;
var
  ts : timespec;
begin
  clock_gettime(CLOCK_MONOTONIC, @ts);
  result := TNsTime(ts.tv_sec) * TNsTime(1000000000) + TNsTime(ts.tv_nsec) - nstime_sys_offset;
end;

{$endif}

initialization
begin
  init_nstimer(0);
end;

end.

