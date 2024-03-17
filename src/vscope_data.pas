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
  Classes, SysUtils, fgl, math, jsontools, util_nstime;

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

    visible     : boolean;
    groupid     : integer;
    viewscale   : double;  // display scale
    viewoffset  : double;  // display offset

    color  : cardinal;
    basealpha : single;

    bin_storage_type : byte;  // for the binary format

    raw_data_scale : double;

    run_autoscale : boolean;

    constructor Create(aname: string; asamplt: double);
    destructor Destroy; override;
    function DataCount : integer;

    procedure CopyFrom(srcwave : TWaveData);

    procedure AllocateData(asamples : cardinal);

    procedure SaveToJsonNode(jnode : TJsonNode; binary_data : boolean);
    procedure SaveToJsonFile(afilename : string);
    function LoadFromJsonNode(jnode : TJsonNode) : boolean;
    function LoadFromJsonFile(afilename : string) : boolean;

    property StartTime : double read startt;
    function EndTime : double;

    procedure LoadFloatArray(astr : string);  // for data load
    function  GetFloatArrayStr : string;      // for data save

    procedure DoOnDataUpdate; virtual;

    function GetDataIndex(t : double) : integer;  // warning: it might be out of bounds !
    function NearestSampleTime(t : double) : double;
    function GetDataIndexTime(di : integer) : double;
    function GetValueAt(t : double) : double;
    function GetValueStr(t : double) : string;
    function FormatValue(v : double) : string;

    procedure CalcMinMax(fromtime, totime : double; out data_min : double; out data_max : double; out scnt : integer);

    function FindNearestScale(ascale : double) : double;
    function ScalingStr : string;

    procedure CutData(fromtime, totime : double);

  end;

  TWaveDataList = specialize TFPGList<TWaveData>;

  { TScopeData }

  TScopeData = class
  public
    jroot : TJsonNode;

    waves : TWaveDataList;
    time_unit   : string;
    binary_data : boolean;

    constructor Create;
    destructor Destroy; override;

    function AddWave(aname: string; asamplt: double): TWaveData;
    function DeleteWave(awave : TWaveData) : boolean;

    procedure ClearWaves;

    procedure LoadFromFile(afilename : string);
    procedure SaveToFile(afilename : string);

  private
    fdata  : array of byte;  // local buffer
  end;


procedure HexStrToBuffer(const astr : string; pbuf : pointer; buflen : cardinal);
function  BufferToHexStr(pbuf : pointer; len : cardinal) : string;

function FormatTime(t : double) : string;

var
  float_number_format : TFormatSettings;

implementation

uses
  vscope_bin_file;

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

function FormatTime(t : double) : string;
begin
  result := FloatToStrF(t, ffFixed, 0, 6, float_number_format);
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
  visible := true;
  groupid := 1;
  viewscale := 1;
  viewoffset := 0;
  basealpha := 0.8;
  color := $FFFFFFFF;
  bin_storage_type := $28;  // $28 = double, $12 = int16, $14 = int32
  raw_data_scale := 1;
  run_autoscale := true;
end;

destructor TWaveData.Destroy;
begin
  inherited Destroy;
end;

function TWaveData.DataCount: integer;
begin
  result := length(data);
end;

procedure TWaveData.CopyFrom(srcwave : TWaveData);
begin
  self.startt     := srcwave.startt;
  self.dataunit   := srcwave.dataunit;
  self.viewscale  := srcwave.viewscale;
  self.viewoffset := srcwave.viewoffset;
  self.basealpha  := srcwave.basealpha;
  self.color      := srcwave.color;
  self.data       := copy(srcwave.data);

  self.DoOnDataUpdate;
end;

procedure TWaveData.AllocateData(asamples: cardinal);
begin
  SetLength(data, asamples);
end;

