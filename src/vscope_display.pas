unit vscope_display;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, fgl, math, jsontools, dglOpenGL, ddgfx, ddgfx_font, vscope_data;

const
  vscope_timedivs : array of double =
  (
    0.000001,  // 1 us
    0.000002,
    0.000005,
    0.000010,
    0.000020,
    0.000050,
    0.000100,
    0.000200,
    0.000500,
    0.001000,  // 1 ms
    0.002000,
    0.005000,
    0.010000,
    0.020000,
    0.050000,
    0.100000,
    0.200000,
    0.500000,
    1.000000,  // 1 s
    2.000000,
    5.000000,
    10.000000,
    20.000000,
    50.000000,
    100.000000,
    200.000000,
    500.000000,
    1000.000000  // 1000 s
  );

type

  TScopeDisplay = class;

  { TWaveDisplay }

  TWaveDisplay = class(TWaveData)
  public
    wshp : TShape;
    scope : TScopeDisplay;

    constructor Create(ascope: TScopeDisplay; aname: string; asamplt: double); reintroduce;
    destructor Destroy; override;

    procedure SetColor(acolor : cardinal);

    procedure ReDrawWave;

    procedure AutoScale;
    procedure CorrectOffset;

    procedure DoOnDataUpdate; override;
  end;

  TWaveDisplayList = specialize TFPGList<TWaveDisplay>;

  { TScopeDisplay }

  TScopeDisplay = class(TddScene)
  private
    function GetTimeDiv : double;
    procedure SetViewStart(AValue : double);
    procedure SetViewRange(AValue : double);
  protected
    fmargin_pixels : integer;

    fmintime   : double;
    fmaxtime   : double;
    ftimerange : double;
    fViewstart : double;
    fviewrange : double;

    procedure CalcTimeRange;

  protected
    grid_frame : TShape;
    grid_vline : TShape;
    grid_hline : TShape;
    grid  : TDrawGroup;
    grid_main : TDrawGroup;
    grid_sub  : TDrawGroup;

    procedure InitGrid;
    procedure CleanupGrid;

  public
    vfont : TFontFace;

    valtxt    : TTextBox;
    valgrp    : TDrawGroup;
    valframe  : TShape;

  public

    timecursor : TShape;

  public
    procedure DoOnResize; override;

    procedure RenderWaves;

  public
    data  : TScopeData;
    wgrp  : TDrawGroup;
    waves : TWaveDisplayList;

    draw_steps : boolean;

    constructor Create(aowner : TComponent; aparent : TWinControl); override;
    destructor Destroy; override;

    procedure ClearWaves;

    procedure AutoScale;

    function AddWave(aname: string; asamplt: double): TWaveDisplay;
    function DeleteWave(awave : TWaveDisplay) : boolean;

    function LoadWave(afilename : string) : TWaveDisplay;

    procedure LoadScopeFile(afilename : string);
    procedure SaveScopeFile(afilename : string);

    function ConvertXToTime(x : integer) : double;
    procedure SetTimeCursor(t : double);

    property TimeRange : double read ftimerange;
    property MinTime : double read fmintime;
    property MaxTime : double read fmaxtime;

    property ViewStart : double read fviewstart write SetViewStart;
    property ViewRange : double read fviewrange write SetViewRange;
    function ViewEnd   : double;
    property TimeDiv   : double read GetTimeDiv;

    procedure SetTimeDiv(AValue : double; fixtimepos : double);
  end;


const
  default_wave_colors : array[0..7] of cardinal = (
  // aabbggrr
    $FF00FFFF,
    $FFFC7307,
    $FF40FF40,
    $FFFF00FF,

    $FF0773FC,
    $FFFF4040,
    $FF208020,
    $FF802080
  );

function  FindNextTimeDiv(adiv : double; adir : integer) : double;

implementation

function FindNextTimeDiv(adiv : double; adir : integer) : double;
var
  tdi : integer;
begin
  if adir > 0 then
  begin
    tdi := 0;
    while tdi < length(vscope_timedivs) do
    begin
      result := vscope_timedivs[tdi];
      if result > adiv
      then
          EXIT;

      Inc(tdi);
    end;
  end
  else
  begin
    tdi := length(vscope_timedivs) - 1;
    while tdi >= 0 do
    begin
      result := vscope_timedivs[tdi];
      if result < adiv
      then
          EXIT;

      Dec(tdi);
    end;
  end;
