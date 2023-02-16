unit form_wave_rescale;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Dialogs, Controls, Graphics, StdCtrls, ColorBox,
  Grids, Buttons, ExtCtrls, vscope_data, vscope_display;

type

  { TfrmWaveRescale }

  TfrmWaveRescale = class(TForm)
    Label1 : TLabel;
    edMul : TEdit;
    Label2 : TLabel;
    edDiv : TEdit;
    btnOk : TBitBtn;
    btnCancel : TBitBtn;
    Label3 : TLabel;
    pnlWaveNum : TPanel;
    txtName : TStaticText;
    procedure FormCreate(Sender : TObject);
    procedure btnOkClick(Sender : TObject);
  private

  public
    wave : TWaveDisplay;
    scope : TScopeDisplay;
  end;

var
  frmWaveRescale : TfrmWaveRescale;

implementation

uses
  form_main;

{$R *.lfm}

{ TfrmWaveRescale }

procedure TfrmWaveRescale.FormCreate(Sender : TObject);
begin
  scope := frmMain.scope;
  wave := frmMain.SelectedWave;

  txtName.Caption := wave.name;
  pnlWaveNum.Caption := IntToStr(scope.WaveIndex(wave) + 1);
  pnlWaveNum.Color := (wave.color and $00FFFFFF);
end;

procedure TfrmWaveRescale.btnOkClick(Sender : TObject);
var
  wmul, wdiv : double;
  scaler : double;
  di : integer;
begin
  try
    wmul := StrToFloat(edMul.Text);
  except
    on Exception do
    begin
      MessageDlg('Error','Invalid multiply number', mtError, [mbAbort], 0);
      edMul.SetFocus;
      ModalResult := 0;
      exit;
    end;
  end;
  try
    wdiv := StrToFloat(edDiv.Text);
  except
    on Exception do
    begin
      MessageDlg('Error','Invalid division number', mtError, [mbAbort], 0);
      edDiv.SetFocus;
      ModalResult := 0;
      exit;
    end;
  end;

  if wdiv = 0 then
  begin
    MessageDlg('Error','The divisor cannot be 0!', mtError, [mbAbort], 0);
    edDiv.SetFocus;
    ModalResult := 0;
    exit;
  end;

  // do some work

  scaler := wmul / wdiv;
  for di := 0 to length(wave.data) - 1 do
  begin
    wave.data[di] := wave.data[di] * scaler;
  end;

  wave.InvalidateLoresData;
  wave.ReDrawWave;
  scope.DoOnPaint;
end;

end.

