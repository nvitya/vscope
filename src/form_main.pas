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
 *  file:     form_main.pas
 *  brief:    vscope main window
 *  date:     2023-02-11
 *  authors:  nvitya
*)

unit form_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  ExtCtrls, StdCtrls, Grids, Buttons, LCLType, math, ddgfx, dglOpenGL,
  vscope_data, vscope_display, Types;

const
  c_value_snap_range = 10;
  c_ydrag_grid_snap_range = 8;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    Bevel12 : TBevel;
    Bevel5 : TBevel;
    Bevel6 : TBevel;
    Bevel7 : TBevel;
    Label7 : TLabel;
    mainmenu : TMainMenu;
    menuFile : TMenuItem;
    miOpen : TMenuItem;
    miExit : TMenuItem;
    Separator1 : TMenuItem;
    tbMain : TToolBar;
    pnlScopeGroup : TPanel;
    sbScope : TScrollBar;
    pnlScopeView : TPanel;
    pnlRight : TPanel;
    pnlWaves : TPanel;
    pnlInfo : TPanel;
    chgrid : TDrawGrid;
    miSave : TMenuItem;
    miSaveAs : TMenuItem;
    menuWave : TMenuItem;
    miAutoscaleAll : TMenuItem;
    miAutoscale : TMenuItem;
    tbOpen : TToolButton;
    tbSave : TToolButton;
    tbSaveAs : TToolButton;
    imglist : TImageList;
    ToolButton2 : TToolButton;
    tbDrawSteps : TToolButton;
    menuView : TMenuItem;
    miDrawSteps : TMenuItem;
    tbZoomIn : TToolButton;
    tbZoomOut : TToolButton;
    Separator2 : TMenuItem;
    miZoomIn : TMenuItem;
    miZoomOut : TMenuItem;
    tbScalePlus : TToolButton;
    tbScaleMinus : TToolButton;
    tbOffsetUp : TToolButton;
    tbOffsetDown : TToolButton;
    tbMarkerA : TToolButton;
    tbMarkerB : TToolButton;
    tbMarkerClear : TToolButton;
    Bevel1 : TBevel;
    Bevel3 : TBevel;
    Bevel4 : TBevel;
    menuMarkers : TMenuItem;
    miMarkerA : TMenuItem;
    miMarkerB : TMenuItem;
    miClearMarkers : TMenuItem;
    Separator4 : TMenuItem;
    miScalePlus : TMenuItem;
    miScaleMinus : TMenuItem;
    miOffsetUp : TMenuItem;
    miOffsetDown : TMenuItem;
    dlgFileOpen : TOpenDialog;
    dlgFileSave : TSaveDialog;
    tbZoomAll : TToolButton;
    miZoomAll : TMenuItem;
    Separator5 : TMenuItem;
    miWaveProps : TMenuItem;
    tbWaveProps : TToolButton;
    menuHelp : TMenuItem;
    miAboutBox : TMenuItem;
    Label1 : TLabel;
    Label2 : TLabel;
    Label3 : TLabel;
    Label4 : TLabel;
    Label5 : TLabel;
    txtCursorTime : TStaticText;
    txtCursorToA : TStaticText;
    txtTimeUnit : TStaticText;
    txtViewLength : TStaticText;
    txtTotalLength : TStaticText;
    Label6 : TLabel;
    txtCursorToB : TStaticText;
    Bevel2 : TBevel;
    Bevel8 : TBevel;
    Bevel9 : TBevel;
    Bevel10 : TBevel;
    Bevel11 : TBevel;
    tbABMeasure : TToolButton;
    miABMeasure : TMenuItem;
    procedure miExitClick(Sender : TObject);

    procedure FormCreate(Sender : TObject);

    procedure chgridDrawCell(Sender : TObject; aCol, aRow : Integer; aRect : TRect; aState : TGridDrawState);
    procedure btnTdPlusClick(Sender : TObject);
    procedure btnTdMinusClick(Sender : TObject);
    procedure sbScopeScroll(Sender : TObject; ScrollCode : TScrollCode; var ScrollPos : Integer);


    procedure btnChScalePlusMinusClick(Sender : TObject);
    procedure btnChOffsPlusMinusClick(Sender : TObject);
    procedure miSaveClick(Sender : TObject);
    procedure miAutoscaleClick(Sender : TObject);
    procedure miAutoscaleAllClick(Sender : TObject);
    procedure chgridSelection(Sender : TObject; aCol, aRow : Integer);

    // mouse events
    procedure pnlScopeViewMouseWheel(Sender : TObject; Shift : TShiftState; WheelDelta : Integer; MousePos : TPoint; var Handled : Boolean);
    procedure pnlScopeViewMouseDown(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
    procedure pnlScopeViewMouseUp(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
    procedure pnlScopeViewMouseMove(Sender : TObject; Shift : TShiftState; X, Y : Integer);

    procedure miDrawStepsClick(Sender : TObject);
    procedure tbZoomInClick(Sender : TObject);
    procedure tbZoomOutClick(Sender : TObject);
    procedure tbMarkerAClick(Sender : TObject);
    procedure tbMarkerClearClick(Sender : TObject);
    procedure tbMarkerBClick(Sender : TObject);
    procedure tbOpenClick(Sender : TObject);
    procedure tbSaveAsClick(Sender : TObject);
    procedure FormDropFiles(Sender : TObject; const FileNames : array of string);
    procedure tbZoomAllClick(Sender : TObject);
    procedure tbWavePropsClick(Sender : TObject);
    procedure pnlScopeViewDblClick(Sender : TObject);
    procedure miAboutBoxClick(Sender : TObject);
    procedure FormKeyDown(Sender : TObject; var Key : Word; Shift : TShiftState);
    procedure tbABMeasureClick(Sender : TObject);
  private

  public
    exe_dir : string;

    procedure UpdateDrawSteps;

  public
    scope : TScopeDisplay;

    cursor_time : double;

    filename : string;

    drag_start_x : integer;
    drag_start_y : integer;

    time_dragging : boolean;
    td_viewstart : double;

    wave_dragging : boolean; // wave offset change
    wdr_wave : TWaveDisplay;
    wdr_start_offs : double;

    marker_placing : integer;
    marker_was_moved : boolean;

    procedure UpdateScrollBar;
    procedure UpdateTimeDiv;

    procedure UpdateChGrid;

    procedure LoadScopeFile(afilename : string);

    procedure SelectWave(awidx : integer); overload;
    procedure SelectWave(wd : TWaveDisplay); overload;

    function SelectedWave : TWaveDisplay;

    procedure ChangeWaveScale(amul : double);

    procedure UpdateInfoGrid;

    procedure UpdateWavePopupWins;

  end;

var
  frmMain : TfrmMain;

implementation

uses
  form_wave_props, form_measure_ab, version_vscope, form_about;

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender : TObject);
begin

  exe_dir := ExtractFileDir(ParamStr(0));
  default_font_path :=  IncludeTrailingBackslash(exe_dir) + 'vscope_font.ttf';

  marker_placing := 0;

  try
    scope := TScopeDisplay.Create(self, pnlScopeView);
  except
    on e : Exception do
    begin
      MessageDlg('Exception', e.ToString, mtError, [mbAbort], 0);
      halt(1);
    end;
  end;
  scope.ViewStart := 0;
  scope.ViewRange := 10;
  scope.ViewStart := 0; //-2;
  scope.UpdateTimeDivInfo;

  scope.valgrp.visible := false;

  scope.draw_steps := true;
  UpdateDrawSteps;

  scope.OnMouseMove := @pnlScopeViewMouseMove;
  scope.OnMouseDown := @pnlScopeViewMouseDown;
  scope.OnMouseUp   := @pnlScopeViewMouseUp;
  scope.OnDblClick  := @pnlScopeViewDblClick;


  if (ParamCount >= 1) and FileExists(ParamStr(1)) then
  begin
    try
      LoadScopeFile(ParamStr(1));
    except
      on e : Exception do
      begin
        MessageDlg('Error Loading File', e.ToString, mtError, [mbOK], 0);
      end;
    end;
  end;

  //scope.LoadScopeFile(filename);
  //scope.AutoScale;

  //scope.SetMarker(0, scope.TimeRange / 3);
  //scope.SetMarker(1, scope.TimeRange / 2);

  UpdateScrollBar;
  UpdateTimeDiv;

  UpdateChGrid;
  SelectWave(0);

end;

procedure TfrmMain.chgridDrawCell(Sender : TObject; aCol, aRow : Integer; aRect : TRect; aState : TGridDrawState);
var
  s : string;
  w : TWaveDisplay;
  c : TCanvas;
  ts : TTextStyle;
begin
  if arow = 0 then Exit;  // keep the header as it is

  w := scope.waves[aRow - 1];
  if w = nil then Exit;

  // give some margins:
  Inc(arect.Left, 2);
  Dec(arect.Right, 2);

  c := chgrid.Canvas;
  ts := c.TextStyle;

  if 0 = acol then
  begin
    c.Brush.Color := w.color and $FFFFFF;
    c.FillRect(arect);
    s := IntToStr(aRow);
    ts.Alignment := taCenter;
    c.Font.Color := 0;  // always black (even when the row is highlighted)
  end
  else if 1 = acol then
  begin
    s := w.name;
  end
  else if 2 = acol then
  begin
    s := w.ScalingStr;
    ts.Alignment := taRightJustify;
  end
  {
  else if 3 = acol then // cursor value
  begin
    s := w.GetValueStr(cursor_time);
    ts.Alignment := taRightJustify;
  end
  }
  else s := '?';

  c.TextStyle := ts;
  c.TextRect(aRect, arect.Left, arect.top, s);
end;

procedure TfrmMain.btnTdMinusClick(Sender : TObject);
begin
  scope.SetTimeDiv(FindNextTimeDiv(scope.TimeDiv, -1), scope.ViewStart + scope.ViewRange / 2);
  UpdateTimeDiv;
  UpdateScrollBar;
  scope.Repaint;
end;

procedure TfrmMain.btnTdPlusClick(Sender : TObject);
begin
  scope.SetTimeDiv(FindNextTimeDiv(scope.TimeDiv, 1), scope.ViewStart + scope.ViewRange / 2);
  UpdateTimeDiv;
  UpdateScrollBar;
  scope.Repaint;
end;

procedure TfrmMain.sbScopeScroll(Sender : TObject; ScrollCode : TScrollCode; var ScrollPos : Integer);
begin
  scope.ViewStart := scope.TimeDiv * ScrollPos;
  scope.Repaint;
  UpdateInfoGrid;
end;

procedure TfrmMain.pnlScopeViewMouseWheel(Sender : TObject;
  Shift : TShiftState; WheelDelta : Integer; MousePos : TPoint; var Handled : Boolean);
var
  pm : integer;
begin
  if WheelDelta < 0 then pm := 1
                    else pm := -1;

  if Shift = [] then  // normal time zoom
  begin
    scope.SetTimeDiv(FindNextTimeDiv(scope.TimeDiv, pm), scope.ConvertXToTime(MousePos.x));
    UpdateTimeDiv;
    UpdateScrollBar;
    scope.Repaint;
  end
  else if ssCtrl in Shift then
  begin
    if WheelDelta < 0 then ChangeWaveScale(0.5)
                      else ChangeWaveScale(2)
  end;

end;

procedure TfrmMain.pnlScopeViewMouseDown(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
var
  wd : TWaveDisplay;
  tm : TScopeMarker;
  di : integer;
begin
  if mbLeft = Button then
  begin
    tm := scope.FindNearestMarker(x, 5);
    if tm <> nil then
    begin
      marker_placing := tm.index + 1;
    end
    else
    begin
      time_dragging := true;
      drag_start_x := x;
      td_viewstart := scope.ViewStart;

      wd := scope.FindNearestWaveSample(x, y, c_value_snap_range, di);
      if wd <> nil then SelectWave(wd);
    end;
  end
  else if mbRight = Button then
  begin
    wd := scope.FindNearestWaveSample(x, y, c_value_snap_range, di);
    if wd = nil then EXIT;

    SelectWave(wd);

    wave_dragging := true;
    wdr_wave := wd;
    drag_start_y := y;
    wdr_start_offs := wd.viewoffset;
  end;
end;

procedure TfrmMain.pnlScopeViewMouseUp(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
begin
  if mbLeft = Button then
  begin
    if (marker_placing > 0) and not marker_was_moved then
    begin
      // keep the marker placing mode
    end
    else
    begin
      time_dragging := false;
      marker_placing := 0;
      marker_was_moved := false;
    end;
  end
  else if mbRight = Button then
  begin
    wave_dragging := false;
  end;
end;

procedure TfrmMain.pnlScopeViewMouseMove(Sender : TObject; Shift : TShiftState; X, Y : Integer);
var
  t : double;
  di : integer;
  wd : TWaveDisplay;
  instantupdate : boolean = False;
  ysnapping : boolean = True;
  ysnapgridrange : double; // in grid coordinates;
  newwoffs : double;
  selw : TWaveDisplay;
begin
  if time_dragging then
  begin
    scope.ViewStart := td_viewstart + (scope.ConvertXToTime(drag_start_x) - scope.ConvertXToTime(x));
    instantupdate := True;
    UpdateTimeDiv;
    UpdateScrollBar;
  end
  else if wave_dragging then
  begin
    newwoffs := wdr_start_offs + (scope.ConvertYToGrid(y) - scope.ConvertYToGrid(drag_start_y));

    if ssShift in Shift then ysnapping := False;
    if ysnapping then
    begin
      ysnapgridrange := scope.ConvertYToGrid(Height div 2 - c_ydrag_grid_snap_range) - scope.ConvertYToGrid(Height div 2);
      if (round(newwoffs) - ysnapgridrange <= newwoffs) and (round(newwoffs) + ysnapgridrange >= newwoffs) then
      begin
        newwoffs := round(newwoffs);
      end;
    end;

    wdr_wave.viewoffset := newwoffs;
    wdr_wave.ReDrawWave;
    instantupdate := True;
  end;

  t := scope.ConvertXToTime(x);
  cursor_time := t;

  if marker_placing > 0 then
  begin
    scope.SetMarker(marker_placing - 1, t);
    scope.timecursor.visible := false;
    marker_was_moved := true;

    selw := SelectedWave;
    if (selw <> nil) and (frmMeasureAB <> nil) then
    begin
      frmMeasureAB.wave := selw;
      frmMeasureAB.UpdateWaveInfo;
    end;
  end
  else
  begin
    scope.SetTimeCursor(t);
  end;

  wd := scope.FindNearestWaveSample(x, y, c_value_snap_range, di);
  scope.ShowSampleMarker(wd, di);

  if instantupdate
  then
      scope.DoOnPaint  // less lag, but delays other refreshes on linux
  else
      scope.Repaint;   // better for the other GUI elements

  //chgrid.Repaint;
  UpdateInfoGrid;
end;

procedure TfrmMain.miDrawStepsClick(Sender : TObject);
begin
  miDrawSteps.Checked := not miDrawSteps.Checked;
  scope.draw_steps := miDrawSteps.Checked;
  tbDrawSteps.Down := miDrawSteps.Checked;

  scope.RenderWaves;
  scope.Repaint;
end;

procedure TfrmMain.tbZoomInClick(Sender : TObject);
begin
  scope.SetTimeDiv(FindNextTimeDiv(scope.TimeDiv, -1), scope.ViewStart + scope.ViewRange / 2);
  UpdateTimeDiv;
  UpdateScrollBar;
  scope.Repaint;
end;

procedure TfrmMain.tbZoomOutClick(Sender : TObject);
begin
  scope.SetTimeDiv(FindNextTimeDiv(scope.TimeDiv, 1), scope.ViewStart + scope.ViewRange / 2);
  UpdateTimeDiv;
  UpdateScrollBar;
  scope.Repaint;
end;

procedure TfrmMain.tbMarkerAClick(Sender : TObject);
begin
  marker_placing := 1;
end;

procedure TfrmMain.tbMarkerClearClick(Sender : TObject);
begin
  scope.ClearMarkers;
  scope.Repaint;
end;

procedure TfrmMain.tbMarkerBClick(Sender : TObject);
begin
  marker_placing := 2;
end;

procedure TfrmMain.tbOpenClick(Sender : TObject);
begin
  if dlgFileOpen.Execute then
  begin
    LoadScopeFile(dlgFileOpen.FileName);
  end;
end;

procedure TfrmMain.tbSaveAsClick(Sender : TObject);
begin
  dlgFileSave.FileName := filename;
  if dlgFileSave.Execute then
  begin
    scope.SaveScopeFile(dlgFileSave.FileName);
    filename := dlgFileSave.FileName;

    Application.Title := ExtractFileName(filename) + ' - VScope';
    Caption := Application.Title;
  end;
end;

procedure TfrmMain.FormDropFiles(Sender : TObject; const FileNames : array of string);
begin
  LoadScopeFile(FileNames[0]);
end;

procedure TfrmMain.tbZoomAllClick(Sender : TObject);
begin
  scope.ViewRange := scope.TimeRange;
  scope.ViewStart := 0;
  scope.UpdateTimeDivInfo;
  UpdateTimeDiv;
  UpdateScrollBar;
  scope.Repaint;
end;

procedure TfrmMain.tbWavePropsClick(Sender : TObject);
var
  gpos : TPoint;
begin
  if SelectedWave = nil then SelectWave(0);
  if SelectedWave = nil then EXIT;

  if frmWaveProps = nil then
  begin
    Application.CreateForm(TfrmWaveProps, frmWaveProps);
    frmWaveProps.scope := self.scope;
    gpos := chgrid.ClientToScreen( Point(0,0) );
    frmWaveProps.Left := gpos.x;
    frmWaveProps.Top  := gpos.y + chgrid.Height - frmWaveProps.Height;
  end;

  frmWaveProps.wave := SelectedWave;
  frmWaveProps.UpdateWaveInfo;
  frmWaveProps.Show;
end;

procedure TfrmMain.pnlScopeViewDblClick(Sender : TObject);
begin
  tbWavePropsClick(Sender);
end;

procedure TfrmMain.miAboutBoxClick(Sender : TObject);
begin
  Application.CreateForm(TfrmAbout, frmAbout);
  frmAbout.ShowModal;
end;

procedure TfrmMain.FormKeyDown(Sender : TObject; var Key : Word; Shift : TShiftState);
var
  scpos : TPoint;
begin
  scpos := scope.ScreenToClient(Mouse.CursorPos);
  if (scpos.x < 0) or (scpos.x > scope.Width)
     or (scpos.y < 0) or (scpos.y > scope.Height)
  then
      EXIT;

  if key = VK_A then
  begin
    //marker_placing := 1;
    scope.SetMarker(0, cursor_time);
    scope.DoOnPaint;
    UpdateWavePopupWins;
  end
  else if key = VK_B then
  begin
    //marker_placing := 2;
    scope.SetMarker(1, cursor_time);
    scope.DoOnPaint;
    UpdateWavePopupWins;
  end
  else if key = VK_UP then
  begin
    tbOffsetUp.Click;
  end
  else if key = VK_DOWN then
  begin
    tbOffsetDown.Click;
  end
  else if key = VK_NEXT then
  begin
    tbScaleMinus.Click;
  end
  else if key = VK_PRIOR then
  begin
    tbScalePlus.Click;
  end;

  key := 0; // do not pass on the keypresses to other controls
end;

procedure TfrmMain.tbABMeasureClick(Sender : TObject);
begin
  if frmMeasureAB = nil then
  begin
    Application.CreateForm(TfrmMeasureAB, frmMeasureAB);
    frmMeasureAB.scope := self.scope;
  end;

  if SelectedWave = nil then SelectWave(0);
  frmMeasureAB.wave := SelectedWave;
  frmMeasureAB.UpdateWaveInfo;
  frmMeasureAB.Show;
end;

procedure TfrmMain.UpdateDrawSteps;
begin
  miDrawSteps.Checked := scope.draw_steps;
  tbDrawSteps.Down := scope.draw_steps;
end;

procedure TfrmMain.btnChScalePlusMinusClick(Sender : TObject);
begin
  if (Sender = tbScalePlus) or (Sender = miScalePlus)
  then
      ChangeWaveScale(2)
  else
      ChangeWaveScale(0.5);
end;

procedure TfrmMain.btnChOffsPlusMinusClick(Sender : TObject);
var
  wd : TWaveDisplay;
begin
  wd := SelectedWave;
  if wd = nil then EXIT;

  if (Sender = tbOffsetUp) or (Sender = miOffsetUp)
  then
      wd.viewoffset := round(wd.viewoffset * 2) / 2 + 0.5
  else
      wd.viewoffset := round(wd.viewoffset * 2) / 2 - 0.5;

  scope.RenderWaves;
  scope.Repaint;
  //chgrid.Refresh;
end;

procedure TfrmMain.miSaveClick(Sender : TObject);
begin
  scope.SaveScopeFile(filename);
end;

procedure TfrmMain.miAutoscaleClick(Sender : TObject);
var
  wd : TWaveDisplay;
begin
  wd := SelectedWave;
  if wd = nil then EXIT;

  wd.AutoScale;
  scope.RenderWaves;
  scope.Repaint;
end;

procedure TfrmMain.miAutoscaleAllClick(Sender : TObject);
begin
  scope.AutoScale;
  scope.RenderWaves;
  scope.Repaint;
end;

procedure TfrmMain.chgridSelection(Sender : TObject; aCol, aRow : Integer);
begin
  SelectWave(chgrid.row - 1);
end;

procedure TfrmMain.UpdateScrollBar;
var
  totaldivs : integer;
begin
  totaldivs := ceil(scope.TimeRange / scope.TimeDiv);
  sbScope.Max := trunc(totaldivs);// - 10 + 1;
  sbScope.Position := trunc(scope.ViewStart / scope.TimeDiv);
  sbScope.PageSize := 10;
end;

procedure TfrmMain.UpdateTimeDiv;
begin
  UpdateInfoGrid;
end;

procedure TfrmMain.UpdateChGrid;
begin
  chgrid.RowCount := 1 + scope.waves.Count;
  chgrid.Refresh;
  //UpdateSampling;
  //UpdateChGrid2;
end;

procedure TfrmMain.LoadScopeFile(afilename : string);
begin
  filename := afilename;
  try
    scope.LoadScopeFile(filename);
  except
    on e : Exception do
    begin
      MessageDlg('Error Loading Scope File', e.ToString, mtError, [mbOK], 0);
    end;
  end;

  UpdateScrollBar;
  UpdateTimeDiv;
  UpdateDrawSteps;

  UpdateChGrid;
  SelectWave(0);

  Application.Title := ExtractFileName(filename) + ' - VScope v'+VSCOPE_VERSION;
  Caption := Application.Title;
end;

procedure TfrmMain.SelectWave(awidx : integer);
var
  wd : TWaveDisplay;
  i : integer;
begin
  chgrid.Row := awidx + 1;
  for i := 0 to scope.waves.Count - 1 do
  begin
    wd := scope.waves[i];
    if i = awidx then
    begin
      wd.wshp.alpha := 0.75 * wd.basealpha * 1.3333;
      wd.wshp.parent.MoveTop(wd.wshp);
      wd.zeroline.parent.MoveTop(wd.zeroline);
    end
    else
    begin
      wd.wshp.alpha := 0.75 * wd.basealpha;
    end;
  end;

  scope.Repaint;

  UpdateWavePopupWins;
end;

procedure TfrmMain.SelectWave(wd : TWaveDisplay);
var
  i : integer;
begin
  for i := 0 to scope.waves.Count - 1 do
  begin
    if scope.waves[i] = wd then
    begin
      SelectWave(i);
      break;
    end;
  end;
end;

function TfrmMain.SelectedWave : TWaveDisplay;
var
  wi : integer;
begin
  wi := chgrid.Row - 1;
  if (wi >= 0) and (wi < scope.waves.Count) then  result := scope.waves[wi]
                                            else  result := nil;
end;

procedure TfrmMain.ChangeWaveScale(amul : double);
var
  wd : TWaveDisplay;
  oldscale : double;
  newscale : double;
begin
  wd := SelectedWave;
  if wd = nil then EXIT;
  oldscale := wd.viewscale;
  newscale := oldscale;
  while oldscale = wd.viewscale do
  begin
    newscale := newscale * amul;
    wd.viewscale := wd.FindNearestScale(newscale);
  end;

  wd.CorrectOffset;
  scope.RenderWaves;
  scope.Repaint;
  chgrid.Refresh;
end;

procedure TfrmMain.UpdateInfoGrid;
var
  s : string;
  sm : TScopeMarker;
begin
  txtTimeUnit.Caption := scope.time_unit;
  txtTotalLength.Caption := format('%.6f', [scope.TimeRange]);
  txtViewLength.Caption := format('%.6f', [scope.ViewRange]);
  txtCursorTime.Caption := format('%.6f', [cursor_time]);

  sm := scope.marker[0];
  if sm.Visible
  then
      s := format('%.6f', [cursor_time - sm.mtime])
  else
      s := '-';
  txtCursorToA.Caption := s;

  sm := scope.marker[1];
  if sm.Visible
  then
      s := format('%.6f', [cursor_time - sm.mtime])
  else
      s := '-';
  txtCursorToB.Caption := s;
end;

procedure TfrmMain.UpdateWavePopupWins;
var
  selw : TWaveDisplay;
begin
  selw := SelectedWave;
  if selw = nil then EXIT;
  if frmWaveProps <> nil then
  begin
    frmWaveProps.wave := selw;
    frmWaveProps.UpdateWaveInfo;
  end;

  if frmMeasureAB <> nil then
  begin
    frmMeasureAB.wave := selw;
    frmMeasureAB.UpdateWaveInfo;
  end;
end;

procedure TfrmMain.miExitClick(Sender : TObject);
begin
  Application.Terminate;
end;


end.

