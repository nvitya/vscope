unit form_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  ExtCtrls, StdCtrls, Grids, Buttons, math, ddgfx, dglOpenGL, vscope_data,
  vscope_display, Types;

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
    pnlBottom : TPanel;
    sbScope : TScrollBar;
    pnlScopeView : TPanel;
    pnlRight : TPanel;
    pnlWaves : TPanel;
    pnlInfo : TPanel;
    chgrid : TDrawGrid;
    btnChOffsPlus : TBitBtn;
    btnChScalePlus : TBitBtn;
    btnChOffsMinus : TBitBtn;
    btnChScaleMinus : TBitBtn;
    txtChInfo : TStaticText;
    Label1 : TLabel;
    txtTimeDiv : TStaticText;
    btnTdPlus : TBitBtn;
    btnTdMinus : TBitBtn;
    Label2 : TLabel;
    txtViewStart : TStaticText;
    cbDrawSteps : TCheckBox;
    Label3 : TLabel;
    txtCursorTime : TStaticText;
    Label4 : TLabel;
    txtCursorValue : TStaticText;
    procedure miExitClick(Sender : TObject);

    procedure FormCreate(Sender : TObject);

    procedure chgridDrawCell(Sender : TObject; aCol, aRow : Integer; aRect : TRect; aState : TGridDrawState);
    procedure chgridClick(Sender : TObject);
    procedure btnTdPlusClick(Sender : TObject);
    procedure btnTdMinusClick(Sender : TObject);
    procedure sbScopeScroll(Sender : TObject; ScrollCode : TScrollCode;
      var ScrollPos : Integer);
    procedure pnlScopeViewMouseWheel(Sender : TObject; Shift : TShiftState;
      WheelDelta : Integer; MousePos : TPoint; var Handled : Boolean);
    procedure pnlScopeViewMouseDown(Sender : TObject; Button : TMouseButton;
      Shift : TShiftState; X, Y : Integer);
    procedure pnlScopeViewMouseMove(Sender : TObject; Shift : TShiftState; X,
      Y : Integer);
    procedure pnlScopeViewMouseUp(Sender : TObject; Button : TMouseButton;
      Shift : TShiftState; X, Y : Integer);
    procedure cbDrawStepsChange(Sender : TObject);
  private

  public
    scope : TScopeDisplay;

    vertdrag : boolean;
    vdx : integer;
    vdviewstart : double;

    procedure UpdateScrollBar;
    procedure UpdateTimeDiv;

    procedure UpdateChGrid;

    procedure SelectWave(awidx : integer);
    function SelectedWave : TWaveDisplay;

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
  scope := TScopeDisplay.Create(self, pnlScopeView);
  scope.ViewStart := 0;
  scope.ViewRange := 5;
  scope.ViewStart := 0; //-2;

  scope.draw_steps := true;
  cbDrawSteps.Checked := scope.draw_steps;

  scope.LoadScopeFile('vscope.json');

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
    s := '...'; //item.ScalingStr; //format('%.6f', [item.vscale]);
    //s := format('%.6f', [item.vscale]);
  end
  else s := '?';

  c.TextStyle := ts;
  c.TextRect(aRect, arect.Left, arect.top, s);
end;

procedure TfrmMain.chgridClick(Sender : TObject);
begin
  SelectWave(chgrid.row - 1);
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

  scope.SetTimeDiv(FindNextTimeDiv(scope.TimeDiv, pm), scope.ConvertXToTime(MousePos.x));
  UpdateTimeDiv;
  UpdateScrollBar;
  scope.DoOnPaint;
end;

procedure TfrmMain.pnlScopeViewMouseDown(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
begin
  if mbLeft = Button then
  begin
    vertdrag := true;
    vdx := x;
    vdviewstart := scope.ViewStart;
  end;
end;

procedure TfrmMain.pnlScopeViewMouseUp(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
begin
  if mbLeft = Button then
  begin
    vertdrag := false;
  end;
end;

procedure TfrmMain.pnlScopeViewMouseMove(Sender : TObject; Shift : TShiftState; X, Y : Integer);
var
  t : double;
  wd : TWaveDisplay;
begin

  if vertdrag then
  begin
    scope.ViewStart := vdviewstart + (scope.ConvertXToTime(vdx) - scope.ConvertXToTime(x));
    UpdateTimeDiv;
    UpdateScrollBar;
    //scope.DoOnPaint;
    //scope.Repaint;
  end
  else
  begin

    //scope.valgrp.x := x;
    //scope.valgrp.y := y;
    //scope.DoOnPaint; // less frame delay
    ////scope.Repaint; // 2-3 frame delay noticeable
  end;

  t := scope.ConvertXToTime(x);
  txtCursorTime.Caption := format('%.6f', [t]);
  scope.SetTimeCursor(t);

  wd := SelectedWave;
  if wd = nil then
  begin
    txtCursorValue.Caption := '-';
  end
  else
  begin
    txtCursorValue.Caption := wd.name + ' = ' + FloatToStr(wd.GetValueAt(t));
  end;

  scope.Repaint;
end;

procedure TfrmMain.cbDrawStepsChange(Sender : TObject);
begin
  scope.draw_steps := cbDrawSteps.Checked;
  scope.RenderWaves;
  scope.Repaint;
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
  txtTimeDiv.Caption := format('%.6f s', [scope.TimeDiv]);
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
    end
    else
    begin
      wd.wshp.alpha := 0.5;
    end;
  end;

  wd := scope.waves[awidx];
  txtChInfo.Caption := wd.name;

  scope.Repaint;
end;

function TfrmMain.SelectedWave : TWaveDisplay;
var
  wi : integer;
begin
  wi := chgrid.Row - 1;
  if (wi >= 0) and (wi < scope.waves.Count) then  result := scope.waves[wi]
                                            else  result := nil;
end;

procedure TfrmMain.miExitClick(Sender : TObject);
begin
  Application.Terminate;
end;


end.

