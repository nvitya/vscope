unit wave_processing;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, vscope_data, vscope_display, strparseobj;

type

  EWaveProcess = class(Exception)

  end;

  { TWaveProcessor }

  TWaveProcessor = class
  public
    expr : ansistring;
    sp   : TStrParseObj;
    arg  : array of double;
    wd   : TWaveDisplay;

    procedure Run(awd : TWaveDisplay; aexpr : ansistring);

    procedure ReadArguments;

  public
    procedure ExecSclale();
    procedure ExecOffset();
    procedure ExecMovAvg();
  end;

implementation

uses
  uFilters;

{ TWaveProcessor }

procedure TWaveProcessor.Run(awd : TWaveDisplay; aexpr : ansistring);
var
  ids : ansistring;
begin
  wd := awd;
  expr := aexpr;
  sp.Init(expr);

  sp.SkipWhite;

  while sp.readptr < sp.bufend do
  begin
    if not sp.ReadIdentifier()
    then
      raise EWaveProcess.Create('Identifier is missing');

    ids := UpperCase(sp.PrevStr());

    ReadArguments;

    if      'SCALE'     = ids then ExecSclale()
    else if 'OFFSET'    = ids then ExecOffset()
    else if ('MOVAVG' = ids) or ('MOVINGAVERAGE' = ids) then ExecMovAvg()
    else
    begin
      raise EWaveProcess.Create('Unknown identifier: "'+ids+'"');
    end;

    sp.SkipWhite();
    sp.CheckSymbol(';');  // skip the optional semicolon
    sp.SkipWhite();
  end;
end;

procedure TWaveProcessor.ReadArguments;
var
  s : ansistring;
  v : double;
begin
  SetLength(arg, 0);

  sp.SkipWhite();
  if not sp.CheckSymbol('(') then
    raise EWaveProcess.Create('"(" is missing');

  // read arguments

  while sp.readptr < sp.bufend do
  begin
    if sp.CheckSymbol(')') then EXIT;  // arguments finished.

    s := '';
    sp.SkipWhite();
    if not sp.ReadTo('),; '#13#10#9) then
      raise EWaveProcess.Create('Argument error');
    s := sp.PrevStr();
    v := StrToFloat(s);
    SetLength(arg, length(arg) + 1);
    arg[length(arg) - 1] := v;

    sp.SkipWhite();
    sp.CheckSymbol(',');
    sp.CheckSymbol(';');

    sp.SkipWhite();
  end;

end;

procedure TWaveProcessor.ExecSclale;
var
  factor : double;
  i, len : integer;
begin
  if length(arg) < 1 then raise EWaveProcess.Create('SCALE argument is missing');
  factor := arg[0];
  len := length(wd.data);
  for i := 0 to len - 1 do
  begin
    wd.data[i] := wd.data[i] * factor;
  end;
end;

procedure TWaveProcessor.ExecOffset;
var
  offset : double;
  i, len : integer;
begin
  if length(arg) < 1 then raise EWaveProcess.Create('OFFSET argument is missing');
  offset := arg[0];
  len := length(wd.data);
  for i := 0 to len - 1 do
  begin
    wd.data[i] := wd.data[i] + offset;
  end;
end;

procedure TWaveProcessor.ExecMovAvg();
var
  samples : integer;
  i, len : integer;
begin
  if length(arg) < 1 then raise EWaveProcess.Create('MOVAVG argument is missing');
  samples := trunc(arg[0]);
  MovingAverageFilter(wd.data, samples);
end;

end.

