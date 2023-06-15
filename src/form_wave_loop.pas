unit form_wave_loop;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Spin,
  StdCtrls, Buttons, vscope_data, vscope_display;

type

  { TfrmWaveLoop }

  TfrmWaveLoop = class(TForm)
    btnOk : TBitBtn;
    btnCancel : TBitBtn;
    Label1 : TLabel;
    Label2 : TLabel;
    pnlWaveColor : TPanel;
    sedLoopsBeforeA : TSpinEdit;
    sedLoopsAfterB : TSpinEdit;
    procedure btnOkClick(Sender : TObject);
    procedure btnCancelClick(Sender : TObject);
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormShow(Sender : TObject);
    procedure sedLoopsAfterBChange(Sender : TObject);
  private

  public
    wave  : TWaveDisplay;
    scope : TScopeDisplay;

    origw : TWaveData;

    markert : array[0..1] of double;

    procedure SetupWave;
    procedure UpdateWaveInfo;
    procedure MarkersChanged;

    procedure RestoreOrigWave;
    procedure LoopWave;

  end;

var
  frmWaveLoop : TfrmWaveLoop;

implementation

{$R *.lfm}

{ TfrmWaveLoop }

procedure TfrmWaveLoop.FormClose(Sender : TObject; var CloseAction : TCloseAction);
begin
  origw.Free;
  frmWaveLoop := nil;
  CloseAction := caFree;
end;

procedure TfrmWaveLoop.btnOkClick(Sender : TObject);
begin
  Close;
end;

procedure TfrmWaveLoop.btnCancelClick(Sender : TObject);
begin
  RestoreOrigWave;
  wave.InvalidateLoresData;
  wave.ReDrawWave;
  scope.Repaint;
  Close;
end;

procedure TfrmWaveLoop.FormShow(Sender : TObject);
begin
  UpdateWaveInfo;
end;

procedure TfrmWaveLoop.sedLoopsAfterBChange(Sender : TObject);
begin
  LoopWave;
  scope.RePaint;
end;

procedure TfrmWaveLoop.SetupWave;
begin
  pnlWaveColor.Color := (wave.color and $00FFFFFF);
  pnlWaveColor.Caption := wave.name;

  origw := TWaveData.create(wave.name, wave.samplt);
  origw.data := copy(wave.data, 0, length(wave.data));
  origw.startt := wave.startt;
  origw.samplt := wave.samplt;

  markert[0] := -1;
  markert[1] := -1;

  UpdateWaveInfo;
end;

procedure TfrmWaveLoop.UpdateWaveInfo;
begin
  if wave = nil then EXIT;
end;

procedure TfrmWaveLoop.MarkersChanged;
begin
  if scope.marker[0].Visible and scope.marker[1].Visible then
  begin
    if (markert[0] <> scope.marker[0].mtime) or (markert[1] <> scope.marker[1].mtime) then
    begin
      markert[0] := scope.marker[0].mtime;
      markert[1] := scope.marker[1].mtime;
      LoopWave;
    end;
  end;
end;

procedure TfrmWaveLoop.RestoreOrigWave;
begin
  wave.startt := origw.startt;
  wave.data := copy(origw.data, 0, length(origw.data));
end;

procedure TfrmWaveLoop.LoopWave;
var
  di, ldi, ldis, ldie, looplen : integer;
  //dis, die : integer;
  odlen : integer;
  loopcnt, loopidx : integer;
  v : double;
begin
  odlen := length(origw.data);

  // calculate the new wave data
  ldis := origw.GetDataIndex(markert[0]);
  ldie := origw.GetDataIndex(markert[1]);
  if ldis > ldie then
  begin
    ldi := ldie;
    ldie := ldis;
    ldis := ldi;
  end;
  looplen := ldie - ldis;

  if ((ldis < 0) and (ldie < 0))
  or ((ldis >= odlen) and (ldie >= odlen))
  or (sedLoopsAfterB.Value = 0) then
  begin
    RestoreOrigWave;
  end
  else
  begin
    // ok, there is something to do

    loopcnt := (1 + sedLoopsAfterB.Value + sedLoopsBeforeA.Value);
    SetLength(wave.data, looplen * loopcnt);
    wave.startt := origw.GetDataIndexTime(ldis) - sedLoopsBeforeA.Value * looplen * origw.samplt;

    di := 0;
    for loopidx := 1 to loopcnt do
    begin
      ldi := ldis;
      while (ldi < ldie) do
      begin
        if ldi < 0 then v := origw.data[0]
        else if ldi >= odlen then v := origw.data[odlen-1]
        else v := origw.data[ldi];
        wave.data[di] := v;
        Inc(ldi);
        Inc(di);
      end;
    end;
  end;

  wave.InvalidateLoresData;
  wave.ReDrawWave;
end;

initialization
begin
  frmWaveLoop := nil;
end;

end.

