unit form_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  ExtCtrls, StdCtrls, math, ddgfx, dglOpenGL, vscope_data, vscope_display;

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
    procedure miExitClick(Sender : TObject);

    procedure FormCreate(Sender : TObject);
  private

  public
    scope : TScopeDisplay;

    procedure UpdateScrollBar;
    procedure UpdateTimeDiv;

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

  scope.draw_steps := false;
  //cbDrawSteps.Checked := scope.draw_steps;

  scope.LoadScopeFile('vscope.json');

  UpdateScrollBar;
  UpdateTimeDiv;

  //scope.OnMouseMove := @pnlScopeMouseMove;
  //scope.OnMouseDown := @pnlScopeMouseDown;
  //scope.OnMouseUp   := @pnlScopeMouseUp;
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

end;

procedure TfrmMain.miExitClick(Sender : TObject);
begin
  Application.Terminate;
end;


end.

