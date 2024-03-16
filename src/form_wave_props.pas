unit form_wave_props;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ComCtrls, ExtCtrls, Spin, vscope_data, vscope_display;

type

  { TfrmWaveProps }

  TfrmWaveProps = class(TForm)
    Label1 : TLabel;
    edName : TEdit;
    tbAlpha : TTrackBar;
    btnColor : TColorButton;
    dlgColors : TColorDialog;
    Label2 : TLabel;
    edDataUnit : TEdit;
    btnRescale : TBitBtn;
    pnlInfo : TPanel;
    Label3 : TLabel;
    Label4 : TLabel;
    Label5 : TLabel;
    Label6 : TLabel;
    txtTotalTime : TStaticText;
    txtStartTime : TStaticText;
    txtSampleCount : TStaticText;
    txtSamplingTime : TStaticText;
    Bevel2 : TBevel;
    Bevel8 : TBevel;
    Bevel10 : TBevel;
    btnSyncWave : TBitBtn;
    cbVisible : TCheckBox;
    sedGroupId : TSpinEdit;
    Label7 : TLabel;
    Label8 : TLabel;
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormShow(Sender : TObject);
    procedure btnColorColorChanged(Sender : TObject);
    procedure edNameChange(Sender : TObject);
    procedure tbAlphaChange(Sender : TObject);
    procedure edDataUnitChange(Sender : TObject);
    procedure btnRescaleClick(Sender : TObject);
    procedure btnSyncWaveClick(Sender : TObject);
    procedure cbVisibleChange(Sender : TObject);
    procedure sedGroupIdChange(Sender : TObject);
  private

  public
    wave  : TWaveDisplay;
    scope : TScopeDisplay;

    procedure UpdateWaveInfo;

    procedure OnPropertyChanged(aredrawwave : boolean);

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

procedure TfrmWaveProps.FormShow(Sender : TObject);
begin
  UpdateWaveInfo;
end;

procedure TfrmWaveProps.btnColorColorChanged(Sender : TObject);
begin
  wave.SetColor((wave.color and $FF000000) or (cardinal(btnColor.ButtonColor) and $00FFFFFF));
  OnPropertyChanged(true);
end;

procedure TfrmWaveProps.edNameChange(Sender : TObject);
begin
  if not edName.Focused then EXIT;
  wave.name := edName.Text;
  OnPropertyChanged(false);
end;

procedure TfrmWaveProps.edDataUnitChange(Sender : TObject);
begin
  if not edDataUnit.Focused then EXIT;
  wave.dataunit := edDataUnit.Text;
  OnPropertyChanged(false);
end;

procedure TfrmWaveProps.btnRescaleClick(Sender : TObject);
begin
  Application.CreateForm(TfrmWaveRescale, frmWaveRescale);
  frmWaveRescale.ShowModal;
end;

procedure TfrmWaveProps.btnSyncWaveClick(Sender : TObject);
begin
  frmMain.miSyncWave.Click;
end;

procedure TfrmWaveProps.cbVisibleChange(Sender : TObject);
begin
  if not cbVisible.Focused then EXIT;
  wave.visible := cbVisible.Checked;
  OnPropertyChanged(true);
end;

procedure TfrmWaveProps.sedGroupIdChange(Sender : TObject);
begin
  if not sedGroupId.Focused then EXIT;
  wave.groupid := sedGroupId.Value;
  OnPropertyChanged(false);
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

  txtSamplingTime.Caption := FloatToStrF(wave.samplt, ffExponent, 6, 0, float_number_format);
  //txtSamplingTime.Caption := FloatToStrF(wave.samplt, ffFixed, 0, 6, float_number_format);
  txtSampleCount.Caption  := IntToStr(length(wave.data));
  txtTotalTime.Caption := FloatToStrF(wave.EndTime - wave.StartTime, ffFixed, 0, 6, float_number_format);
  txtStartTime.Caption := FloatToStrF(wave.StartTime, ffFixed, 0, 6, float_number_format);

  i := scope.waves.IndexOf(wave);
  Caption := 'Wave '+IntToStr(i + 1)+' Properties';

  edName.Text := wave.name;
  edDataUnit.Text := wave.dataunit;
  btnColor.ButtonColor := (wave.color and $00FFFFFF);
  tbAlpha.Position := round(wave.basealpha * 100);
  sedGroupId.Value := wave.groupid;
  cbVisible.Checked := wave.visible;
end;

procedure TfrmWaveProps.OnPropertyChanged(aredrawwave : boolean);
begin
  frmMain.UpdateChGrid;
  if aredrawwave then
  begin
    scope.RenderWaves;
    scope.DoOnPaint;
  end;
end;

initialization
begin
  frmWaveProps := nil;
end;

end.

