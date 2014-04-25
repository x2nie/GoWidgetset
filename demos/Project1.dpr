program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {frmG1: TGoForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmG1, frmG1);
  Application.Run;
end.
