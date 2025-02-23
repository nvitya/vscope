unit form_load_view;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons, jsontools;

type

  { TfrmLoadView }

  TfrmLoadView = class(TForm)
    Label1 : TLabel;
    list : TListBox;
    btnLoadNew : TButton;
    btnOpenSelected : TButton;
    btnCancel : TBitBtn;
    dlgLoadView : TOpenDialog;
    btnRemove : TButton;
    procedure btnLoadNewClick(Sender : TObject);
    procedure FormShow(Sender : TObject);
    procedure listDblClick(Sender : TObject);
    procedure btnOpenSelectedClick(Sender : TObject);
    procedure btnRemoveClick(Sender : TObject);
  private

  public

    settings_file_name : string;

    procedure AddToRecents(afilename : string);
    procedure SaveRecents;
    procedure LoadRecents;

  end;

var
  frmLoadView : TfrmLoadView;

implementation

uses
  form_main;

{$R *.lfm}

{ TfrmLoadView }

procedure TfrmLoadView.btnLoadNewClick(Sender : TObject);
begin
  if not dlgLoadView.Execute then EXIT;

  AddToRecents(dlgLoadView.FileName);
  frmMain.LoadViewSettings(dlgLoadView.FileName);
  ModalResult := mrOK;
end;

procedure TfrmLoadView.FormShow(Sender : TObject);
begin
  settings_file_name := IncludeTrailingBackslash(frmMain.exe_dir) + 'view_load_recent.json';
  LoadRecents;
end;

procedure TfrmLoadView.listDblClick(Sender : TObject);
begin
  btnOpenSelected.Click;
end;

procedure TfrmLoadView.btnOpenSelectedClick(Sender : TObject);
var
  i : integer;
begin
  if list.Items.Count < 1 then EXIT;

  i := list.ItemIndex;
  frmMain.LoadViewSettings(list.Items[i]);

  if i > 0 then
  begin
    list.Items.Move(i, 0);
    SaveRecents;
  end;

  ModalResult := mrOK;
end;

procedure TfrmLoadView.btnRemoveClick(Sender : TObject);
begin
  if list.Items.Count < 1 then EXIT;
  list.Items.Delete(list.ItemIndex);
  SaveRecents;
end;

procedure TfrmLoadView.AddToRecents(afilename : string);
var
  i : integer;
begin
  i := list.Items.IndexOf(afilename);
  if i >= 0 then
  begin
    if i > 0 then
    begin
      list.Items.Move(i, 0);
      SaveRecents;
    end;
    exit;
  end;

  list.Items.Insert(0, afilename);
  SaveRecents;
end;

procedure TfrmLoadView.SaveRecents;
var
  jf, jn : TJsonNode;
  i : integer;
  s : string;
begin
  jf := TJsonNode.Create();

  jn := jf.Add('FILES', nkArray);
  for i := 0 to list.Items.Count - 1 do
  begin
    jn.Add('', nkString).AsString := list.Items[i];
  end;
  jf.SaveToFile(settings_file_name);
  jf.Free;
end;

procedure TfrmLoadView.LoadRecents;
var
  jf, jn, jv : TJsonNode;
  i : integer;
begin
  list.Items.Clear;
  jf := TJsonNode.Create();
  try
    jf.LoadFromFile(settings_file_name);
    if jf.Find('FILES', jn) then
    begin
      for i := 0 to jn.Count - 1 do
      begin
        jv := jn.Child(i);
        list.AddItem(jv.AsString, nil);
      end;
    end;
  except
    ;
  end;
  jf.Free;
end;

end.