procedure TWaveData.SaveToJsonNode(jnode : TJsonNode; binary_data : boolean);
begin
  jnode := jnode.AsObject;  // forces the type of object
  jnode.Add('NAME', name);
  jnode.Add('SAMPLT', samplt);

  if not binary_data
  then
     jnode.Add('VALUES', GetFloatArrayStr());

  jnode.Add('STARTT', startt);
  jnode.Add('DATAUNIT', dataunit);
  if raw_data_scale <> 1 then jnode.Add('RAW_DATA_SCALE', raw_data_scale);

  jnode.Add('COLOR', color);
  jnode.Add('ALPHA', basealpha);
  jnode.Add('VISIBLE', visible);
  jnode.Add('GROUPID', groupid);

  if not run_autoscale or (viewscale <> 1) or (viewoffset <> 0) then
  begin
    jnode.Add('VIEWSCALE', viewscale);
    jnode.Add('VIEWOFFSET', viewoffset);
  end;
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

  if jnode.Find('VALUES', jv) then  // not existing for binary files
  begin
    rawdatastr := jv.AsString;
    LoadFloatArray(rawdatastr);
  end;

  // optional fields
  startt := 0;
  dataunit := '';
  viewscale := 1;
  viewoffset := 0;
  raw_data_scale := 1;
  color := $FFFFFFFF;
  run_autoscale := true;

  if jnode.Find('STARTT', jv)   then startt   := jv.AsNumber;
  if jnode.Find('DATAUNIT', jv) then dataunit := jv.AsString;
  if jnode.Find('RAW_DATA_SCALE', jv) then raw_data_scale := jv.AsNumber;
  if jnode.Find('COLOR', jv)    then color    := trunc(jv.AsNumber);
  if jnode.Find('ALPHA', jv)    then basealpha:= jv.AsNumber;
  if jnode.Find('VISIBLE', jv)  then visible  := jv.AsBoolean;
  if jnode.Find('GROUPID', jv)  then groupid  := trunc(jv.AsNumber);

  if jnode.Find('VIEWSCALE', jv) or jnode.Find('DSCALE', jv) then    // (DSCALE is deprecated)
  begin
    viewscale   := jv.AsNumber;
    run_autoscale := false;
  end;

  if jnode.Find('VIEWOFFSET', jv) or jnode.Find('DOFFSET', jv) then  // (DOFFSET is deprecated)
  begin
    viewoffset  := jv.AsNumber;
    run_autoscale := false;
  end;

  DoOnDataUpdate;

  result := true;
end;

procedure TWaveData.SaveToJsonFile(afilename : string);
var
  jf : TJsonNode;
begin
  jf := TJsonNode.Create();
  try
    SaveToJsonNode(jf, false);
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

{$if 1}

procedure TWaveData.LoadFloatArray(astr : string);
var
  di : integer;
  s : string[48];
  c : char;
  pc, pend : PChar;
  hasvalue : boolean;

  nsign, esign : double;

  digit : double;
  fracmul : double;
  nv, ev : double;

  mode : integer;  // 0 = integer part, 1 = fractional part, 2 = exponent

  t0, t1 : int64;

  procedure AppendToData;
  var
    v : double;
  begin
    if s <> '' then
    begin
      v := StrToFloatDef(s, 0, float_number_format);
      if di >= length(data) then SetLength(data, length(data) * 2);
      data[di] := v;
      inc(di);
    end;
  end;

  procedure Reset;
  begin
    nsign := 1;
    esign := 1;
    fracmul := 1;
    nv := 0;
    ev := 0;
    mode := 0;
    hasvalue := false;
  end;

begin

  if length(astr) < 1 then
  begin
    data := [];
    EXIT;
  end;

  // optimized parser for huge amount of floating point numbers

  t0 := nstime();

  SetLength(data, 1024 * 1024); // preallocate some bigger array
  di := 0;

  pc := @astr[1];
  pend := pc + length(astr);

  Reset;

  hasvalue := false;
  s := '';
  while pc < pend do
  begin
    c := pc^;
    if '-' = c then
    begin
      if 2 = mode then esign := -1
                  else nsign := -1;
    end
    else if (c >= '0') and (c <= '9') then
    begin
      digit := ord(c) - ord('0');
      if 1 = mode then // fractional part
      begin
        fracmul := fracmul * 0.1;
        nv := nv + digit * fracmul;
      end
      else if 2 = mode then  // exponential integer
      begin
        ev := ev * 10 + digit;
      end
      else  // integer part
      begin
        nv := nv * 10 + digit;
      end;
      hasvalue := true;
    end
    else if '.' = c then
    begin
      mode := 1; // change to fractional mode
    end
    else if ('e' = c) or ('E' = c) then
    begin
      mode := 2; // change to exponential mode
    end
    else
    begin
      // close the number
      if di >= length(data) then SetLength(data, length(data) * 2);
      data[di] := nsign * nv * Power(10, esign * ev);
      inc(di);
      Reset;
    end;

    inc(pc);
  end;

  if hasvalue then
  begin
    if di >= length(data) then SetLength(data, length(data) * 2);
    data[di] := nsign * nv * Power(10, esign * ev);
    inc(di);
  end;

  SetLength(data, di);

  t1 := nstime();
  {$ifdef TRACES}
  writeln('Wave data parsing time: ',(t1 - t0)/1000 :0:3, ' us');
  {$endif}

  if t0 + t1 <> 0 then ; // to suppress unused warning