end;


{ TWaveDisplay }

constructor TWaveDisplay.Create(ascope: TScopeDisplay; aname: string; asamplt: double);
begin
  inherited Create(aname, asamplt);
  scope := ascope;
  wshp := scope.wgrp.NewShape();
  wshp.scaley := -1;
  wshp.y := 5;
end;

destructor TWaveDisplay.Destroy;
begin
  inherited Destroy;
end;

procedure TWaveDisplay.SetColor(acolor : cardinal);
begin
  color := acolor;
  wshp.SetColor(
    ((color shr  0) and $FF) / 255,
    ((color shr  8) and $FF) / 255,
    ((color shr 16) and $FF) / 255,
    ((color shr 24) and $FF) / 255
  );
  wshp.alpha := 0.5;
end;

procedure TWaveDisplay.ReDrawWave;
var
  i : integer;
  di,  maxdi : integer; // data index
  //ddi : double;
  vi  : integer; // vertex index
  varr : array of TVertex;
  v : TVertex;
  vcnt : integer;
  t : double;
  x, dx : double;
begin
  vi := 0;
  dx := samplt / scope.TimeDiv;

  di := trunc((scope.ViewStart - startt) / samplt);
  if di < 0 then
  begin
    di := 0;
  end;

  t := startt + di * samplt;
  x := (t - scope.ViewStart) / scope.TimeDiv;
  if x < 0 then
  begin
    i := Ceil(-x / dx);
    di += i;
    x += dx * i;
  end;

  maxdi := length(data);
  if maxdi < 0 then maxdi := 0;

  varr := [];
  vcnt := maxdi - di;
  if scope.draw_steps then vcnt *= 2;
  SetLength(varr, vcnt);

  while (di < maxdi) and (x < 10) do
  begin
    v[0] := x;

    v[1] := data[di] * viewscale + viewoffset;
    // clamping the Y:
    if v[1] > 5 then v[1] := 5
    else if v[1] < -5 then v[1] := -5;

    if scope.draw_steps and (vi > 0) then
    begin
      varr[vi][0] := x;
      varr[vi][1] := varr[vi-1][1];
      Inc(vi);
    end;

    varr[vi] := v;

    inc(di);
    inc(vi);
    x += dx;
  end;

  wshp.Clear; // removes all primitives
  wshp.AddPrimitive(GL_LINE_STRIP, vi, @varr[0]);

  varr := [];
end;

procedure TWaveDisplay.AutoScale;
var
  ddiff : double;
  data_min, data_max : double;
  scnt : integer;
begin
  CalcMinMax(startt, EndTime, data_min, data_max, scnt);

  ddiff := (data_max - data_min);
  if ddiff < 0.001 then ddiff := 0.001;

  viewscale := FindNearestScale(10 / ddiff);
  viewoffset := -5 - data_min * viewscale
end;

procedure TWaveDisplay.CorrectOffset;
var
  ddiff : double;
  data_min, data_max : double;
  scnt : integer;
begin
  CalcMinMax(scope.ViewStart, scope.ViewEnd, data_min, data_max, scnt);

  if      data_min * viewscale > 5  then viewoffset := 5 - data_max * viewscale
  else if data_max * viewscale < -5 then viewoffset := -5 - data_min * viewscale;
end;

procedure TWaveDisplay.DoOnDataUpdate;
var
  ci : integer;
begin
  ReDrawWave;

  if color = $FFFFFFFF then // if no color was set
  begin
    ci := (scope.waves.Count - 1) mod 8;
    SetColor(default_wave_colors[ci]);
  end;
end;

{ TScopeDisplay }

constructor TScopeDisplay.Create(aowner : TComponent; aparent : TWinControl);
const
  frame_vertices : array[0..3] of TVertex = ((0, 0),(1,0),(1,1),(0, 1));
