(* -----------------------------------------------------------------------------
 * This file is a part of the vscope project: https://github.com/nvitya/vscope
 * Copyright (c) 2023 Viktor Nagy, nvitya
 *
 * This software is provided 'as-is', without any express or implied warranty.
 * In no event will the authors be held liable for any damages arising from
 * the use of this software. Permission is granted to anyone to use this
 * software for any purpose, including commercial applications, and to alter
 * it and redistribute it freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software in
 *    a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 *
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 *
 * 3. This notice may not be removed or altered from any source distribution.
 * --------------------------------------------------------------------------- */
 *  file:     vscope_data.pas
 *  brief:    vscope data handler objects, without gui/opengl usage
 *  date:     2023-02-11
 *  authors:  nvitya
*)

unit vscope_data;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fgl, math, jsontools;

type

  EScopeData = class(Exception);

  { TWaveData }

  TWaveData = class
  public
    name   : string;
    samplt : double;  // sampling time [s]
    startt : double;  // start time [s]
    data   : array of double;

    dataunit : string;  // data unit

    viewscale   : double;  // display scale
    viewoffset  : double;  // display offset

    color  : cardinal;

    constructor Create(aname: string; asamplt: double);
    destructor Destroy; override;
    function DataCount : integer;

    procedure AllocateData(asamples : cardinal);

    procedure SaveToJsonNode(jnode : TJsonNode);
    procedure SaveToJsonFile(afilename : string);
    function LoadFromJsonNode(jnode : TJsonNode) : boolean;
    function LoadFromJsonFile(afilename : string) : boolean;

    property StartTime : double read startt;
    function EndTime : double;

    procedure LoadFloatArray(astr : string);

    procedure DoOnDataUpdate; virtual;

    function GetDataIndex(t : double) : integer;
    function NearestSampleTime(t : double) : double;
    function GetDataIndexTime(di : integer) : double;
    function GetValueAt(t : double) : double;
    function GetValueStr(t : double) : string;

    procedure CalcMinMax(fromtime, totime : double; out data_min : double; out data_max : double; out scnt : integer);

    function FindNearestScale(ascale : double) : double;
    function ScalingStr : string;

  end;

  TWaveDataList = specialize TFPGList<TWaveData>;

  { TScopeData }

  TScopeData = class
  public
    waves : TWaveDataList;

    constructor Create;
    destructor Destroy; override;

    function AddWave(aname: string; asamplt: double): TWaveData;
    function DeleteWave(awave : TWaveData) : boolean;

    procedure ClearWaves;

    procedure SaveToJsonFile(afilename : string);
    procedure LoadFromJsonFile(afilename : string);
  end;


procedure HexStrToBuffer(const astr : string; pbuf : pointer; buflen : cardinal);
function  BufferToHexStr(pbuf : pointer; len : cardinal) : string;

var
  float_number_format : TFormatSettings;

implementation

const
  hexchar_array : array of char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');

function BufferToHexStr(pbuf : pointer; len : cardinal) : string;
var
  pb, pend : PByte;
  pc : PChar;
begin
  result := '';
  if len < 1 then EXIT;

  SetLength(result, len * 2);

  pb := PByte(pbuf);
  pend := pb + len;
  pc := @result[1];
  while pb < pend do
  begin
    pc^ := hexchar_array[(pb^ shr 4) and 15];
    inc(pc);
    pc^ := hexchar_array[pb^ and 15];
    inc(pc);
    inc(pb);
  end;
end;


procedure HexStrToBuffer(const astr : string; pbuf : pointer; buflen : cardinal);
var
  pc, pcend: PChar;
  pb : PByte;
  n : byte;
  b : byte;
  c : char;
begin
  if length(astr) div 2 < buflen then buflen := length(astr) div 2;
  if buflen < 1 then EXIT;

  pc := @astr[1];
  pcend := pc + (buflen * 2);
  pb := PByte(pbuf);
  b := 0;
  n := 0;
  while pc < pcend do
  begin
    c := pc^;
    if (c >= '0') and (c <= '9') then b += (ord(c) - ord('0'))
    else if (c >= 'A') and (c <= 'F') then b += (ord(c) - ord('A') + 10)
    else if (c >= 'a') and (c <= 'f') then b += (ord(c) - ord('a') + 10);
    if n >= 1 then
    begin
      pb^ := b;
      inc(pb);
      b := 0;
      n := 0;
    end
    else
    begin
      b := b shl 4;
      inc(n);
    end;
    inc(pc);
  end;
end;


{ TWaveData }

