unit form_measure_ab;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Grids, vscope_data, vscope_display;

type

  { TfrmMeasureAB }

  TfrmMeasureAB = class(TForm)
    pnlWaveColor : TPanel;
    igrid : TStringGrid;
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
  private

  public
    wave  : TWaveDisplay;
    scope : TScopeDisplay;

    procedure UpdateWaveInfo;

  end;

var
  frmMeasureAB : TfrmMeasureAB;

implementation

{$R *.lfm}

{ TfrmMeasureAB }

procedure TfrmMeasureAB.FormClose(Sender : TObject; var CloseAction : TCloseAction);
begin
  CloseAction := caFree;
  frmMeasureAB := nil;
end;

procedure TfrmMeasureAB.UpdateWaveInfo;
var
  ia, ib, i : integer;
  scnt : integer;
  minval : double;
  maxval : double;
  avgval : double;
  sumval : double;
  tdiff : double;
  sqrsum, effval : double;
  v : double;
begin
  igrid.RowCount := 12;

  igrid.Cells[0, 0] := 'A Marker Time';
  igrid.Cells[0, 1] := 'B Marker Time';
  igrid.Cells[0, 2] := 'A...B Time';
  igrid.Cells[0, 3] := 'A...B Frequency';
  igrid.Cells[0, 4] := 'Sample Count';
  igrid.Cells[0, 5] := 'A Value';
  igrid.Cells[0, 6] := 'B Value';
  igrid.Cells[0, 7] := 'Minimum Value';
  igrid.Cells[0, 8] := 'Maximum value';
  igrid.Cells[0, 9] := 'Max-Min Diff.';
  igrid.Cells[0,10] := 'Average value';
  igrid.Cells[0,11] := 'Effective val.';

  if wave = nil then EXIT;

  pnlWaveColor.Color := (wave.color and $00FFFFFF);
  pnlWaveColor.Caption := wave.name;

  if scope.marker[0].Visible then
  begin
    igrid.Cells[1, 0] := scope.FormatTime(scope.marker[0].mtime);

    ia := trunc((scope.marker[0].mtime - wave.startt) / wave.samplt);
    if ia >= length(wave.data) then ia := length(wave.data) - 1;
    if ia < 0 then ia := 0;
  end
  else
  begin
    igrid.Cells[1, 0] := '-';
    ia := 0;
  end;

  if scope.marker[1].Visible then
  begin
    igrid.Cells[1, 1] := scope.FormatTime(scope.marker[1].mtime);
    ib := trunc((scope.marker[1].mtime - wave.startt) / wave.samplt);
    if ib >= length(wave.data) then ib := length(wave.data) - 1;
    if ib < 0 then ib := 0;
  end
  else
  begin
    igrid.Cells[1, 1] := '-';
    ib := 0;
  end;

  if scope.marker[0].Visible and scope.marker[1].Visible then
  begin
    tdiff := scope.marker[1].mtime - scope.marker[0].mtime;
    igrid.Cells[1, 2] := scope.FormatTime(tdiff);
    if tdiff <> 0 then igrid.Cells[1, 3] := FloatToStrF(1 / tdiff, ffFixed, 0, 3, float_number_format) + ' Hz'
                  else igrid.Cells[1, 3] := ''
  end
  else
  begin
    igrid.Cells[1, 2] := '-';
    igrid.Cells[1, 3] := '-';
  end;

  if ia < length(wave.data)
  then
      igrid.Cells[1, 5] := wave.GetValueStr(scope.marker[0].mtime)
  else
      igrid.Cells[1, 5] := '-';


  if ib < length(wave.data)
  then
      igrid.Cells[1, 6] := wave.GetValueStr(scope.marker[1].mtime)
  else
      igrid.Cells[1, 6] := '-';


  if (ia < length(wave.data)) and (ib < length(wave.data)) then
  begin
    if ib < ia then
    begin
      i := ia;
      ia := ib;
      ib := i;
    end;

    scnt := 0;
    minval := 0;
    maxval := 0;
    sumval := 0;
    sqrsum := 0;
    while ia <= ib do
    begin
      v := wave.data[ia];
      if scnt = 0 then
      begin
        minval := v;
        maxval := v;
      end
      else
      begin
        if v < minval then minval := v;
        if v > maxval then maxval := v;
      end;
      sumval += v;
      sqrsum += v * v;
      inc(scnt);
      inc(ia);
    end;
    if scnt > 0 then
    begin
      avgval := sumval / scnt;
      effval := sqrt(sqrsum / scnt);
    end
    else
    begin
      avgval := 0;
      effval := 0;
    end;
    igrid.Cells[1, 4] := IntToStr(scnt);
    igrid.Cells[1, 7] := wave.FormatValue(minval);
    igrid.Cells[1, 8] := wave.FormatValue(maxval);
    igrid.Cells[1, 9] := wave.FormatValue(maxval-minval);
    igrid.Cells[1,10] := wave.FormatValue(avgval);
    igrid.Cells[1,11] := wave.FormatValue(effval);
  end
  else
  begin
    igrid.Cells[1, 4] := '-'; //IntToStr(abs(ib - ia));
    igrid.Cells[1, 7] := '-';
    igrid.Cells[1, 8] := '-';
    igrid.Cells[1, 9] := '-';
    igrid.Cells[1,10] := '-';
    igrid.Cells[1,11] := '-';
  end;

end;


initialization
begin
  frmMeasureAB := nil;
end;

end.

