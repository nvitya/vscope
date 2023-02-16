unit form_about;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons;

type

  { TfrmAbout }

  TfrmAbout = class(TForm)
    txtVersion : TStaticText;
    BitBtn1 : TBitBtn;
    memoInfo : TMemo;
    procedure FormCreate(Sender : TObject);
  private

  public

  end;

var
  frmAbout : TfrmAbout;

implementation

uses
  version_vscope;

{$R *.lfm}

{ TfrmAbout }

procedure TfrmAbout.FormCreate(Sender : TObject);
begin
  txtVersion.Caption := 'VScope - v'+VSCOPE_VERSION;
end;

end.

