unit form_wave_props;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  Grids, ComCtrls, vscope_data, vscope_display;

type

  { TfrmWaveProps }

  TfrmWaveProps = class(TForm)
    Label1 : TLabel;
    edName : TEdit;
    gridi : TStringGrid;
    tbAlpha : TTrackBar;
    btnColor : TColorButton;
    dlgColors : TColorDialog;
    Label2 : TLabel;
    edDataUnit : TEdit;
    btnRescale : TBitBtn;
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure btnColorDialogClick(Sender : TObject);
    procedure FormShow(Sender : TObject);
    procedure btnColorColorChanged(Sender : TObject);
    procedure edNameChange(Sender : TObject);
    procedure tbAlphaChange(Sender : TObject);
    procedure edDataUnitChange(Sender : TObject);
    procedure btnRescaleClick(Sender : TObject);
  private

  public
    wave  : TWaveDisplay;
    scope : TScopeDisplay;

    procedure UpdateWaveInfo;

  end;

var
  frmWaveProps : TfrmWaveProps;

implementation

uses
  form_main, form_wave_rescale;

{$R *.lfm}

{ TfrmWaveProps }

procedure TfrmWaveProps.FormClose(Sender : TObject; var CloseAction : TCloseAction);
begin
  CloseAction := caFree;
  frmWaveProps := nil;
end;

procedure TfrmWaveProps.btnColorDialogClick(Sender : TObject);
begin

end;

procedure TfrmWaveProps.FormShow(Sender : TObject);
begin
  UpdateWaveInfo;
end;

procedure TfrmWaveProps.btnColorColorChanged(Sender : TObject);
begin
  wave.color := (wave.color and $FF000000) or (btnColor.ButtonColor and $00FFFFFF);
  scope.RenderWaves;
  scope.DoOnPaint;
end;

procedure TfrmWaveProps.edNameChange(Sender : TObject);
begin
  wave.name := edName.Text;
  frmMain.chgrid.Repaint;
end;

procedure TfrmWaveProps.edDataUnitChange(Sender : TObject);
begin
  wave.dataunit := edDataUnit.Text;
  //frmMain.chgrid.Repaint;
end;

procedure TfrmWaveProps.btnRescaleClick(Sender : TObject);
begin
  Application.CreateForm(TfrmWaveRescale, frmWaveRescale);
  frmWaveRescale.ShowModal;
end;

procedure TfrmWaveProps.tbAlphaChange(Sender : TObject);
begin
  wave.basealpha := tbAlpha.Position / 100;
  frmMain.SelectWave(wave);
end;


procedure TfrmWaveProps.UpdateWaveInfo;
var
  i : integer;
begin
  if wave = nil then EXIT; // unexpected call

  gridi.Cells[1, 0] := FloatToStrF(wave.samplt, ffFixed, 0, 6, float_number_format);
  gridi.Cells[1, 1] := IntToStr(length(wave.data));
  gridi.Cells[1, 2] := FloatToStrF(wave.EndTime - wave.StartTime, ffFixed, 0, 6, float_number_format);
  gridi.Cells[1, 3] := FloatToStrF(wave.StartTime, ffFixed, 0, 6, float_number_format);

  i := scope.waves.IndexOf(wave);
  Caption := 'Wave '+IntToStr(i + 1)+' Properties';

  edName.Text := wave.name;
  edDataUnit.Text := wave.dataunit;
  btnColor.ButtonColor := (wave.color and $00FFFFFF);
  tbAlpha.Position := round(wave.basealpha * 100);
end;

initialization
begin
  frmWaveProps := nil;
end;

end.