begin
  inherited;

  InitFontManager;
  vfont := fontmanager.GetFont('vscope_font.ttf');

  fmargin_pixels := 32;

  data := TScopeData.Create;
  grid := root.NewGroup;
  grid.x := fmargin_pixels;
  grid.y := fmargin_pixels;

  wgrp := root.NewGroup;
  wgrp.x := fmargin_pixels;
  wgrp.y := fmargin_pixels;

  waves := TWaveDisplayList.Create;


  valgrp := root.NewGroup;

  valframe := valgrp.NewShape;
  valframe.AddPrimitive(GL_TRIANGLE_FAN, 4, @frame_vertices);
  valframe.SetColor(0.2, 0.2, 0.5, 0.7);

  valtxt := TTextBox.Create(valgrp, vfont.GetSizedFont(9), 'Value Sample Text');
  valgrp.x := 50;
  valgrp.y := 150;
  valframe.x := -2;
  valframe.y := -2;
  valframe.scalex := valtxt.Width + 4;
  valframe.scaley := valtxt.Height + 4;


  fviewstart := 0;
  fviewrange := 1;
  CalcTimeRange; // initialize the time range

  bgcolor.r := 0.1;
  bgcolor.g := 0.1;
  bgcolor.b := 0.1;

  draw_steps := false;

  InitGrid;
end;

destructor TScopeDisplay.Destroy;
begin
  ClearWaves;

  data.Free;
  inherited;
end;

procedure TScopeDisplay.DoOnResize;
begin
  inherited DoOnResize;

  grid.scalex := (self.width - 1 - 2 * fmargin_pixels)  / 10;
  grid.scaley := (self.height - 1 - 2 * fmargin_pixels) / 10;

  wgrp.scalex := grid.scalex;
  wgrp.scaley := grid.scaley;

end;

procedure TScopeDisplay.RenderWaves;
var
  w : TWaveDisplay;
begin
  for w in waves do w.DoOnDataUpdate;
end;

procedure TScopeDisplay.InitGrid;
const
  frame_vertices : array[0..4] of TVertex = ((0, 0),(10,0),(10,10),(0, 10),(0,0));
  hline_vertices : array[0..1] of TVertex = ((0, 0),(10,0));
  vline_vertices : array[0..1] of TVertex = ((0, 0),(0,10));
var
  n : integer;
  vsh, hsh : TShape;
  cs : TClonedShape;
  px, py, d : double;
begin
  grid.scalex := 100;
  grid.scaley := 100;

  grid_sub  := grid.NewGroup();  // define sub first to be on a lower level (drawn first)
  grid_main := grid.NewGroup();

  // main lines

  grid_frame := grid_main.NewShape();
  grid_frame.AddPrimitive(GL_LINE_STRIP, 5, @frame_vertices);
  grid_frame.SetColor(0.5, 0.5, 0.5);
  grid_frame.visible := false;

  grid_hline := grid_main.NewShape();
  grid_hline.AddPrimitive(GL_LINES, 2, @hline_vertices);
  grid_hline.y := 5;
  grid_hline.SetColor(0.5, 0.5, 0.5);
  grid_hline.visible := false;

  grid_vline := grid_main.NewShape();
  grid_vline.AddPrimitive(GL_LINES, 2, @vline_vertices);
  grid_vline.x := 5;
  grid_vline.color := grid_hline.color;
  grid_vline.visible := false;

  // sub lines

  d := 1;
  px := 0;
  py := 0;

  hsh := grid_sub.NewShape();
  hsh.AddPrimitive(GL_LINES, 2, @hline_vertices);
  hsh.y := py;
  hsh.SetColor(0.2, 0.2, 0.2);

  vsh := grid_sub.NewShape();
  vsh.AddPrimitive(GL_LINES, 2, @vline_vertices);
  vsh.x := px;
  vsh.color := hsh.color;

  for n := 1 to 10 do
  begin
    px += d;
    py += d;

    if true then //n <> 4 then
    begin
      cs := grid_sub.CloneShape(vsh);
      cs.x := px;

      cs := grid_sub.CloneShape(hsh);
      cs.y := py;
    end;
  end;

  timecursor := grid.NewShape();
  timecursor.AddPrimitive(GL_LINES, 2, @vline_vertices);
  timecursor.x := 1.5;
  timecursor.SetColor(1, 0.5, 0.5);
  timecursor.alpha := 0.3;
  timecursor.visible := true;

end;

procedure TScopeDisplay.CleanupGrid;
begin
  //
end;


function TScopeDisplay.GetTimeDiv : double;
begin
  result := fviewrange / 10;
end;

