unit GoDesignerHooks;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ActiveX, ComObj, StdCtrls;

type
  TGoDesignerHook = class(TInterfacedObject, IDesignerNotify, IDesignerHook)
  private
    FRoot: TComponent;
    //FStretchHandle : TStretchHandle;
    FControl: TControl;
    FDragging: boolean;
    FControlPos,FDownPos : TPoint;
    //function StretchHandle : TStretchHandle;
  protected
    function IsMouseMsg(Sender: TControl; var Message: TWMMouse): Boolean;
  public
    { IDesignerNotify }
    procedure Modified;
    procedure Notification(AnObject: TPersistent; Operation: TOperation);
  public
    { IDesignerHook }
    function GetCustomForm: TCustomForm;
    procedure SetCustomForm(Value: TCustomForm);
    function GetIsControl: Boolean;
    procedure SetIsControl(Value: Boolean);
    function IsDesignMsg(Sender: TControl; var Message: TMessage): Boolean;
    procedure PaintGrid;
    procedure ValidateRename(AComponent: TComponent;
      const CurName, NewName: string);
    function UniqueName(const BaseName: string): string;
    function GetRoot: TComponent;
    property IsControl: Boolean read GetIsControl write SetIsControl;
    property Form: TCustomForm read GetCustomForm write SetCustomForm;
  end;

  
implementation

uses //Unit2,
  GoWidgetSet;

{ TDesignerHook }
 
function TGoDesignerHook.GetCustomForm: TCustomForm;
begin
  if FRoot is TCustomForm then
    Result := TCustomForm(FRoot)
  else
    Result := nil;
end;
 
type
  TControlCrack = class(TControl);
 
function TGoDesignerHook.GetIsControl: Boolean;
begin
  if FRoot is TControl then
    Result := TControlCrack(FRoot).IsControl
  else
    result := False;
end;
 
function TGoDesignerHook.GetRoot: TComponent;
begin
  Result := FRoot;
end;
 
function TGoDesignerHook.IsDesignMsg(Sender: TControl;
  var Message: TMessage): Boolean;
begin
  //Result := (Message.Msg = WM_LBUTTONDOWN) or (Message.Msg = WM_LBUTTONDBLCLK);
  Result := false;
  //if (Message.Msg in [WM_LBUTTONDOWN, WM_MOUSEMOVE])  then
  if (Sender <> self.FRoot) then
  begin
    result := self.IsMouseMsg(Sender,  TWMMouse(Message));
  end;
  
  result := result or (Message.Msg = WM_LBUTTONDBLCLK);// or (Sender = self.FRoot);

  if Result then
  begin
    //form2.Caption := Sender.Name;
  end;
end;
 
function TGoDesignerHook.IsMouseMsg(Sender: TControl; var Message: TWMMouse): Boolean;
var
  P: TPoint;
  X, Y : integer;
begin
  {if GetCapture = Handle then
  begin
    if (CaptureControl <> nil) and (CaptureControl.Parent = Self) then
      Control := CaptureControl
    else
      Control := nil;
  end
  else
    Control := Form.ControlAtPos(SmallPointToPoint(Message.Pos), False);}
  Result := False;
  if Sender = self.FRoot then exit;

  //if Sender = FStretchHandle then exit;
//  if Message.Msg in [WM_LBUTTONDOWN, WM_MOUSEMOVE] then
  if Message.Msg = WM_LBUTTONDOWN then
  begin
    Result := true;
    FControl := Sender;
    FDownPos := FControl.ClientToScreen( SmallPointToPoint(Message.Pos));
    FControlPos := Point(Sender.Left, Sender.Top);
    FDragging := True;
    setcapture(TWinControl(FControl).Handle);
    //StretchHandle.Attach(FControl);
  end
  else
  if Message.Msg = WM_MOUSEMOVE then
  begin
    if FDragging = True then
    begin
      Result := true;
      P := FControl.ClientToScreen( SmallPointToPoint(Message.Pos) );
      
      X := FControlPos.X + (P.X - FDownPos.X);
      Y := FControlPos.Y + (P.Y - FDownPos.Y);
      FControl.SetBounds(X,Y, FControl.Width, FControl.Height);
    end;
  end
  else
  if Message.Msg = WM_LBUTTONUP then
  begin
    Result := true;
    SetCapture(0);
    FDragging := False;
  end;


{  if Control <> nil then
  begin
    P.X := Message.XPos - Control.Left;
    P.Y := Message.YPos - Control.Top;
    Message.Result := Control.Perform(Message.Msg, Message.Keys, Longint(PointToSmallPoint(P)));
    Result := True;
  end;}

end;

procedure TGoDesignerHook.Modified;
begin
  //
end;
 
procedure TGoDesignerHook.Notification(AnObject: TPersistent;
  Operation: TOperation);
begin
  if (Operation = opRemove) and (AnObject = FRoot) then
    FRoot := nil;
end;
 
procedure TGoDesignerHook.PaintGrid;
  var x, y,i : integer;
  c : TComponent;
  const
    gx = 8; //TODO: Link to: EnvironmentOptions.GridSizeX
    gy = 8;
begin
    for y := 0 to (Form.Height -1) div gy do
      for x := 0 to (Form.Width -1) div gx do
      begin
        Form.Canvas.Pixels[x *gx, y *gy] := clBlack;
      end;
  for i := 0 to self.FRoot.ComponentCount -1  do
  begin
    c := self.FRoot.Components[i];
    //if not (c is TControl) then
    if c is TGoWidget then
    begin
      form.Canvas.Pen.Color := clRed;
      with TGoWidget(c) do
      form.Canvas.Rectangle(left, top, left+ width, top + height);
    end;
    

  end;

end;
 
procedure TGoDesignerHook.SetCustomForm(Value: TCustomForm);
begin
  FRoot := Value;
end;
 
procedure TGoDesignerHook.SetIsControl(Value: Boolean);
begin
  if FRoot is TControl then
    TControlCrack(FRoot).IsControl := Value;
end;
 
{function TDesignerHook.StretchHandle: TStretchHandle;
begin
  if not assigned(FStretchHandle) then
    FStretchHandle := TStretchHandle.Create(self.FRoot);
  result := FStretchHandle;
end;}

function TGoDesignerHook.UniqueName(const BaseName: string): string;
var
  guid: TGuid;
  s: string;
begin
  OleCheck(CoCreateGuid(guid));
  s := GuidToString(guid);
  s := Copy(s, 2, Length(s) - 2); // ??????? ??????{}
  s := StringReplace(s, '-', '', []);
  Result := BaseName + s;
end;
 
procedure TGoDesignerHook.ValidateRename(AComponent: TComponent;
  const CurName, NewName: string);
begin
 
end;
end.
 