end;

function TWaveData.GetFloatArrayStr : string;
var
  s : string;
  sv : string[48];
  i, si : integer;
  t0, t1 : int64;
begin
  // somewhat optimizied for memory allocations,
  // but still using the FloatToStr() which is relative slow for huge amount of numbers

  t0 := nstime();
  s := '';
  SetLength(s, 1024 * 1024);
  si := 1;
  for i := 0 to length(data) - 1 do
  begin
    if si + 48 > length(s) then
    begin
      SetLength(s, length(s) * 2);
    end;
    if i > 0 then
    begin
      s[si] := '|';
      inc(si);
    end;
    sv := FloatToStr(data[i], float_number_format);  // uses always "." as decimal separator
    move(sv[1], s[si], length(sv));
    inc(si, length(sv));
  end;

  SetLength(s, si - 1);

  t1 := nstime();
  {$ifdef TRACES}
  writeln('Wave VALUES String gererate time: ', (t1 - t0) / 1000 :0:0, ' us');
  {$endif}

  if t0 + t1 <> 0 then ; // to suppress unused warning

  result := s;
end;

{$else}

procedure TWaveData.LoadFloatArray(astr : string);
var
  si, di : integer;
  s : string;
  c : char;

  t0, t1 : int64;

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

  t0 := nstime();

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

  t1 := nstime();
  {$ifdef TRACES}
  writeln('Wave data parsing time: ',(t1 - t0)/1000 :0:3, ' us');
  {$endif}
end;

{$endif}

procedure TWaveData.DoOnDataUpdate;
begin
  // nothing here
end;

function TWaveData.GetDataIndex(t : double) : integer;
begin
  result := trunc((t - startt) / samplt);
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
{
  if (di < 0) or (di >= length(data))
  then
      EXIT(NaN);
}
  result := startt + di * samplt;
end;

function TWaveData.GetValueAt(t : double) : double;
var
  di : integer;
  ddi : double;
begin
  ddi := (t - startt) / samplt;
  di := round(ddi); // TODO: make interpolation
  if (di < 0) or (di >= length(data))
  then
      result := 0
  else
      result := data[di];
end;

function TWaveData.GetValueStr(t : double) : string;
begin
  result := FormatValue(GetValueAt(t));
end;

function TWaveData.FormatValue(v : double) : string;
var
  sarr : array of string;
begin

  result := FloatToStr(v, float_number_format);
  if pos(UpperCase(result), 'E') = 0 then
  begin
    // limit the precision to 8 digits
    sarr := result.split('.');
    if (length(sarr) > 1) and (length(sarr[1]) > 8)
    then
        result := FloatToStrF(v, ffFixed, 0, 8, float_number_format);
  end;

  if dataunit <> '' then result += ' ' + dataunit;
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
  if dito >= length(data) then dito := length(data) - 1;

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

  if dataunit <> '' then result := result + ' ' + dataunit;
end;

procedure TWaveData.CutData(fromtime, totime : double);
var
  d : double;
  fromdi, todi, cnt : integer;
begin
  if fromtime > totime then  // swap them
  begin
    d := fromtime;
    fromtime := totime;
    totime := d;
  end;

  fromdi := trunc((fromtime - startt) / samplt);
  if fromdi < 0 then fromdi := 0;
  todi := trunc((totime - startt) / samplt);
  if todi > length(data) then todi := length(data);
  if todi < 0 then todi := 0;
  cnt := todi - fromdi;

  if cnt <= 0 then EXIT;

  // delete from the end first
  if todi < length(data) then SetLength(data, todi);

  // then from the beginning
  if fromdi > 0 then
  begin
    delete(data, 0, fromdi);
    startt += fromdi * samplt;  // maintain the time position
  end;

  DoOnDataUpdate;