constructor TWaveData.Create(aname: string; asamplt: double);
begin
  name := aname;
  samplt := asamplt;
  startt := 0;
  data := [];
  dataunit := '';
  viewscale := 1;
  viewoffset := 0;
  color := $FFFFFFFF;
end;

destructor TWaveData.Destroy;
begin
  inherited Destroy;
end;

function TWaveData.DataCount: integer;
begin
  result := length(data);
end;

procedure TWaveData.AllocateData(asamples: cardinal);
begin
  SetLength(data, asamples);
end;

procedure TWaveData.SaveToJsonNode(jnode : TJsonNode);
var
  s : string;
  i : integer;
begin
  jnode := jnode.AsObject;  // forces the type of object
  jnode.Add('NAME', name);
  jnode.Add('SAMPLT', samplt);

  s := '';
  for i := 0 to length(data) - 1 do
  begin
    if i > 0 then s += '|';
    s += FloatToStr(data[i], float_number_format);  // uses always "." as decimal separator
  end;
  jnode.Add('VALUES', s);

  jnode.Add('STARTT', startt);
  jnode.Add('DATAUNIT', dataunit);

  jnode.Add('VIEWSCALE', viewscale);
  jnode.Add('VIEWOFFSET', viewoffset);
end;

function TWaveData.LoadFromJsonNode(jnode : TJsonNode) : boolean;
var
  jv : TJsonNode;
  rawdatastr : string;
begin
  result := false;
  if not jnode.Find('NAME', jv) then EXIT;
  name := jv.AsString;
  if not jnode.Find('SAMPLT', jv) then EXIT;
  samplt := jv.AsNumber;

  if not jnode.Find('VALUES', jv) then EXIT;

  rawdatastr := jv.AsString;
  LoadFloatArray(rawdatastr);

  // optional fields
  startt := 0;
  dataunit := '';
  viewscale := 1;
  viewoffset := 0;

  if jnode.Find('STARTT', jv)   then startt   := jv.AsNumber;
  if jnode.Find('DATAUNIT', jv) then dataunit := jv.AsString;

  // deprecated:
  if jnode.Find('DSCALE', jv)   then viewscale   := jv.AsNumber;
  if jnode.Find('DOFFSET', jv)  then viewoffset  := jv.AsNumber;

  if jnode.Find('VIEWSCALE', jv)   then viewscale   := jv.AsNumber;
  if jnode.Find('VIEWOFFSET', jv)  then viewoffset  := jv.AsNumber;


  DoOnDataUpdate;

  result := true;
end;

procedure TWaveData.SaveToJsonFile(afilename : string);
var
  jf : TJsonNode;
begin
  jf := TJsonNode.Create();
  try
    SaveToJsonNode(jf);
    jf.SaveToFile(afilename);
  finally
    jf.Free;
  end;
end;

function TWaveData.LoadFromJsonFile(afilename : string) : boolean;
var
  jf : TJsonNode;
begin
  result := False;
  jf := TJsonNode.Create;
  try
    jf.LoadFromFile(afilename);
    result := LoadFromJsonNode(jf);
  finally
    jf.Free;
  end;
end;

function TWaveData.EndTime : double;
begin
  result := startt + length(data) * samplt;
end;

procedure TWaveData.LoadFloatArray(astr : string);
var
  si, di : integer;
  s : string;
  c : char;

  procedure AppendToData(dstr : string);
  var
    v : double;
  begin
    if dstr <> '' then
    begin
      v := StrToFloatDef(dstr, 0, float_number_format);
      if di >= length(data) then SetLength(data, length(data) * 2);
      data[di] := v;
      inc(di);
    end;
  end;

begin
  SetLength(data, 16384); // preallocate some bigger array
  di := 0;

  si := 1;
  s := '';
  while si <= length(astr) do
  begin
    c := astr[si];
    if (c = '-') or ((c >= '0') and (c <= '9')) or (c = '.') or (c = 'e') or (c = 'E') then
    begin
      s := s + c;
    end
    else
    begin
      AppendToData(s);
      s := '';
    end;
    inc(si);
  end;

  AppendToData(s);

  SetLength(data, di);
end;

procedure TWaveData.DoOnDataUpdate;
begin
  // nothing here
end;

function TWaveData.GetDataIndex(t : double) : integer;
begin
  result := trunc((t - startt) / samplt);
  if (result < 0) or (result >= length(data))
  then
      result := -1;
end;

function TWaveData.NearestSampleTime(t : double) : double;
var
  di : integer;
begin
  di := GetDataIndex(t);
  result := GetDataIndexTime(di);
end;

function TWaveData.GetDataIndexTime(di : integer) : double;
begin
  if (di < 0) or (di >= length(data))
  then
      EXIT(NaN);

  result := startt + di * samplt;
