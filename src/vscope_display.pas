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
 *  file:     vscope_display.pas
 *  brief:    vscope visualisation implementations
 *  date:     2023-02-11
 *  authors:  nvitya
*)

unit vscope_display;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, Dialogs, Forms, fgl, math, jsontools, dglOpenGL,
  ddgfx, ddgfx_font, vscope_data, vscope_bin_file, util_nstime;

type

  TScopeDisplay = class;

  { TWaveDisplay }

  TWaveDisplay = class(TWaveData)
  public
    lores_data : array of double;
    lores_samplt_mul : double;

    procedure MakeLoresData;
    procedure InvalidateLoresData;

  public
    wshp : TShape;
    zeroline : TShape;
    scope : TScopeDisplay;

    constructor Create(ascope: TScopeDisplay; aname: string; asamplt: double); reintroduce;
    destructor Destroy; override;

    procedure SetColor(acolor : cardinal);

    procedure ReDrawWave;

    procedure AutoScale(agridmin, agridmax : double);
    procedure CorrectOffset;

    procedure DoOnDataUpdate; override;

    function GridValue(di : integer) : double;
    function GridValueAt(t : double) : double;

  end;

  TWaveDisplayList = specialize TFPGList<TWaveDisplay>;

  { TScopeMarker }

  TScopeMarker = class
  private
    fvisible : boolean;
    procedure SetVisible(AValue : boolean);

  public
    index   : integer;
    mtime    : double;

    vline  : TShape;
    letter : TTextBox;
    letterbg : TShape;

    scope : TScopeDisplay;

    constructor Create(ascope : TScopeDisplay; aindex : integer; atime : double);
    destructor Destroy; override;

    procedure SetTo(t : double);

    property Visible : boolean read fvisible write SetVisible;

    procedure Update;

  end;

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

    scale_ratio : double;
    txt_font_size : double;

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
    vfont     : TFontFace;
    valtxt    : TTextBox;
    valgrp    : TDrawGroup;
    valframe  : TShape;

    txt_timediv : TTextBox;
    txt_abinfo  : TTextBox;

    procedure InitTexts;

  public
    timecursor    : TShape;
    sample_marker : TShape;
    grp_top_icons : TDrawGroup;  // screen aligned
    grp_markers   : TDrawGroup;  // grid-scaled
    marker        : array[0..1] of TScopeMarker;

    procedure InitMarkers;
    procedure UpdateMarkers;

    procedure SetMarker(aindex : integer; t : double);
    procedure ClearMarkers;
    function  FindNearestMarker(x, range : integer) : TScopeMarker;

  public
    grp_waves   : TDrawGroup;    // grid-scaled
    grp_zeroes  : TDrawGroup;    // grid-scaled
    grp_zeroes2 : TClonedGroup; // grid-scaled

    procedure ClearWaves;
    function AddWave(aname: string; asamplt: double): TWaveDisplay;
    function DuplicateWave(sw : TWaveDisplay) : TWaveDisplay;
    function DeleteWave(awave : TWaveDisplay) : boolean;
    function WaveIndex(awave : TWaveDisplay) : integer;
    procedure RenderWaves;

    function FindNearestWaveSample(x, y : integer; range : integer; out rdi : integer) : TWaveDisplay;
    procedure ShowSampleMarker(wd : TWaveDisplay; di : integer); //t : double);

  public
    waves       : TWaveDisplayList;

    draw_steps  : boolean;
    time_unit   : string;

    binary_file : boolean;

    constructor Create(aowner : TComponent; aparent : TWinControl); override;
    destructor Destroy; override;

    procedure DoOnResize; override;
    procedure UpdateTimeDivPos;
    procedure AutoScale;

    procedure CalcTimeRange;  // necessary when the scope data changed

    property TimeRange : double read ftimerange;
    property MinTime : double read fmintime;
    property MaxTime : double read fmaxtime;

    property ViewStart : double read fviewstart write SetViewStart;
    property ViewRange : double read fviewrange write SetViewRange;
    function ViewEnd   : double;
    property TimeDiv   : double read GetTimeDiv;

    procedure SetTimeDiv(AValue : double; fixtimepos : double);
    procedure UpdateTimeDivInfo;
    procedure SetTimeCursor(t : double);
    function  FindNextTimeDiv(adiv : double; adir : integer) : double;

    function FormatTime(t : double) : string;

  public
    function ConvertXToTime(x : integer) : double;
    function ConvertTimeToX(t : double) : integer;
    function ConvertTimeToGrid(t : double) : double;
    function ConvertGridToY(gridvalue : double) : integer;
    function ConvertYToGrid(y : integer) : double;
    function GetSmallestSampleTime : double;
    function GridWidthPixels : integer;

  public
    function  LoadWave(afilename : string) : TWaveDisplay;
    procedure LoadScopeFile(afilename : string);
    procedure SaveScopeFile(afilename : string);

  private
    fbfile    : TVscopeBinFile;

  end;


