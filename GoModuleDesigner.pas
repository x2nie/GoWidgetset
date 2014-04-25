unit GoModuleDesigner;

interface

uses Windows, SysUtils, Messages, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, DesignIntf, DesignEditors,
  DesignWindows, Menus, ComCtrls, ToolWin, Buttons, ActnList,GoWidgetset;


type
  TGoModuleDesignerForm = class(TDesignWindow)
    ComponentContainer: TScrollBox;
  private
    FDesigner: IDesigner;
    FLayoutComplete: Boolean;
    procedure DropDesigningInComponentState;
    function GetModule: TGoForm;
    procedure ReadLayout;
    procedure SaveLayout;
    procedure SetDesigner(const Value: IDesigner);
    { Private declarations }
  protected
    procedure Activated; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure KeyPress(var Key: Char); override;
    procedure Resize; override;
    procedure WMMove(var Message: TWMMove); message WM_MOVE;
  public
    constructor CreateEx(AOwner: TComponent; const ADesigner: IDesigner; out
        AComponentContainer: TWinControl);
    destructor Destroy; override;
    procedure ItemDeleted(const ADesigner: IDesigner; AItem: TPersistent); override;
    procedure DesignerClosed(const ADesigner: IDesigner; AGoingDormant: Boolean);
        override;
    procedure DesignerOpened(const ADesigner: IDesigner; AResurrecting: Boolean);
        override;
    procedure ItemsModified(const ADesigner: IDesigner); override;
    function EditAction(Action: TEditAction): Boolean; override;
    function GetEditState: TEditState; override;
    {IcxWebModuleDesignerNotify}
    procedure SelectionChanged(const ADesigner: IDesigner; const ASelection:
        IDesignerSelections); override;
    property Designer: IDesigner read FDesigner write SetDesigner;
    property Module: TGoForm read GetModule;
    { Public declarations }
  end;

  THackComponent=class(TComponent)
  end;

var
  goObjectTreeEditorForm: TGoModuleDesignerForm;

implementation
uses Dialogs, TypInfo;


{$R *.dfm}

{ TcxWebModuleDesignWindow }

constructor TGoModuleDesignerForm.CreateEx(AOwner: TComponent; const
    ADesigner: IDesigner; out AComponentContainer: TWinControl);
begin
  Designer := ADesigner;
  InsertComponent(Module);
  Create(AOwner);
  SetDesigning(True);
  KeyPreview := True;
  THackComponent(ComponentContainer).SetDesigning(True);
  AComponentContainer := ComponentContainer;
end;

destructor TGoModuleDesignerForm.Destroy;
begin
  inherited;
end;

procedure TGoModuleDesignerForm.ItemDeleted(const ADesigner: IDesigner;
    AItem: TPersistent);
begin
end;

procedure TGoModuleDesignerForm.Activated;
begin
//  Designer.Activate;
//  Windows.SetFocus(DesignerPanel.Handle);
  //TODO -> set Current OT component to ModuleManager
end;

procedure TGoModuleDesignerForm.CreateParams(var Params: TCreateParams);
begin
  inherited;
  //commenting this line makes things even worse
  Params.WndParent := Application.MainForm.Handle;
end;

procedure TGoModuleDesignerForm.DesignerClosed(const ADesigner: IDesigner;
    AGoingDormant: Boolean);
begin
  if ADesigner=Designer then begin
    Destroying;
    Release;
  end;
//  Close;
end;

{ IDesignNotification }

procedure TGoModuleDesignerForm.DesignerOpened(const ADesigner: IDesigner;
    AResurrecting: Boolean);
begin
  if ADesigner=Designer then begin
    Visible:=True;
    if Module<>nil then begin
      Caption := Module.Name;
      ReadLayout;
      DropDesigningInComponentState;
  //    CurrentComponent:=RC;
    end;
  end;
end;

procedure TGoModuleDesignerForm.DropDesigningInComponentState;
var
  I: Integer;
  Component: TComponent;
begin
  for I := 0 to ComponentCount - 1 do
  begin
    Component := Components[I];
    if (Component <> Designer.GetRoot) and (Component <> ComponentContainer) then
      THackComponent(Component).SetDesigning(False);
  end;
end;

procedure TGoModuleDesignerForm.ItemsModified(const ADesigner: IDesigner);
begin
end;

function TGoModuleDesignerForm.EditAction(Action: TEditAction): Boolean;
begin
  Result := False;
end;

function TGoModuleDesignerForm.GetEditState: TEditState;
begin
  Result := [];
end;

function TGoModuleDesignerForm.GetModule: TGoForm;
begin
  if Designer=nil then Result:=nil
  else if Designer.Root is TGoForm then
    Result:=TGoForm(Designer.Root)
  else Result:=nil;
end;

procedure TGoModuleDesignerForm.KeyPress(var Key: char);
begin
  inherited KeyPress(Key);
end;

procedure TGoModuleDesignerForm.ReadLayout;
const
  VisibleModuleSize = 10;
var
  DesignOffset,DesignSize,SplitSize: TPoint;
begin
  if Module<>nil then begin
    {DesignOffset:=Module.DesignOffset;
    DesignSize:=Module.DesignSize;
    SplitSize:=Module.SplitSize;
    if (DesignOffset.X + DesignSize.X < VisibleModuleSize) then
       DesignOffset.X := VisibleModuleSize - DesignSize.X;
    if (DesignOffset.Y + DesignSize.Y < VisibleModuleSize) then
       DesignOffset.Y := VisibleModuleSize - DesignSize.Y;
    if (Screen.Width - DesignOffset.X < VisibleModuleSize) then
       DesignOffset.X := Screen.Width - VisibleModuleSize;
    if (Screen.Height - DesignOffset.Y < VisibleModuleSize) then
       DesignOffset.Y := Screen.Height - VisibleModuleSize;
    SetBounds(DesignOffset.X,DesignOffset.Y,DesignSize.X,DesignSize.Y);}
    with Module do
    self.SetBounds(Left, Top, Width, Height);
    Application.ProcessMessages;
    FLayoutComplete:=True;
  end;
end;

procedure TGoModuleDesignerForm.Resize;
begin
  inherited;
  SaveLayout;
end;

procedure TGoModuleDesignerForm.SaveLayout;
begin
  if FLayoutComplete and (Module<>nil) then
    {with Module do begin
      DesignOffset:=Point(Left, Top);
      DesignSize:=Point(Width,Height);
    end;}
  begin
    Module.Left := self.Left;
    module.Top := self.Top;
    module.Width := self.Width;
    module.Height := self.Height;
  end;
end;

procedure TGoModuleDesignerForm.SelectionChanged(const ADesigner: IDesigner;
    const ASelection: IDesignerSelections);
begin
end;

procedure TGoModuleDesignerForm.SetDesigner(const Value: IDesigner);
begin
  if FDesigner <> Value then
  begin
    FDesigner := Value;
//    if (FDesigner <> nil) and (FComponentDesigner = nil) then
//    begin
//      FComponentDesigner := Designers.DesignerFromExtension(Designer.DesignerExtention);
//      SetBounds(200, ComponentDesigner. Environment.GetMainWindowSize.Bottom + 2, Width, Height);
//    end;
  end;
end;

procedure TGoModuleDesignerForm.WMMove(var Message: TWMMove);
begin
  inherited;
  SaveLayout;
end;


function GetControlByHandle(AHandle: THandle): TWinControl;
begin 
  Result := Pointer(GetProp( AHandle, 
                             PChar( Format( 'Delphi%8.8x', 
                                            [GetCurrentProcessID])))); 
end;







end.