end;

function TWaveData.GetValueAt(t : double) : double;
var
  di : integer;
  ddi : double;
begin
  ddi := (t - startt) / samplt;
  di := trunc(ddi); // TODO: make interpolation
  if (di < 0) or (di >= length(data))
  then
      result := 0
  else
      result := data[di];
end;

function TWaveData.GetValueStr(t : double) : string;
begin
  result := FloatToStr(GetValueAt(t), float_number_format);
end;

procedure TWaveData.CalcMinMax(fromtime, totime : double; out data_min : double; out data_max : double; out scnt : integer);
var
  di, dito : integer;
  d : double;
begin

  di   := Ceil( (fromtime - startt) / samplt );
  dito := Floor( (totime - startt) / samplt );

  scnt := 0;
  data_min := 0;
  data_max := 0;

  if di < 0 then di := 0;
  while di <= dito do
  begin
    d := data[di];
    if scnt = 0 then
    begin
      data_min := d;
      data_max := d;
    end
    else
    begin
      if d < data_min then data_min := d;
      if d > data_max then data_max := d;
    end;
    inc(di);
    inc(scnt);
  end;
end;

function TWaveData.FindNearestScale(ascale : double) : double;
var
  log10_scale : double;
  log10_int_scale : double;
  smul : double;
begin
  log10_scale := log10(ascale);
  log10_int_scale := trunc(log10_scale);
  if log10_scale < 0 then  // 0 < ascale < 1
  begin
    smul := power(10, log10_int_scale) / ascale;
    if      smul > 5 then smul := 10
    else if smul > 2 then smul := 5
    else if smul > 1 then smul := 2
    else                  smul := 1;

    result := power(10, log10_int_scale) / smul;
  end
  else  // ascale >= 1
  begin
    smul := ascale / power(10, log10_int_scale);
    if      smul > 5 then smul := 10
    else if smul > 2 then smul := 5
    else if smul > 1 then smul := 2
    else                  smul := 1;

    result := power(10, log10_int_scale) * smul;
  end;
end;

function TWaveData.ScalingStr : string;
var
  invsc : double;
  log10_scale : double;
begin
  invsc := 1 / viewscale;
  log10_scale := log10(invsc);

  if log10_scale >= 0 then
  begin
    result := format('%.0f', [invsc]);
  end
  else
  begin
    result := format('%.'+IntToStr(Ceil(-log10_scale))+'f', [invsc]);
  end;
end;

{ TScopeData }

constructor TScopeData.Create;
begin
  waves := TWaveDataList.Create;
end;

destructor TScopeData.Destroy;
begin
  ClearWaves;
  inherited Destroy;
end;

function TScopeData.AddWave(aname: string; asamplt: double) : TWaveData;
begin
  result := TWaveData.Create(aname, asamplt);
  waves.Add(result);
end;

function TScopeData.DeleteWave(awave : TWaveData) : boolean;
begin
  if waves.Extract(awave) <> nil then
  begin
    awave.Free;
    result := True;
  end
  else result := False;
end;

procedure TScopeData.ClearWaves;
var
  ch : TWaveData;
begin
  for ch in waves do ch.Free;
  waves.Clear;
end;

procedure TScopeData.SaveToJsonFile(afilename : string);
var
  jf : TJsonNode;
  w  : TWaveData;
  jwarr, jn : TJSonNode;
begin
  jf := TJsonNode.Create();

  jwarr := jf.Add('WAVES', nkArray);
  for w in waves do
  begin
    jn := jwarr.Add();
    w.SaveToJsonNode(jn);
  end;

  try
    jf.SaveToFile(afilename);
  finally
    jf.Free;
  end;
end;

procedure TScopeData.LoadFromJsonFile(afilename : string);
var
  jf : TJsonNode;
  w  : TWaveData = nil;
  i  : integer;
  jwarr, jn : TJSonNode;
begin
  jf := TJsonNode.Create();
  try
    jf.LoadFromFile(afilename);
    if not jf.Find('WAVES', jwarr)
    then
        raise Exception.Create('Error loading scope data: no WAVES node was found.');

    for i := 0 to jwarr.Count - 1 do
    begin
      jn := jwarr.Child(i);
      w := AddWave('???', 1/1000);
      if not w.LoadFromJsonNode(jn) then
      begin
        DeleteWave(w);
      end;
      w := nil;
    end;
  finally
    if w <> nil then DeleteWave(w);
    jf.Free;
  end;
end;

initialization
begin
  float_number_format.DecimalSeparator := '.';
  float_number_format.ThousandSeparator := chr(0);
end;

end.