const

  default_font_path : string = 'vscope_font.ttf';

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

  scope_marker_letters : array[0..1] of char = ('A', 'B');

implementation

{ TScopeMarker }

procedure TScopeMarker.SetVisible(AValue : boolean);
begin
  if fvisible = AValue then Exit;
  fvisible := AValue;
  Update;
end;

constructor TScopeMarker.Create(ascope : TScopeDisplay; aindex : integer; atime : double);
const
  vline_vertices  : array[0..1] of TVertex = ((0, 0),(0,10));
  //lshp_vertices   : array[0..5] of TVertex = ((0, 0),(0,10));
begin
  scope := ascope;
  index := aindex;
  visible := false;
  mtime  := atime;

  vline  := scope.grp_markers.NewShape;
  vline.AddPrimitive(GL_LINES, 2, @vline_vertices);
  vline.x := 0.5;
  vline.alpha := 0.5;
  if aindex = 0 then
  begin
    vline.SetColor(0.8, 0.8, 1);
  end
  else
  begin
    vline.SetColor(0.8, 1, 0.8);
  end;

  //letterbg := grp.NewShape;
  letter := TTextBox.Create(scope.grp_top_icons, scope.vfont.GetSizedFont(8 * scope.scale_ratio), scope_marker_letters[index]);
  letter.y := -letter.Height;
  letter.color := vline.color;
end;

destructor TScopeMarker.Destroy;
begin
  vline.Free;
  letter.Free;
  inherited Destroy;
end;

procedure TScopeMarker.SetTo(t : double);
begin
  mtime := t;
  fvisible := true;
  Update;
end;

procedure TScopeMarker.Update;
var
  gt : double;
begin
  if fvisible then
  begin
    gt := (mtime - scope.ViewStart) / scope.TimeDiv;
    if      gt <  0 then gt := 0
    else if gt > 10 then gt := 10;
    vline.x := gt;
    vline.visible := true;

    letter.x := round((scope.Width - 2 * scope.fmargin_pixels) * gt / 10 - letter.Width / 2 + 0.25);
    letter.visible := true;
  end
  else
  begin
    vline.visible := false;
    letter.visible := false;
  end;
end;


{ TWaveDisplay }

constructor TWaveDisplay.Create(ascope: TScopeDisplay; aname: string; asamplt: double);
const
  zeroline_vertices  : array[0..1] of TVertex = ((0, 0),(1,0));
begin
  inherited Create(aname, asamplt);
  scope := ascope;
  wshp := scope.grp_waves.NewShape();
  wshp.scaley := -1;
  wshp.y := 5;
  wshp.alpha := basealpha;

  zeroline := scope.grp_zeroes.NewShape();
  zeroline.scaley := -1;
  zeroline.y := 5;
  zeroline.AddPrimitive(GL_LINES, 2, @zeroline_vertices);
  zeroline.alpha := 0.8;

  lores_data := [];
end;

destructor TWaveDisplay.Destroy;
begin
  wshp.Free;
  zeroline.Free;

  lores_data := [];

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

  zeroline.color := wshp.color;
end;

procedure TWaveDisplay.MakeLoresData;
var
  di, maxdi : integer;
  minval, maxval : double;
  modidx : integer;
  v : double;
  lrdi : integer;

  loresmul : integer;
  loresmask : integer;
begin
  loresmul := 256;
  loresmask := loresmul - 1;

  // search min and max every loresmul / 2 points
  lrdi := 0;
  lores_samplt_mul := (loresmul div 2);
  SetLength(lores_data, length(data) div (loresmul div 4));
  maxdi := length(data) - 1;
  minval := 0;
  maxval := 0;
  modidx := loresmask;
  for di := 0 to maxdi do
  begin
    v := data[di];
    modidx := (di and loresmask);
    if 0 = modidx then
    begin
      minval := v;
      maxval := v;
    end
    else
    begin
      if v < minval then minval := v;
      if v > maxval then maxval := v;
      if loresmask = modidx then
      begin
        lores_data[lrdi] := minval;
        inc(lrdi);
        lores_data[lrdi] := maxval;
        inc(lrdi);
      end;
    end;
  end;

  // add the last not complete sample
  if modidx <> loresmask then
  begin
    lores_data[lrdi] := minval;
    inc(lrdi);
    lores_data[lrdi] := maxval;
    inc(lrdi);
  end;
  SetLength(lores_data, lrdi);