procedure TScopeDisplay.SetViewRange(AValue : double);
begin
  if fviewrange = AValue then Exit;
  fviewrange := AValue;
  RenderWaves;
end;

procedure TScopeDisplay.SetTimeDiv(AValue : double; fixtimepos : double);
var
  //fviewmid : double;
  ftimeratio : double;
begin
  //fviewmid := fviewstart + fviewrange / 2;

  ftimeratio := (fixtimepos - fviewstart) / fviewrange;

  fviewrange := AValue * 10;

  fviewstart := fixtimepos - fviewrange * ftimeratio;
  //fviewstart := fviewmid - fviewrange / 2;

  RenderWaves;
end;

procedure TScopeDisplay.SetViewStart(AValue : double);
begin
  if fviewstart = AValue then Exit;
  fviewstart := AValue;

  RenderWaves;
end;

procedure TScopeDisplay.CalcTimeRange;
var
  n : integer = 0;
  w : TWaveDisplay;
begin
  fmintime := 0;
  fmaxtime := 1;
  for w in waves do
  begin
    if n = 0 then
    begin
      fmintime := w.StartTime;
      fmaxtime := w.EndTime;
    end
    else
    begin
      if w.StartTime < fmintime then fmintime := w.StartTime;
      if w.EndTime > fmaxtime   then fmaxtime := w.EndTime;
    end;
    inc(n);
  end;
  ftimerange := fmaxtime - fmintime;
end;


procedure TScopeDisplay.ClearWaves;
var
  w : TWaveDisplay;
begin
  for w in waves do w.Free;
  waves.Clear;
end;

procedure TScopeDisplay.AutoScale;
var
  wd : TWaveDisplay;
begin
  for wd in waves do
  begin
    wd.AutoScale;
  end;
  RenderWaves;
end;

function TScopeDisplay.AddWave(aname: string; asamplt: double) : TWaveDisplay;
begin
  result := TWaveDisplay.Create(self, aname, asamplt);
  waves.Add(result);
end;

function TScopeDisplay.DeleteWave(awave : TWaveDisplay) : boolean;
begin
  if waves.Extract(awave) <> nil then
  begin
    awave.Free;
    result := True;
  end
  else result := False;
end;

function TScopeDisplay.LoadWave(afilename: string) : TWaveDisplay;
var
  jf : TJsonNode;
begin
  result := nil;
  jf := TJsonNode.Create();
  try
    jf.LoadFromFile(afilename);
    result := AddWave('???', 1/1000);
    if not result.LoadFromJsonNode(jf) then
    begin
      DeleteWave(result);
      result := nil;
    end;
  finally
    jf.Free;
  end;

  if result <> nil then
  begin
    CalcTimeRange;
  end;
end;

procedure TScopeDisplay.LoadScopeFile(afilename : string);
var
  jf, jwlist, jw : TJsonNode;
  i : integer;
  wd : TWaveDisplay;
begin
  jf := TJsonNode.Create();
  try
    jf.LoadFromFile(afilename);

    jwlist := jf.Find('WAVES');
    if jwlist = nil then raise EScopeData.Create('Scope data format error: "WAVES" node not found.');

    for i := 0 to jwlist.Count - 1 do
    begin
      jw := jwlist.Child(i);
      wd := AddWave('???', 1/1000);
      if not wd.LoadFromJsonNode(jw) then
      begin
        DeleteWave(wd);
      end;
    end;
  finally
    jf.Free;
  end;

  CalcTimeRange;
end;

procedure TScopeDisplay.SaveScopeFile(afilename : string);
var
  jf : TJsonNode;
  w  : TWaveDisplay;
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

function TScopeDisplay.ConvertXToTime(x : integer) : double;
var
  gx : integer;
  gw : integer;
begin
  gw := Width - 2 * fmargin_pixels;
  gx := x - fmargin_pixels;
  result := ViewStart + 10 * TimeDiv * gx / gw;
end;

procedure TScopeDisplay.SetTimeCursor(t : double);
var
  gt : double;
begin
  gt := (t - ViewStart) / TimeDiv;
  if (gt < 0) or (gt > 10) then
  begin
    timecursor.visible := false;
  end
  else
  begin
    timecursor.x := gt;
    timecursor.visible := true;
  end;
end;

function TScopeDisplay.ViewEnd : double;
begin
  result := ViewStart + ViewRange;
end;

end.

