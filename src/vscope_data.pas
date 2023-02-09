unit vscope_data;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fgl, jsontools;

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

    function GetValueAt(t : double) : double;
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

implementation

const
  hexchar_array : array of char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');

var
  float_number_format : TFormatSettings;

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
  jnode.Add('DSCALE', viewscale);
  jnode.Add('DOFFSET', viewoffset);
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
  try
    jwarr := jf.Add('WAVES', nkArray);
    for w in waves do
    begin
      jn := jwarr.Add();
      w.SaveToJsonNode(jn);
    end;
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