end;

procedure TWaveDisplay.InvalidateLoresData;
begin
  lores_data := [];
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
  y, x, dx : double;
  pixeltime : double;
  samples_per_pixel : double;

  disp_samplt : double;
  disp_data   : array of double;
  steps : boolean;
begin

  wshp.Clear; // removes all primitives

  wshp.visible := visible;
  zeroline.visible := visible;

  if not visible then EXIT; // --->

  vi := 0;
  steps := scope.draw_steps;

  pixeltime := scope.ViewRange / scope.GridWidthPixels;
  samples_per_pixel := pixeltime / samplt;
  if (samples_per_pixel >= 256) and (length(data) > 100000) then
  begin
    if length(lores_data) <= 0 then MakeLoresData;

    disp_data := lores_data;
    disp_samplt := samplt * lores_samplt_mul;
    steps := false;
  end
  else
  begin
    disp_data := data;
    disp_samplt := samplt;
    if samples_per_pixel >= 2 then steps := false;  // step drawing does not make sense
  end;

  di := trunc((scope.ViewStart - startt) / disp_samplt);
  if di < 0 then
  begin
    di := 0;
  end;

  dx := disp_samplt / scope.TimeDiv;
  t := startt + di * disp_samplt;
  x := (t - scope.ViewStart) / scope.TimeDiv;
  if x < 0 then
  begin
    i := Ceil(-x / dx);
    di += i;
    x += dx * i;
  end;

  maxdi := di + trunc(11 / dx);
  if maxdi > length(disp_data) then maxdi := length(disp_data);
  if maxdi < 0 then maxdi := 0;

  vcnt := maxdi - di;
  if steps then vcnt *= 2;

  varr := [];
  if vcnt > 0 then
  begin
    SetLength(varr, vcnt);

    while (di < maxdi) and (x < 10) do
    begin
      v[0] := x;
      v[1] := disp_data[di] * viewscale + viewoffset;
      // clamping the Y:
      if v[1] > 5 then v[1] := 5
      else if v[1] < -5 then v[1] := -5;

      if steps and (vi > 0) then
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

    if vi > 0 then wshp.AddPrimitive(GL_LINE_STRIP, vi, @varr[0]);

    varr := [];
  end;

  // adjust the zero line
  y := 5-viewoffset;
  if y < 0 then y := 0
  else if y > 10 then y := 10;
  zeroline.y := y;

end;

procedure TWaveDisplay.AutoScale(agridmin, agridmax: double);
var
  ddiff : double;
  data_min, data_max : double;
  scnt : integer;
begin
  CalcMinMax(startt, EndTime, data_min, data_max, scnt);

  ddiff := (data_max - data_min);
  if ddiff < 0.00000001 then ddiff := 0.00000001;

  viewscale := FindNearestScale((agridmax - agridmin) / ddiff);
  viewoffset := agridmin - data_min * viewscale
end;

procedure TWaveDisplay.CorrectOffset;
var
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
  InvalidateLoresData;
  ReDrawWave;

  if color = $FFFFFFFF then // if no color was set
  begin
    ci := (scope.waves.Count - 1) mod 8;
    SetColor(default_wave_colors[ci]);
  end
  else
  begin
    SetColor(color);
  end;
end;

function TWaveDisplay.GridValueAt(t : double) : double;
var
  di : integer;
begin
  di := GetDataIndex(t);
  if di < 0
  then
      EXIT(-20);

  result := data[di] * viewscale + viewoffset;
  // clamping the Y:
  if result > 5 then result := 5
  else if result < -5 then result := -5;
end;

function TWaveDisplay.GridValue(di : integer) : double;
begin
  if (di < 0) or (di >= length(data))
  then
      EXIT(-20);

  result := data[di] * viewscale + viewoffset;
  // clamping the Y:
  if result > 5 then result := 5
  else if result < -5 then result := -5;
end;


{ TScopeDisplay }

