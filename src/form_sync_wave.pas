unit form_sync_wave;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Spin, Buttons, vscope_data, vscope_display;

type

  TOrigWaveData = record
    wd     : TWaveDisplay;
    samplt : double;
    startt : double;
  end;

  { TfrmSyncWave }

  TfrmSyncWave = class(TForm)
    pnlWaveColor : TPanel;
    Label1 : TLabel;
    edSamplingTime: TEdit;
    speStartTime : TFloatSpinEdit;
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
    Label5 : TLabel;
    cbGroup : TCheckBox;
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure btnCloseClick(Sender : TObject);
    procedure btnResetClick(Sender : TObject);
    procedure speStartTimeChange(Sender : TObject);
    procedure FormActivate(Sender : TObject);
    procedure cbGroupChange(Sender : TObject);
  private

  public
    wave  : TWaveDisplay;
    scope : TScopeDisplay;
    groupid : integer;

    origdata : array of TOrigWaveData;
    odw_samplt : double;
    odw_startt : double;

    procedure SetupWave;

    procedure UpdateWaveInfo;
    procedure ApplyToGroup;

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

  frmMain.UpdateAfterSync;
end;

procedure TfrmSyncWave.btnCloseClick(Sender : TObject);
begin
  Close;
end;

procedure TfrmSyncWave.btnResetClick(Sender : TObject);
var
  wd    : TWaveDisplay;
  odidx : integer;
begin
  for odidx := 0 to length(origdata) - 1 do
  begin
    wd := origdata[odidx].wd;
    wd.startt := origdata[odidx].startt;
    wd.samplt := origdata[odidx].samplt;
  end;
  UpdateWaveInfo;
  scope.RenderWaves;
  scope.Repaint;
end;

procedure TfrmSyncWave.speStartTimeChange(Sender : TObject);
var
  fv : double;
begin
  if speStartTime.Focused then
  begin
    wave.startt := speStartTime.Value;
    scope.RenderWaves;
    scope.Repaint;
  end;

  if edSamplingTime.Focused then
  begin
    try
      wave.samplt := StrToFloat(edSamplingTime.Text);
      scope.RenderWaves;
      scope.Repaint;
    except
      ;
    end;
  end;
end;

procedure TfrmSyncWave.FormActivate(Sender : TObject);
begin
  if scope = nil then EXIT;

  speStartTime.Increment := scope.ViewRange / 100;
end;

procedure TfrmSyncWave.cbGroupChange(Sender : TObject);
begin
  ApplyToGroup;
  scope.Refresh;
end;

procedure TfrmSyncWave.SetupWave;
var
  wd    : TWaveDisplay;
  odcnt : integer;
begin
  pnlWaveColor.Color := (wave.color and $00FFFFFF);
  pnlWaveColor.Caption := wave.name;
  groupid := wave.groupid;
  cbGroup.Caption := '+ Group '+IntToStr(groupid);

  // save origdata for all waves in this group;
  odcnt := 0;
  SetLength(origdata, 0);
  for wd in scope.waves do
  begin
    if wd.groupid = groupid then
    begin
      SetLength(origdata, odcnt + 1);
      origdata[odcnt].wd     := wd;
      origdata[odcnt].samplt := wd.samplt;
      origdata[odcnt].startt := wd.startt;
      Inc(odcnt);
    end;
  end;

  // for the simplicity of transform calculations save the selected wave original data here too:
  odw_samplt := wave.samplt;
  odw_startt := wave.startt;

  txtOrigStart.Caption := FloatToStr(odw_startt, float_number_format);
  txtOrigSmpt.Caption  := FloatToStr(odw_samplt, float_number_format);

  UpdateWaveInfo;
end;

procedure TfrmSyncWave.UpdateWaveInfo;  // called when the wave was moved
begin
  if wave = nil then EXIT;

  speStartTime.Value := wave.startt;
  edSamplingTime.Text := FloatToStrF(wave.samplt, ffExponent, 9, 0, float_number_format);

  speStartTime.Increment := scope.ViewRange / 100;

  ApplyToGroup;
end;

procedure TfrmSyncWave.ApplyToGroup;
var
  new_waveshift   : double;
  new_wavestretch : double;
  gwi : integer;
  wd : TWaveDisplay;
begin

  if cbGroup.Checked then
  begin
    new_waveshift   := wave.startt - odw_startt;
    new_wavestretch := wave.samplt / odw_samplt;
  end
  else
  begin
    new_waveshift   := 0;
    new_wavestretch := 1;
  end;

  for gwi := 0 to length(origdata) - 1 do
  begin
    wd := origdata[gwi].wd;
    if wd <> wave then
    begin
      wd.startt := origdata[gwi].startt + new_waveshift;
      wd.samplt := origdata[gwi].samplt * new_wavestretch;
      wd.ReDrawWave;
    end;
  end;
end;

initialization
begin
  frmSyncWave := nil;
end;

end.

