unit form_wave_process;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, LCLType, vscope_data, vscope_display, strparseobj, wave_processing;

type

  TOrigWaveData = record
    wd     : TWaveDisplay;
    data   : array of double;
  end;

  { TfrmWaveProcess }

  TfrmWaveProcess = class(TForm)
    pnlWaveColor : TPanel;
    cbGroup : TCheckBox;
    btnApply : TBitBtn;
    btnReset : TBitBtn;
    Label1 : TLabel;
    memo : TMemo;
    pnlhelp : TPanel;
    Label2 : TLabel;
    memohelp : TMemo;
    Bevel1 : TBevel;
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure cbGroupChange(Sender : TObject);
    procedure btnApplyClick(Sender : TObject);
    procedure btnResetClick(Sender : TObject);
    procedure FormCreate(Sender : TObject);
    procedure memoKeyDown(Sender : TObject; var Key : Word; Shift : TShiftState);
  private

  public
    wave  : TWaveDisplay;
    scope : TScopeDisplay;
    groupid : integer;

    origdata : array of TOrigWaveData;

    waveproc : TWaveProcessor;

    sp : TStrParseObj;      // object, not a class, no allocation/free required

    procedure SetupWave;

    procedure UpdateWaveInfo;
    procedure ApplyToGroup;

    procedure ProcessWave(wd : TWaveDisplay);

    procedure FreeOrigData;

  end;

var
  frmWaveProcess : TfrmWaveProcess;

implementation


{$R *.lfm}

{ TfrmWaveProcess }

procedure TfrmWaveProcess.FormClose(Sender : TObject; var CloseAction : TCloseAction);
begin
  FreeOrigData;
  WaveProc.Free;
  CloseAction := caFree;
  frmWaveProcess := nil;
end;

procedure TfrmWaveProcess.cbGroupChange(Sender : TObject);
begin
  ApplyToGroup;
  scope.Refresh;
end;

procedure TfrmWaveProcess.btnApplyClick(Sender : TObject);
begin
  try
    ApplyToGroup;
  except
    on e : EWaveProcess do
    begin
      ShowMessage(e.Message);
    end;
  end;
end;

procedure TfrmWaveProcess.btnResetClick(Sender : TObject);
var
  wd    : TWaveDisplay;
  odidx : integer;
begin
  for odidx := 0 to length(origdata) - 1 do
  begin
    wd := origdata[odidx].wd;
    if length(wd.data) = length(origdata[odidx].data) then
    begin
      move(origdata[odidx].data[0], wd.data[0], length(wd.data) * sizeof(double));
    end;
  end;
  UpdateWaveInfo;
  scope.RenderWaves;
  scope.Repaint;
end;

procedure TfrmWaveProcess.FormCreate(Sender : TObject);
begin
  waveproc := TWaveProcessor.Create;
end;

procedure TfrmWaveProcess.memoKeyDown(Sender : TObject; var Key : Word; Shift : TShiftState);
begin
  if      Key = VK_F9 then btnApply.Click
  else if Key = VK_F7 then btnReset.Click
  ;
end;

procedure TfrmWaveProcess.SetupWave;
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
      SetLength(origdata[odcnt].data, 0);  // the data will be copied on the first calculation
      Inc(odcnt);
    end;
  end;

  UpdateWaveInfo;
end;

procedure TfrmWaveProcess.UpdateWaveInfo;
begin
  //
end;

procedure TfrmWaveProcess.ApplyToGroup;
var
  wd : TWaveDisplay;
  porig : ^TOrigWaveData;
  odi : integer;
begin
  for odi := 0 to length(origdata) - 1 do
  begin
    porig := @origdata[odi];
    wd := porig^.wd;
    if cbGroup.Checked or (wd = wave) then
    begin
      if 0 = length(porig^.data) then
      begin
        // save the original wave data
        SetLength(porig^.data, length(wd.data));
        move(wd.data[0], porig^.data[0], length(wd.data) * sizeof(double));
        //orig.data := copy(wd.data);
      end
      else
      begin
        // restore the original wave data
        move(porig^.data[0], wd.data[0], length(porig^.data) * sizeof(double));
      end;
      ProcessWave(wd);
      wd.ReDrawWave;
    end;
  end;
  scope.Repaint;
end;

procedure TfrmWaveProcess.ProcessWave(wd : TWaveDisplay);
begin
  waveproc.Run(wd, memo.Text);
end;

procedure TfrmWaveProcess.FreeOrigData;
var
  odi : integer;
begin
  for odi := 0 to length(origdata) - 1 do
  begin
    SetLength(origdata[odi].data, 0);
  end;
  SetLength(origdata, 0);
end;

initialization
begin
  frmWaveProcess := nil;
end;

end.

