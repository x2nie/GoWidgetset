unit GoWidgetset_Reg;

interface

uses
  SysUtils, Classes;


procedure Register;

implementation

uses GoWidgetset;

procedure Register;
begin
  RegisterComponents('Standard', [TGoGroupBox, TGoButton]);
end;

end.