constructor TScopeDisplay.Create(aowner : TComponent; aparent : TWinControl);
begin
  inherited Create(aowner, aparent);

  fbfile := TVscopeBinFile.Create;

  draw_steps := false;
  time_unit := 's';

  scale_ratio := Forms.Screen.PixelsPerInch / 96;

  waves := TWaveDisplayList.Create;

  InitFontManager;
  vfont := fontmanager.GetFont(default_font_path);

  fmargin_pixels := round(32 * scale_ratio);
  txt_font_size := 9 * scale_ratio;

  grid := root.NewGroup;
  grid.x := fmargin_pixels;
  grid.y := fmargin_pixels;

  grp_zeroes := root.NewGroup;
  grp_zeroes.scalex := fmargin_pixels;
  grp_zeroes.x := 0;
  grp_zeroes.y := grid.y;

  grp_zeroes2 := root.CloneGroup(grp_zeroes);
  grp_zeroes2.scalex := fmargin_pixels;
  grp_zeroes2.y := grid.y;
  grp_zeroes2.x := Width - fmargin_pixels;

  grp_waves := root.NewGroup;
  grp_waves.x := fmargin_pixels;
  grp_waves.y := fmargin_pixels;

  grp_markers := root.NewGroup;
  grp_markers.x := fmargin_pixels;
  grp_markers.y := fmargin_pixels;

  fviewstart := 0;
  fviewrange := 1;
  CalcTimeRange; // initialize the time range

  bgcolor.r := 0.0;
  bgcolor.g := 0.0;
  bgcolor.b := 0.0;

  grp_top_icons := root.NewGroup;
  grp_top_icons.x := fmargin_pixels;
  grp_top_icons.y := fmargin_pixels;

  InitGrid;
  InitMarkers;
  InitTexts;
end;

destructor TScopeDisplay.Destroy;
var
  m : TScopeMarker;
begin
  for m in marker do if m <> nil then m.Free;

  ClearWaves;
  fbfile.Free;
  inherited;
end;

procedure TScopeDisplay.DoOnResize;
var
  gw, gh : integer;
begin
  inherited DoOnResize;

  gw := self.width  - 2 * fmargin_pixels;
  gh := self.Height - 2 * fmargin_pixels;

  grid.scalex := gw / 10;
  grid.scaley := gh / 10;

  grp_zeroes.scaley  := grid.scaley;
  grp_zeroes2.scaley := grid.scaley;
  grp_zeroes2.x := Width - fmargin_pixels;

  grp_waves.scalex := grid.scalex;
  grp_waves.scaley := grid.scaley;

  grp_markers.scalex := grid.scalex;
  grp_markers.scaley := grid.scaley;

  sample_marker.scalex := 40 / gw; // rescaled to 4 pixels in DoOnResize
  sample_marker.scaley := 40 / gh;

  UpdateTimeDivPos;

  UpdateMarkers;

  txt_abinfo.x := fmargin_pixels;
  txt_abinfo.y := round(gh + fmargin_pixels + fmargin_pixels / 2 - txt_abinfo.Height / 2);

  RenderWaves; // resolution might change
end;

procedure TScopeDisplay.UpdateTimeDivPos;
var
  gw, gh : integer;
begin
  gw := self.width  - 2 * fmargin_pixels;
  gh := self.Height - 2 * fmargin_pixels;

  txt_timediv.x := round(gw + fmargin_pixels - txt_timediv.Width);
  txt_timediv.y := round(gh + fmargin_pixels + fmargin_pixels / 2 - txt_timediv.Height / 2);
end;

procedure TScopeDisplay.RenderWaves;
var
  w : TWaveDisplay;
begin
  for w in waves do w.ReDrawWave;
  UpdateMarkers;
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
  hsh.SetColor(0.15, 0.15, 0.15);

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
end;

procedure TScopeDisplay.CleanupGrid;
begin
  //
end;

procedure TScopeDisplay.InitTexts;
const
  frame_vertices  : array[0..3] of TVertex = ((0, 0),(1,0),(1,1),(0, 1));
begin
  // sample point value

  valgrp := root.NewGroup;

  valframe := valgrp.NewShape;
  valframe.AddPrimitive(GL_TRIANGLE_FAN, 4, @frame_vertices);
  valframe.SetColor(0.0, 0.0, 0.0);
  valframe.alpha := 0.8;

  valtxt := TTextBox.Create(valgrp, vfont.GetSizedFont(txt_font_size), 'Value Sample Text');
  valgrp.x := 50;
  valgrp.y := 150;
  valframe.x := -4;
  valframe.y := -4;
  valframe.scalex := valtxt.Width + 8;
  valframe.scaley := valtxt.Height + 8;

  valgrp.visible := false;

  txt_timediv := TTextBox.Create(root, vfont.GetSizedFont(txt_font_size), 'Time Div Info');
  txt_timediv.SetColor(0.7, 0.7, 0.7);

  txt_abinfo := TTextBox.Create(root, vfont.GetSizedFont(txt_font_size), 'A-B Marker Info Text');;
  txt_abinfo.SetColor(0.7, 0.7, 0.7);
