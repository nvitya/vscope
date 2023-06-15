program vscope;

{$mode objfpc}{$H+}

{$ifdef TRACES}
  {$APPTYPE CONSOLE}
{$endif}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazopenglcontext, form_main, form_wave_props, form_wave_rescale, 
  version_vscope, form_about, form_measure_ab, form_sync_wave, form_wave_loop
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

