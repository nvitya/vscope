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
    miWaveLoop : TMenuItem;
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
    Separator3 : TMenuItem;
    miCutWaves : TMenuItem;
    miCutCurWave : TMenuItem;
    Separator6 : TMenuItem;
    miSyncWave : TMenuItem;
    miWaveDuplicate : TMenuItem;
    miWaveDelete : TMenuItem;
    miFileMerge : TMenuItem;
    chgrid : TStringGrid;
    Label8 : TLabel;
    Bevel13 : TBevel;
    txtZeroTime : TStaticText;
    procedure miExitClick(Sender : TObject);

    procedure FormCreate(Sender : TObject);

    procedure chgridDrawCell(Sender : TObject; aCol, aRow : Integer; aRect : TRect; aState : TGridDrawState);
    procedure btnTdPlusClick(Sender : TObject);
    procedure btnTdMinusClick(Sender : TObject);
    procedure miWaveLoopClick(Sender : TObject);
    procedure sbScopeScroll(Sender : TObject; ScrollCode : TScrollCode; var ScrollPos : Integer);

    procedure btnChScalePlusMinusClick(Sender : TObject);
    procedure btnChOffsPlusMinusClick(Sender : TObject);

    procedure miAutoscaleClick(Sender : TObject);
    procedure miAutoscaleAllClick(Sender : TObject);
    procedure chgridSelection(Sender : TObject; aCol, aRow : Integer);

    // mouse events
    procedure pnlScopeViewMouseWheel(Sender : TObject; Shift : TShiftState; WheelDelta : Integer; MousePos : TPoint; var Handled : Boolean);
    procedure pnlScopeViewMouseDown(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
    procedure pnlScopeViewMouseUp(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
    procedure pnlScopeViewMouseMove(Sender : TObject; Shift : TShiftState; X, Y : Integer);

    procedure FormKeyDown(Sender : TObject; var Key : Word; Shift : TShiftState);

    procedure miDrawStepsClick(Sender : TObject);
    procedure tbZoomInClick(Sender : TObject);
    procedure tbZoomOutClick(Sender : TObject);
    procedure tbMarkerAClick(Sender : TObject);
    procedure tbMarkerClearClick(Sender : TObject);
    procedure tbMarkerBClick(Sender : TObject);
    procedure FormDropFiles(Sender : TObject; const FileNames : array of string);
    procedure tbZoomAllClick(Sender : TObject);
    procedure tbWavePropsClick(Sender : TObject);
    procedure pnlScopeViewDblClick(Sender : TObject);
    procedure miAboutBoxClick(Sender : TObject);
    procedure tbABMeasureClick(Sender : TObject);
    procedure miCutWavesClick(Sender : TObject);
    procedure miCutCurWaveClick(Sender : TObject);
    procedure miSyncWaveClick(Sender : TObject);
    procedure miWaveDuplicateClick(Sender : TObject);
    procedure miWaveDeleteClick(Sender : TObject);

    procedure tbOpenClick(Sender : TObject);
    procedure miFileMergeClick(Sender : TObject);
    procedure miSaveClick(Sender : TObject);
    procedure tbSaveAsClick(Sender : TObject);
    procedure chgridGetCheckboxState(Sender : TObject; ACol, ARow : Integer;
      var Value : TCheckboxState);
    procedure chgridSetCheckboxState(Sender : TObject; ACol, ARow : Integer;
      const Value : TCheckboxState);
    procedure chgridDblClick(Sender : TObject);
    procedure chgridKeyDown(Sender : TObject; var Key : Word;
      Shift : TShiftState);
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

    wave_shifting   : boolean;
    wshift_startt : double;

    wave_stretching : boolean;
    wstretch_fixdi   : integer;
    wstretch_smpcnt  : double; // double here !
    wstretch_fixtime : double;

    wave_dragging : boolean; // wave offset change
    wdr_wave : TWaveDisplay;
    wdr_start_offs : double;

    marker_placing : integer;
    marker_was_moved : boolean;

    procedure UpdateScrollBar;
    procedure UpdateTimeDiv;

    procedure UpdateChGrid;

    procedure LoadScopeFile(afilename : string);
    procedure MergeScopeFile(afilename : string);

    procedure SelectWave(awidx : integer); overload;
    procedure SelectWave(wd : TWaveDisplay); overload;

    function SelectedWave : TWaveDisplay;

    procedure ChangeWaveScale(amul : double);

    procedure UpdateInfoGrid;

    procedure UpdateWavePopupWins;

    procedure UpdateAfterSync;

  end;

var
  frmMain : TfrmMain;

implementation

uses
  form_wave_props, form_measure_ab, version_vscope, form_about, form_sync_wave, form_wave_loop;

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

  if acol <> 0 then Exit; // this is only for the channel number

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
{
  else if 1 = acol then
  begin
    s := w.name;
  end
  else if 2 = acol then
  begin
    s := w.ScalingStr;
    ts.Alignment := taRightJustify;
  end
}
  {
  else if 3 = acol then // cursor value
  begin
    s := w.GetValueStr(cursor_time);
    ts.Alignment := taRightJustify;
  end
  }
  else s := '';

  c.TextStyle := ts;
  c.TextRect(aRect, arect.Left, arect.top, s);
end;

procedure TfrmMain.btnTdMinusClick(Sender : TObject);
begin
  scope.SetTimeDiv(scope.FindNextTimeDiv(scope.TimeDiv, -1), scope.ViewStart + scope.ViewRange / 2);
  UpdateTimeDiv;
  UpdateScrollBar;
  scope.Repaint;
end;

procedure TfrmMain.miWaveLoopClick(Sender : TObject);
var
  gpos : TPoint;
begin
  if frmWaveLoop = nil then
  begin
    Application.CreateForm(TfrmWaveLoop, frmWaveLoop);
    frmWaveLoop.scope := self.scope;

    gpos := scope.ClientToScreen( Point(0,0) );
    frmWaveLoop.Left := gpos.x + scope.Width div 2 - frmWaveLoop.Width div 2;
    frmWaveLoop.Top  := gpos.y + scope.Height - frmWaveLoop.Height;
  end;

  if SelectedWave = nil then SelectWave(0);
  frmWaveLoop.wave := SelectedWave;
  frmWaveLoop.SetupWave;
  frmWaveLoop.Show;
  frmWaveLoop.MarkersChanged;
  scope.RePaint;
end;

procedure TfrmMain.btnTdPlusClick(Sender : TObject);
begin
  scope.SetTimeDiv(scope.FindNextTimeDiv(scope.TimeDiv, 1), scope.ViewStart + scope.ViewRange / 2);
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
    scope.SetTimeDiv(scope.FindNextTimeDiv(scope.TimeDiv, pm), scope.ConvertXToTime(MousePos.x));
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
      wave_shifting := false;
      wave_stretching := false;
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
      wd := scope.FindNearestWaveSample(x, y, c_value_snap_range, di);
      if wd <> nil then SelectWave(wd);

      drag_start_x := x;

      if (frmSyncWave <> nil) and (frmSyncWave.wave = wd) then
      begin
        if frmSyncWave.rbStrechToA.Checked and scope.marker[0].Visible then
        begin
          wave_stretching := true;
          wstretch_fixtime := scope.marker[0].mtime;
          wstretch_fixdi := trunc((wstretch_fixtime - wd.startt) / wd.samplt);  // might be out of range !
          wstretch_smpcnt := (scope.ConvertXToTime(x) - wstretch_fixtime) / wd.samplt;
        end
        else if frmSyncWave.rbStrechToB.Checked and scope.marker[1].Visible then
        begin
          wave_stretching := true;
          wstretch_fixtime := scope.marker[1].mtime;
          wstretch_fixdi := trunc((wstretch_fixtime - wd.startt) / wd.samplt);  // might be out of range !
          wstretch_smpcnt := (scope.ConvertXToTime(x) - wstretch_fixtime) / wd.samplt;
        end
        else
        begin
          wave_shifting := true;
          wshift_startt := wd.startt;
        end;
        wdr_wave := wd;
      end
      else   // view dragging
      begin
        time_dragging := true;
        td_viewstart := scope.ViewStart;
      end;
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

procedure TfrmMain.pnlScopeViewMouseMove(Sender : TObject; Shift : TShiftState; X, Y : Integer);
var
  t, tdiff : double;
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
  else if wave_shifting then
  begin
    wdr_wave.startt := wshift_startt + (scope.ConvertXToTime(x) - scope.ConvertXToTime(drag_start_x));

    wdr_wave.ReDrawWave;
    instantupdate := True;
    if frmSyncWave <> nil then
    begin
      frmSyncWave.UpdateWaveInfo;
    end;
  end
  else if wave_stretching then
  begin
    tdiff := scope.ConvertXToTime(x) - wstretch_fixtime;
    wdr_wave.samplt := tdiff / wstretch_smpcnt;
    wdr_wave.startt := wstretch_fixtime - wstretch_fixdi * wdr_wave.samplt;

    wdr_wave.ReDrawWave;
    instantupdate := True;
    if frmSyncWave <> nil then
    begin
      frmSyncWave.UpdateWaveInfo;
    end;
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

    if frmWaveLoop <> nil then frmWaveLoop.MarkersChanged;
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
  scope.SetTimeDiv(scope.FindNextTimeDiv(scope.TimeDiv, -1), scope.ViewStart + scope.ViewRange / 2);
  UpdateTimeDiv;
  UpdateScrollBar;
  scope.Repaint;
end;

procedure TfrmMain.tbZoomOutClick(Sender : TObject);
begin
  scope.SetTimeDiv(scope.FindNextTimeDiv(scope.TimeDiv, 1), scope.ViewStart + scope.ViewRange / 2);
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

procedure TfrmMain.chgridGetCheckboxState(Sender : TObject; ACol,
  ARow : Integer; var Value : TCheckboxState);
begin
  //if ((arow and 1) = 1) then Value := cbChecked else Value := cbUnchecked;
end;

procedure TfrmMain.chgridSetCheckboxState(Sender : TObject; ACol, ARow : Integer; const Value : TCheckboxState);
var
  wi : integer;
  wd : TWaveDisplay;
begin
  wi := ARow - 1;
  if (wi < 0) or (wi >= scope.waves.Count)
  then
      EXIT;

  wd := scope.waves[wi];
  wd.visible := (Value = cbChecked);
  chgrid.Cells[ACol, ARow] := IntToStr(ord(wd.visible));

  UpdateWavePopupWins;
  scope.RenderWaves;
  scope.Refresh;
end;

procedure TfrmMain.chgridDblClick(Sender : TObject);
var
  pt: TPoint;
  col, row : integer;
begin
  pt := chgrid.ScreenToClient(Mouse.CursorPos);
  chgrid.MouseToCell(pt.X, pt.Y, Col, Row);
  if col <> 3 then
  begin
    tbWavePropsClick(Sender);
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
  gpos, mpos : TPoint;
  maxx : integer;
begin
  if SelectedWave = nil then SelectWave(0);
  if SelectedWave = nil then EXIT;

  if frmWaveProps = nil then
  begin
    Application.CreateForm(TfrmWaveProps, frmWaveProps);
    frmWaveProps.scope := self.scope;
    gpos := chgrid.ClientToScreen( Point(0,0) );
    mpos := Mouse.CursorPos;

    maxx := gpos.x - frmWaveProps.Width + chgrid.Width;
    //frmWaveProps.Left := maxx;
    frmWaveProps.Left := mpos.x - frmWaveProps.Width div 2;
    if frmWaveProps.Left > maxx then frmWaveProps.Left := maxx;
    //frmWaveProps.Top  := gpos.y + chgrid.Height - frmWaveProps.Height;
    frmWaveProps.Top  := mpos.y + 20;
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
  w : TWaveDisplay;
begin
  scpos := scope.ScreenToClient(Mouse.CursorPos);
  if (scpos.x < 0) or (scpos.x > scope.Width)
     or (scpos.y < 0) or (scpos.y > scope.Height)
  then
      EXIT;

  w := SelectedWave;

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
  else if key = VK_V then
  begin
    if w <> nil then
    begin
      w.visible := not w.visible;
      scope.RenderWaves;
      scope.DoOnPaint;
      UpdateChGrid;
      UpdateWavePopupWins;
    end;
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
  end
  else if (key >= VK_1) and (key <= VK_9) then
  begin
    if w <> nil then
    begin
      w.groupid := (key - VK_0);
      UpdateChGrid;
      UpdateWavePopupWins;
    end;
  end
  ;


  key := 0; // do not pass on the keypresses to other controls
end;

procedure TfrmMain.chgridKeyDown(Sender : TObject; var Key : Word; Shift : TShiftState);
var
  w : TWaveDisplay;
begin
  w := SelectedWave;
  if w = nil then Exit;

  if (key >= VK_1) and (key <= VK_9) then
  begin
    w.groupid := (key - VK_0);
    UpdateChGrid;
    UpdateWavePopupWins;
    key := 0;
  end
  else if key = VK_V then
  begin
    w.visible := not w.visible;
    scope.RenderWaves;
    scope.DoOnPaint;
    UpdateChGrid;
    UpdateWavePopupWins;
    key := 0;
  end
  ;
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

procedure TfrmMain.miCutWavesClick(Sender : TObject);
var
  wd : TWaveDisplay;
  minst, stcorr : double;
begin
  if (scope.waves.Count < 1) or (not scope.marker[0].Visible) or (not scope.marker[1].Visible)
  then
      EXIT;

  minst := scope.MaxTime;
  for wd in scope.waves do
  begin
    wd.CutData(scope.marker[0].mtime, scope.marker[1].mtime);
    if wd.startt < minst then minst := wd.startt;
  end;

  // adjust the start times
  stcorr := minst - scope.MinTime;
  if stcorr > 0 then
  begin
    for wd in scope.waves do
    begin
      wd.startt -= stcorr;
    end;
  end;

  scope.CalcTimeRange;  // re-calculate the time ranges
  scope.marker[0].mtime -= stcorr;
  scope.marker[1].mtime -= stcorr;

  tbZoomAllClick(nil);
end;

procedure TfrmMain.miCutCurWaveClick(Sender : TObject);
var
  wd : TWaveDisplay;
begin
  if scope.waves.Count <= 1 then
  begin
    miCutWavesClick(Sender);
    EXIT;
  end;

  wd := SelectedWave;

  if (wd = nil) or (not scope.marker[0].Visible) or (not scope.marker[1].Visible)
  then
      EXIT;

  wd.CutData(scope.marker[0].mtime, scope.marker[1].mtime);

  scope.CalcTimeRange;  // re-calculate the time ranges
  scope.Repaint;
end;

procedure TfrmMain.miSyncWaveClick(Sender : TObject);
var
  gpos : TPoint;
begin
  if frmSyncWave = nil then
  begin
    Application.CreateForm(TfrmSyncWave, frmSyncWave);
    frmSyncWave.scope := self.scope;

    gpos := scope.ClientToScreen( Point(0,0) );
    frmSyncWave.Left := gpos.x + scope.Width div 2 - frmSyncWave.Width div 2;
    frmSyncWave.Top  := gpos.y + scope.Height - frmSyncWave.Height;
  end;

  if SelectedWave = nil then SelectWave(0);
  frmSyncWave.wave := SelectedWave;
  frmSyncWave.SetupWave;
  frmSyncWave.Show;
end;

procedure TfrmMain.miWaveDuplicateClick(Sender : TObject);
var
  sw, dw : TWaveDisplay;
begin
  sw := SelectedWave;
  if sw = nil then EXIT;

  dw := scope.DuplicateWave(sw);
  UpdateChGrid;

  SelectWave(dw);
  scope.RenderWaves;
  scope.Repaint;
end;

procedure TfrmMain.miWaveDeleteClick(Sender : TObject);
var
  sw : TWaveDisplay;
begin
  sw := SelectedWave;
  if sw = nil then EXIT;

  if mrNo = MessageDlg('Delete Wave',
     'Are you sure you want to delete the following wave:'#13
     +'"'+sw.name+'" ?',
     mtConfirmation, mbYesNo, 0)
  then
      EXIT;

  scope.DeleteWave(sw);
  scope.Repaint;
  UpdateChGrid;
end;

procedure TfrmMain.miFileMergeClick(Sender : TObject);
begin
  if dlgFileOpen.Execute then
  begin
    MergeScopeFile(dlgFileOpen.FileName);
  end;
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

  wd.AutoScale(-5, 5);
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
var
  wd : TWaveDisplay;
  row : integer;
  col : integer;
  coltag : integer;
  s : string;
begin
  chgrid.RowCount := 1 + scope.waves.Count;
  row := 1;
  for wd in scope.waves do
  begin
    for col := 0 to chgrid.ColCount-1 do
    begin
      coltag := chgrid.Columns[col].Tag; // kind of equivalend of field name, allows free column re-ordering
      if      coltag = 1 then  s := IntToStr(row)  // channel number
      else if coltag = 2 then  s := wd.name        // channel name
      else if coltag = 3 then  s := wd.ScalingStr
      else if coltag = 4 then  s := IntToStr(ord(wd.visible))
      else if coltag = 5 then  s := IntToStr(wd.groupid)
      ;
      chgrid.Cells[col, row] := s;
    end;
    Inc(row);
  end;
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

procedure TfrmMain.MergeScopeFile(afilename : string);
var
  mscope : TScopeData;
  sw : TWaveData;
  dw : TWaveDisplay;
begin
  mscope := TScopeData.Create;
  try
    mscope.LoadFromFile(afilename);
  except
    on e : Exception do
    begin
      MessageDlg('Error Loading Scope File', e.ToString, mtError, [mbOK], 0);
      mscope.Free;
      EXIT;
    end;
  end;

  for sw in mscope.waves do
  begin
    dw := scope.AddWave(sw.name, sw.samplt);
    dw.CopyFrom(sw);
  end;

  mscope.Free;

  scope.CalcTimeRange;

  UpdateScrollBar;
  UpdateTimeDiv;
  UpdateChGrid;

  scope.RenderWaves;
  scope.Repaint;
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
  UpdateChGrid;
end;

procedure TfrmMain.UpdateInfoGrid;
var
  s : string;
  sm : TScopeMarker;
begin
  txtZeroTime.Caption := scope.FormatAbsTime(0, false);
  txtTimeUnit.Caption := scope.time_unit;
  txtTotalLength.Caption := scope.FormatTime(scope.TimeRange);
  txtViewLength.Caption := scope.FormatTime(scope.ViewRange);
  txtCursorTime.Caption := scope.FormatAbsTime(cursor_time);

  sm := scope.marker[0];
  if sm.Visible
  then
      s := scope.FormatTime(cursor_time - sm.mtime)
  else
      s := '-';
  txtCursorToA.Caption := s;

  sm := scope.marker[1];
  if sm.Visible
  then
      s := scope.FormatTime(cursor_time - sm.mtime)
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

  if frmWaveLoop <> nil then
  begin
    frmWaveLoop.MarkersChanged;
  end;
end;

procedure TfrmMain.UpdateAfterSync;
begin
  scope.CalcTimeRange;
  UpdateScrollBar;
  UpdateTimeDiv;
end;

procedure TfrmMain.miExitClick(Sender : TObject);
begin
  Application.Terminate;
end;


end.