end;

procedure TScopeDisplay.InitMarkers;
const
  vline_vertices : array[0..1] of TVertex = ((0, 0),(0,10));
  marker_vertices : array[0..3] of TVertex = ((0, -1),(0,1),(-1,0),(1, 0));
begin
  timecursor := grid.NewShape();
  timecursor.AddPrimitive(GL_LINES, 2, @vline_vertices);
  timecursor.SetColor(1, 0.1, 0.1);
  timecursor.alpha := 0.25;
  timecursor.visible := false;

  // sample point marker

  sample_marker := grp_markers.NewShape;
  sample_marker.AddPrimitive(GL_LINES, 4, @marker_vertices);
  sample_marker.SetColor(1, 1, 1);
  sample_marker.alpha := 0.8;
  sample_marker.scalex := 1; // warning: grid scaling, rescaled to 5 pixels in DoOnResize
  sample_marker.scaley := 1;
  sample_marker.visible := false;

  // A-B marker
  marker[0] := TScopeMarker.Create(self, 0, 0);
  marker[1] := TScopeMarker.Create(self, 1, 1);
end;

procedure TScopeDisplay.UpdateMarkers;
var
  m : TScopeMarker;
  allvisible : boolean;
  dt : double;
  hz : double;
begin
  allvisible := true;
  for m in marker do
  begin
    m.Update;
    if not m.Visible then allvisible := false;
  end;

  if not allvisible then
  begin
    txt_abinfo.Visible := false;
  end
  else
  begin
    dt := marker[1].mtime - marker[0].mtime;
    hz := 1 / dt;
    txt_abinfo.Text := 'B-A: '
       + FormatTime(dt)
       + ', ' + FloatToStrF(hz, ffFixed, 0, 3, float_number_format) + ' Hz'
    ;
    txt_abinfo.Visible := true;
  end;
end;

procedure TScopeDisplay.SetMarker(aindex : integer; t : double);
begin
  if (aindex < 0) or (aindex > 1) then EXIT;

  marker[aindex].SetTo(t);

  UpdateMarkers;
end;

procedure TScopeDisplay.ClearMarkers;
begin
  marker[0].Visible := false;
  marker[1].Visible := false;
  UpdateMarkers;
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
  ftimeratio : double;
  fmintdiv, fmaxtdiv : double;
begin
  fmintdiv := FindNextTimeDiv(GetSmallestSampleTime * 2, -1);
  fmaxtdiv := FindNextTimeDiv(TimeRange / 5, 1);

  if avalue < fmintdiv then avalue := fmintdiv
  else if avalue > fmaxtdiv then avalue := fmaxtdiv;

  ftimeratio := (fixtimepos - fviewstart) / fviewrange;
  fviewrange := AValue * 10;
  fviewstart := fixtimepos - fviewrange * ftimeratio;

  RenderWaves;
  UpdateTimeDivInfo;
end;

procedure TScopeDisplay.UpdateTimeDivInfo;
var
  s : string;
begin
  if ('s' = time_unit) and (TimeDiv > 60) then
  begin
    if TimeDiv < 3600 then s := FloatToStrF(TimeDiv / 60, ffFixed, 0, 6, float_number_format) + ' m'
    else if TimeDiv < 86400 then s := FloatToStrF(TimeDiv / 3600, ffFixed, 0, 6, float_number_format) + ' h'
    else s := FloatToStrF(TimeDiv / 86400, ffFixed, 0, 6, float_number_format) + ' d';
  end
  else
  begin
    s := FloatToStrF(TimeDiv, ffFixed, 0, 6, float_number_format) + ' '+time_unit;
  end;

  txt_timediv.Text := s+' / div';

  UpdateTimeDivPos;
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
  gridstart : double;
  gridstep  : double;
begin
  if waves.Count <= 4  then gridstep := 2
  else if waves.Count <= 8   then gridstep := 1
  else if waves.Count <= 16  then gridstep := 0.5
  else gridstep := 9 / waves.Count;

  gridstart := 5 - gridstep;
  for wd in waves do
  begin
    wd.AutoScale(gridstart - gridstep, gridstart);
    gridstart -= gridstep;
  end;
  RenderWaves;