end;

{ TScopeData }

constructor TScopeData.Create;
begin
  jroot := TJsonNode.Create;
  waves := TWaveDataList.Create;
  binary_data := false;
  time_unit := 's';
  SetLength(fdata, 256 * 1024); // allocate a static data buffer
end;

destructor TScopeData.Destroy;
begin
  ClearWaves;
  SetLength(fdata, 0);
  jroot.Free;
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

procedure TScopeData.LoadFromFile(afilename : string);
var
  i : integer;
  brec : TVscopeBinRec; // to shorten some lines
  jstr : ansistring = '';

  run_autoscale : boolean;

  wd : TWaveData;

  jf, jwlist, jw : TJsonNode;
  jn : TJsonNode;
  jview, jv : TJsonNode;
  jmarkers : TJsonNode;

  fbfile : TVscopeBinFile = nil;
begin
  jroot.Clear;
  ClearWaves;

  try
    binary_data := (UpperCase(ExtractFileExt(afilename)) = '.BSCOPE');
    if binary_data then
    begin
      fbfile := TVscopeBinFile.Create;
      fbfile.Open(afilename);
      brec := fbfile.currec;
      if brec.marker <> 'J'
      then
          raise EScopeData.Create('J-Record is missing!');

      if brec.addinfo > 64000
      then
          raise EScopeData.Create('J-Record is too long: '+IntToStr(brec.addinfo));

      SetLength(jstr, brec.addinfo);
      move(brec.dataptr^, jstr[1], brec.addinfo);

      jroot.Parse(jstr);
    end
    else
    begin
      jroot.LoadFromFile(afilename);
    end;

    run_autoscale := true;

    jwlist := jroot.Find('WAVES');
    if jwlist = nil
    then
        raise EScopeData.Create('Scope data format error: "WAVES" node not found.');

    for i := 0 to jwlist.Count - 1 do
    begin
      jw := jwlist.Child(i);
      wd := AddWave('???', 1/1000);
      if wd.LoadFromJsonNode(jw)
      then
          run_autoscale := (run_autoscale and wd.run_autoscale)
      else
          DeleteWave(wd);

      jw.Add('VALUES', '');  // clear the wave data, as it might require lot of RAM
    end;

    if binary_data then
    begin
      fbfile.ClearWaves();
      for wd in waves do  fbfile.AddWave(wd);

      fbfile.LoadWaveData();
    end;

    // MARKERS and some VIEW fields are not loaded here.

  finally
    if fbfile <> nil then FreeAndNil(fbfile);
  end;
end;

procedure TScopeData.SaveToFile(afilename : string);
var
  wd    : TWaveData;
  jview : TJsonNode;
  //jmarkers : TJsonNode;
  jwarr, jn : TJSonNode;
  fbfile : TVscopeBinFile = nil;
begin
  binary_data := (UpperCase(ExtractFileExt(afilename)) = '.BSCOPE');

  if not jroot.Find('VIEW', jview) then jview := jroot.Add('VIEW', nkObject);
  jview.Add('TIMEUNIT', time_unit);

  //jview.Add('TIMEDIV', TimeDiv);
  //jview.Add('VIEWSTART', ViewStart);
  //jview.Add('DRAWSTEPS', draw_steps);

  (*
  jmarkers := jf.Add('MARKERS', nkArray);
  for i := 0 to 1 do
  begin
    jn := jmarkers.Add();
    jn.Add('VISIBLE', marker[i].Visible);
    jn.Add('MTIME',   marker[i].mtime);
  end;
  *)

  jwarr := jroot.Add('WAVES', nkArray);
  jwarr.Clear;
  for wd in waves do
  begin
    jn := jwarr.Add();
    wd.SaveToJsonNode(jn, binary_data);
  end;

  try
    if binary_data then
    begin
      fbfile := TVscopeBinFile.Create;
      fbfile.ClearWaves();
      for wd in waves do  fbfile.AddWave(wd);
      fbfile.Save(afilename, jroot);
    end
    else
    begin
      jroot.SaveToFile(afilename);
    end;
  finally
    if fbfile <> nil then FreeAndNil(fbfile);
  end;
end;

initialization
begin
  float_number_format.DecimalSeparator := '.';
  float_number_format.ThousandSeparator := chr(0);
end;

end.

