unit form_sync_wave;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Spin, Buttons, vscope_data, vscope_display;

type

  { TfrmSyncWave }

  TfrmSyncWave = class(TForm)
    pnlWaveColor : TPanel;
    Label1 : TLabel;
    speStartTime : TFloatSpinEdit;
    speSamplingTime : TFloatSpinEdit;
    Label2 : TLabel;
    Label3 : TLabel;
    txtOrigStart : TStaticText;
    Label4 : TLabel;
    txtOrigSmpt : TStaticText;
    rbShifting : TRadioButton;
    rbStrechToA : TRadioButton;
    btnReset : TBitBtn;
    btnClose : TBitBtn;
    rbStrechToB : TRadioButton;
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure btnCloseClick(Sender : TObject);
    procedure btnResetClick(Sender : TObject);
    procedure speStartTimeChange(Sender : TObject);
    procedure FormActivate(Sender : TObject);
  private

  public
    wave  : TWaveDisplay;
    scope : TScopeDisplay;

    orig_startt : double;
    orig_samplt  : double;

    procedure SetupWave;

    procedure UpdateWaveInfo;

  end;

var
  frmSyncWave : TfrmSyncWave;

implementation

uses
  form_main;

{$R *.lfm}

{ TfrmSyncWave }

procedure TfrmSyncWave.FormClose(Sender : TObject; var CloseAction : TCloseAction);
begin
  CloseAction := caFree;
  frmSyncWave := nil;
end;

procedure TfrmSyncWave.btnCloseClick(Sender : TObject);
begin
  Close;
end;

procedure TfrmSyncWave.btnResetClick(Sender : TObject);
begin
  wave.startt := orig_startt;
  wave.samplt := orig_samplt;
  UpdateWaveInfo;
  scope.RenderWaves;
  scope.Repaint;
end;

procedure TfrmSyncWave.speStartTimeChange(Sender : TObject);
begin
  if speStartTime.Focused then
  begin
    wave.startt := speStartTime.Value;
    scope.RenderWaves;
    scope.Repaint;
  end;

  if speSamplingTime.Focused then
  begin
    wave.samplt := speSamplingTime.Value;
    scope.RenderWaves;
    scope.Repaint;
  end;
end;

procedure TfrmSyncWave.FormActivate(Sender : TObject);
begin
  if scope = nil then EXIT;

  speStartTime.Increment := scope.ViewRange / 100;
end;

procedure TfrmSyncWave.SetupWave;
begin
  pnlWaveColor.Color := (wave.color and $00FFFFFF);
  pnlWaveColor.Caption := wave.name;

  orig_startt := wave.startt;
  orig_samplt := wave.samplt;

  txtOrigStart.Caption := FloatToStr(orig_startt, float_number_format);
  txtOrigSmpt.Caption  := FloatToStr(orig_samplt, float_number_format);

  UpdateWaveInfo;
end;

procedure TfrmSyncWave.UpdateWaveInfo;
begin
  if wave = nil then EXIT;

  speStartTime.Value := wave.startt;
  speSamplingTime.Value := wave.samplt;

  speStartTime.Increment := scope.ViewRange / 100;
end;

initialization
begin
  frmSyncWave := nil;
end;

end.