end;

function TScopeDisplay.AddWave(aname: string; asamplt: double) : TWaveDisplay;
begin
  result := TWaveDisplay.Create(self, aname, asamplt);
  waves.Add(result);
end;

function TScopeDisplay.DuplicateWave(sw : TWaveDisplay) : TWaveDisplay;
begin
  result := AddWave(sw.name+'_2', sw.samplt);
  result.CopyFrom(sw);

  result.color := $FFFFFFFF; // let autoselect the color
  result.viewoffset := sw.viewoffset - 1;
  result.DoOnDataUpdate;
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

function TScopeDisplay.WaveIndex(awave : TWaveDisplay) : integer;
begin
  result := waves.IndexOf(awave);
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
  jn : TJsonNode;
  jview, jv : TJsonNode;
  jmarkers : TJsonNode;
  i : integer;
  wd : TWaveDisplay;

  t0, t1, t2 : int64;
  tdiv, vstart : double;
  jstr : ansistring = '';

  //rlen : integer;
  brec : TVscopeBinRec; // to shorten some lines

  run_autoscale : boolean;

begin
  t0 := nstime();
  jf := TJsonNode.Create();

  try
    binary_file := afilename.EndsWith('.bscope');
    if binary_file then
    begin
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

      jf.Parse(jstr);

    end
    else
    begin
      jf.LoadFromFile(afilename);
    end;

    t2 := nstime();

    {$ifdef TRACES}
    writeln('JSON parsing time: ', (t2 - t0) / 1000 :0:3, ' us');
    {$endif}

    ClearWaves;
    ClearMarkers;

    run_autoscale := true;

    jwlist := jf.Find('WAVES');
    if jwlist = nil then raise EScopeData.Create('Scope data format error: "WAVES" node not found.');

    for i := 0 to jwlist.Count - 1 do
    begin
      jw := jwlist.Child(i);
      wd := AddWave('???', 1/1000);
      if wd.LoadFromJsonNode(jw)
      then
          run_autoscale := (run_autoscale and wd.run_autoscale)
      else
          DeleteWave(wd);
    end;

    if binary_file then
    begin
      fbfile.ClearWaves();
      for wd in waves do  fbfile.AddWave(wd);

      fbfile.LoadWaveData();
    end;

    CalcTimeRange;

    if run_autoscale then AutoScale;

    draw_steps := true;
    tdiv := -1;
    vstart := 0;
    time_unit := 's';

    if jf.Find('VIEW', jview) then
    begin
      if jview.Find('TIMEUNIT', jv) then time_unit := jv.AsString;
      if jview.Find('VIEWSTART', jv) then vstart := jv.AsNumber;
      if jview.Find('TIMEDIV', jv)   then tdiv := jv.AsNumber;
      if jview.Find('DRAWSTEPS', jv) then draw_steps := jv.AsBoolean;
    end;

    if tdiv <= 0 then  // auto-range
    begin
      tdiv := TimeRange / 10;
      vstart := 0;
    end;

    ViewStart := vstart;
    SetTimeDiv(tdiv, ViewStart);

    if jf.Find('MARKERS', jmarkers) then
    begin
      for i := 0 to jmarkers.Count - 1 do
      begin
        jn := jmarkers.Child(i);
        if jn.Find('MTIME', jv)   then marker[i].mtime := jv.AsNumber;
        if jn.Find('VISIBLE', jv) then marker[i].fvisible := jv.AsBoolean;
      end;
      UpdateMarkers;
    end;

    UpdateTimeDivInfo;

  finally
    fbfile.Close;
    jf.Free;
  end;

  t1 := nstime();

  {$ifdef TRACES}
  writeln('Total loading time: ', (t1 - t0) / 1000000 :0:3, ' ms');
  {$endif}

  if t0 + t1 + t2 > 0 then ; // to supress unused warnings
end;

procedure TScopeDisplay.SaveScopeFile(afilename : string);
var
  jf : TJsonNode;
  w  : TWaveDisplay;
  jview : TJsonNode;
  jmarkers : TJsonNode;
  jwarr, jn : TJSonNode;
  i : integer;

  t0, t1, t2 : int64;
