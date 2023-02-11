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
  ExtCtrls, StdCtrls, Grids, Buttons, math, ddgfx, dglOpenGL, vscope_data,
  vscope_display, Types;

const
  c_value_snap_range = 10;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    mainmenu : TMainMenu;
    miFile : TMenuItem;
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
    ToolButton1 : TToolButton;
    tbSaveAs : TToolButton;
    imglist : TImageList;
    ToolButton2 : TToolButton;
    tbDrawSteps : TToolButton;
    menuView : TMenuItem;
    miDrawSteps : TMenuItem;
    ToolButton3 : TToolButton;
    tbZoomIn : TToolButton;
    tbZoomOut : TToolButton;
    Separator2 : TMenuItem;
    miZoomIn : TMenuItem;
    miZoomOut : TMenuItem;
    tbScalePlus : TToolButton;
    tbScaleMinus : TToolButton;
    tbOffsetUp : TToolButton;
    tbOffsetDown : TToolButton;
    ToolButton4 : TToolButton;
    Label2 : TLabel;
    txtViewStart : TStaticText;
    Label3 : TLabel;
    txtCursorTime : TStaticText;
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

  private

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

    procedure UpdateScrollBar;
    procedure UpdateTimeDiv;

    procedure UpdateChGrid;

    procedure SelectWave(awidx : integer); overload;
    procedure SelectWave(wd : TWaveDisplay); overload;

    function SelectedWave : TWaveDisplay;

    procedure ChangeWaveScale(amul : double);

  end;

var
  frmMain : TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender : TObject);
//var
//  w : TWaveDisplay;
begin

  filename := 'vscope.json';

  scope := TScopeDisplay.Create(self, pnlScopeView);
  scope.ViewStart := 0;
  scope.ViewRange := 5;
  scope.ViewStart := 0; //-2;

  scope.draw_steps := true;
  miDrawSteps.Checked := scope.draw_steps;
  tbDrawSteps.Down := scope.draw_steps;

  scope.LoadScopeFile(filename);
  //scope.AutoScale;

  UpdateScrollBar;
  UpdateTimeDiv;

  scope.OnMouseMove := @pnlScopeViewMouseMove;
  scope.OnMouseDown := @pnlScopeViewMouseDown;
  scope.OnMouseUp   := @pnlScopeViewMouseUp;

  UpdateChGrid;
  SelectWave(0);

  scope.valgrp.visible := false;
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
  scope.DoOnPaint;
end;

procedure TfrmMain.btnTdPlusClick(Sender : TObject);
begin
  scope.SetTimeDiv(FindNextTimeDiv(scope.TimeDiv, 1), scope.ViewStart + scope.ViewRange / 2);
  UpdateTimeDiv;
  UpdateScrollBar;
  scope.DoOnPaint;
end;

procedure TfrmMain.sbScopeScroll(Sender : TObject; ScrollCode : TScrollCode; var ScrollPos : Integer);
begin
  scope.ViewStart := scope.TimeDiv * ScrollPos;
  txtViewStart.Caption := format('%.6f', [scope.ViewStart]);
  scope.Repaint;
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
    scope.DoOnPaint;
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
  st : double;
begin
  if mbLeft = Button then
  begin
    time_dragging := true;
    drag_start_x := x;
    td_viewstart := scope.ViewStart;

    wd := scope.FindNearestWaveSample(x, y, c_value_snap_range, st);
    SelectWave(wd);
  end
  else if mbRight = Button then
  begin
    wd := scope.FindNearestWaveSample(x, y, c_value_snap_range, st);
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
    time_dragging := false;
  end
  else if mbRight = Button then
  begin
    wave_dragging := false;
  end;
end;

procedure TfrmMain.pnlScopeViewMouseMove(Sender : TObject; Shift : TShiftState; X, Y : Integer);
var
  t : double;
  st : double;
  wd : TWaveDisplay;
begin

  if time_dragging then
  begin
    scope.ViewStart := td_viewstart + (scope.ConvertXToTime(drag_start_x) - scope.ConvertXToTime(x));
    UpdateTimeDiv;
    UpdateScrollBar;
  end
  else if wave_dragging then
  begin
    wdr_wave.viewoffset := wdr_start_offs + (scope.ConvertYToGrid(y) - scope.ConvertYToGrid(drag_start_y));
    wdr_wave.ReDrawWave;
  end;

  t := scope.ConvertXToTime(x);
  cursor_time := t;
  txtCursorTime.Caption := format('%.6f', [t]);
  scope.SetTimeCursor(t);


  wd := scope.FindNearestWaveSample(x, y, c_value_snap_range, st);
  scope.ShowSampleMarker(wd, st);

  scope.Repaint;
  //chgrid.Repaint;
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
  scope.DoOnPaint;
end;

procedure TfrmMain.tbZoomOutClick(Sender : TObject);
begin
  scope.SetTimeDiv(FindNextTimeDiv(scope.TimeDiv, 1), scope.ViewStart + scope.ViewRange / 2);
  UpdateTimeDiv;
  UpdateScrollBar;
  scope.DoOnPaint;
end;

procedure TfrmMain.btnChScalePlusMinusClick(Sender : TObject);
begin
  if Sender = tbScalePlus
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

  if Sender = tbOffsetUp
  then
      wd.viewoffset += 0.25
  else
      wd.viewoffset -= 0.25;

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
  txtViewStart.Caption := format('%.6f', [scope.ViewStart]);
end;

procedure TfrmMain.UpdateChGrid;
begin
  chgrid.RowCount := 1 + scope.waves.Count;
  chgrid.Refresh;
  //UpdateSampling;
  //UpdateChGrid2;
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
      wd.wshp.alpha := 0.8;
      wd.wshp.parent.MoveTop(wd.wshp);
      wd.zeroline.parent.MoveTop(wd.zeroline);
    end
    else
    begin
      wd.wshp.alpha := 0.5;
    end;
  end;

  wd := scope.waves[awidx];

  scope.Repaint;
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

procedure TfrmMain.miExitClick(Sender : TObject);
begin
  Application.Terminate;
end;


end.