begin
  t0 := nstime();

  binary_file := afilename.EndsWith('.bscope');

  jf := TJsonNode.Create();

  jview := jf.Add('VIEW', nkObject);
  jview.Add('TIMEUNIT', time_unit);
  jview.Add('TIMEDIV', TimeDiv);
  jview.Add('VIEWSTART', ViewStart);
  jview.Add('DRAWSTEPS', draw_steps);

  jmarkers := jf.Add('MARKERS', nkArray);
  for i := 0 to 1 do
  begin
    jn := jmarkers.Add();
    jn.Add('VISIBLE', marker[i].Visible);
    jn.Add('MTIME',   marker[i].mtime);
  end;

  jwarr := jf.Add('WAVES', nkArray);
  for w in waves do
  begin
    jn := jwarr.Add();
    w.SaveToJsonNode(jn, binary_file);
  end;

  t1 := nstime();
  {$ifdef TRACES}
  writeln('JSON Prepare time: ', (t1 - t0) / 1000000 :0:3, ' ms');
  {$endif}

  try
    if binary_file then
    begin
      fbfile.ClearWaves();
      for w in waves do  fbfile.AddWave(w);
      fbfile.Save(afilename, jf);
    end
    else
    begin
      jf.SaveToFile(afilename);
    end;
  finally
    fbfile.Close;
    jf.Free;
  end;

  t2 := nstime();
  {$ifdef TRACES}
  writeln('Full Save time: ', (t2 - t0) / 1000000 :0:3, ' ms');
  {$endif}

  if t0 + t1 + t2 > 0 then ; // to supress unused warnings

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

function TScopeDisplay.ConvertTimeToX(t : double) : integer;
var
  gw : integer;
begin
  gw := Width - 2 * fmargin_pixels;
  result := fmargin_pixels + round(gw * (t - ViewStart) / ViewRange);
end;

function TScopeDisplay.ConvertTimeToGrid(t : double) : double;
begin
  result := (t - ViewStart) / TimeDiv;
  if (result < 0) or (result > 10) then
  begin
    result := NaN;
  end;
end;

function TScopeDisplay.ConvertGridToY(gridvalue : double) : integer;
var
  gh : integer;
  gy : double;
begin
  gh := Height - 2 * fmargin_pixels;
  gy := gh * (0.5 - 0.1 * gridvalue);
  result := fmargin_pixels + round(gy);
end;

function TScopeDisplay.ConvertYToGrid(y : integer) : double;
var
  gh : integer;
begin
  gh := Height - 2 * fmargin_pixels;
  result := 5 - 10 * (y - fmargin_pixels) / gh;
end;

function TScopeDisplay.FindNearestMarker(x, range : integer) : TScopeMarker;
var
  tm : TScopeMarker;
  dx, mindx : integer;
begin
  result := nil;
  mindx := range + 1;
  for tm in marker do
  begin
    dx := abs(x - ConvertTimeToX(tm.mtime));
    if dx < mindx then
    begin
      result := tm;
      mindx := dx;
    end;
  end;
end;

function TScopeDisplay.FindNearestWaveSample(x, y : integer; range : integer; out rdi : integer) : TWaveDisplay;
var
  wd            : TWaveDisplay;
  mint, maxt    : double;
  gh, gw        : integer;
  mindist2      : double;
  gv, wy, dy    : double;
  wx, dx, xinc  : double;
  d2            : double;
  di, maxdi     : integer;
begin
  result := nil;

  gw := Width - 2 * fmargin_pixels;
  gh := Height - 2 * fmargin_pixels;

  mint := ConvertXToTime(x - range);
  maxt := ConvertXToTime(x + range);

  mindist2 := range * range + 1;

  for wd in waves do
  begin
    if wd.visible then
    begin
      maxdi := trunc((maxt - wd.startt) / wd.samplt);
      if maxdi < 0
      then
          continue;

      if maxdi > length(wd.data) then maxdi := length(wd.data);

      di := trunc((mint - wd.startt) / wd.samplt);
      if di < 0 then di := 0;
      if di >= length(wd.data)
      then
          continue;

      wx := fmargin_pixels + gw * (wd.GetDataIndexTime(di) - ViewStart) / ViewRange;
      xinc := wd.samplt * gw / ViewRange;

      while di <= maxdi do
      begin
        gv := wd.data[di] * wd.viewscale + wd.viewoffset;

        // convert to screen Y coordinates:
        wy := fmargin_pixels + gh * (0.5 - 0.1 * gv);

        dx := wx - x;
        dy := wy - y;
        d2 := dx * dx + dy * dy;
        if d2 < mindist2 then
        begin
          result := wd;
          mindist2 := d2;
          rdi := di; //wd.GetDataIndexTime(di);
        end;

        inc(di);
        wx += xinc;
      end;
    end;
  end;
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

const
  time_steps_s : array of double =
  (
        20,
        30,
        60,   // 1m
       120,   // 2m
       300,   // 5m
       600,   // 10m
      1200,   // 20m
      1800,   // 30m
      3600,   // 60m = 1h
      7200,   // 2h
     10800,   // 3h
     21600,   // 6h
     43200,   // 12h
     86400,   // 24h = 1d
    172800    // 2d
  );

function TScopeDisplay.FindNextTimeDiv(adiv : double; adir : integer) : double;
var
  log10_div : double;
  log10_int_div : double;
  smul : double;
  newres : double;
  tsi : integer;

begin
  newres := adiv;
  repeat
    if adir > 0 then newres := newres * 2
                else newres := newres / 2;

    log10_div := log10(newres);
    log10_int_div := trunc(log10_div);

    if ('s' = time_unit) and (newres >= time_steps_s[0]) and (newres <= time_steps_s[length(time_steps_s) - 1]) then
    begin
      // find the nearest in the time_steps_s
      result := time_steps_s[0];
      tsi := 1;
      while tsi < length(time_steps_s) do
      begin
        if time_steps_s[tsi] > newres then Break;
        result := time_steps_s[tsi];
        Inc(tsi);
      end;
    end
    else
    begin
      if log10_div < 0 then  // 0 < adiv < 1
      begin
        smul := power(10, log10_int_div) / newres;
        if      smul > 5 then smul := 10
        else if smul > 2 then smul := 5
        else if smul > 1 then smul := 2
        else                  smul := 1;

        result := power(10, log10_int_div) / smul;
      end
      else  // adiv >= 1
      begin
        smul := newres / power(10, log10_int_div);
        if      smul > 5 then smul := 10
        else if smul > 2 then smul := 5
        else if smul > 1 then smul := 2
        else                  smul := 1;

        result := power(10, log10_int_div) * smul;
      end;
    end;
  until result <> adiv;
end;

function TScopeDisplay.FormatTime(t : double) : string;
begin
  if ('s' = time_unit) and (abs(t) > 60) then
  begin
    if abs(t) < 3600 then result := FloatToStrF(t / 60, ffFixed, 0, 6, float_number_format) + ' m'
    else if abs(t) < 86400 then result := FloatToStrF(t / 3600, ffFixed, 0, 6, float_number_format) + ' h'
    else result := FloatToStrF(t / 86400, ffFixed, 0, 6, float_number_format) + ' d';
  end
  else
  begin
    result := FloatToStrF(t, ffFixed, 0, 6, float_number_format) + ' ' + time_unit;
  end;
end;

procedure TScopeDisplay.ShowSampleMarker(wd : TWaveDisplay; di : integer);
var
  gv : double;
  t  : double;
begin
  if wd <> nil then
  begin
    t := wd.GetDataIndexTime(di);
    gv := wd.GridValue(di);
    sample_marker.X := ConvertTimeToGrid(t);
    sample_marker.Y := 5 - gv;
    sample_marker.visible := true;

    {$if 0}
    valtxt.Text := wd.name + ' = ' + wd.GetValueStr(t);
    {$else}
    valtxt.Text := wd.GetValueStr(t);
    valtxt.SetColor(
      ((wd.color shr  0) and $FF) / 255,
      ((wd.color shr  8) and $FF) / 255,
      ((wd.color shr 16) and $FF) / 255
    );
    {$endif}

    valframe.scalex := valtxt.Width + 8;
    valframe.scaley := valtxt.Height + 8;

    valgrp.x := ConvertTimeToX(t) + 20;
    valgrp.y := ConvertGridToY(gv) + 20;
    valgrp.visible := true;

  end
  else
  begin
    sample_marker.visible := false;
    valgrp.visible := false;
  end;
end;

function TScopeDisplay.ViewEnd : double;
begin
  result := ViewStart + ViewRange;
end;

function TScopeDisplay.GetSmallestSampleTime : double;
var
  wd : TWaveDisplay;
  cnt : integer;
begin
  result := 1;
  cnt := 0;
  for wd in waves do
  begin
    if cnt = 0 then result := wd.samplt
    else if wd.samplt < result then result := wd.samplt;
    inc(cnt);
  end;
end;

function TScopeDisplay.GridWidthPixels : integer;
begin
  result := Width - 2 * fmargin_pixels;
end;

end.

