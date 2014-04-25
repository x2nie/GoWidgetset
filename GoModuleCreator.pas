unit GoModuleCreator;

interface
uses Classes,Types,ActnList,SysUtils, Windows, Graphics,
  {$IFDEF VER130} // Delphi 5
  DsgnIntf,
  {$ELSE not VER_140} // Delphi 6+
  DesignIntf,
  {$ENDIF}  ToolsApi,VCLEditors,Controls,Forms,Dialogs,DesignEditors,
  GoModuleDesigner,ComCtrls,Menus,ExtCtrls,DesignWindows,GoWidgetset;

type

  TGoComponentNotificationEvent=procedure(AComponent:TComponent;Operation:TOperation) of object;

  TGoNotificator = class(TComponent)
  private
    FOnNotification: TGoComponentNotificationEvent;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    property OnNotification: TGoComponentNotificationEvent read FOnNotification
        write FOnNotification;
  end;

  TGoModuleCreateAction=class(TCustomAction)
  public
    function Execute: Boolean; override;
    function Update: Boolean; override;
  end;

  TGoModuleDesignModule = class(TCustomModule,ICustomDesignForm)
  public
    { ICustomDesignForm }
    procedure CreateDesignerForm(const Designer: IDesigner; Root: TComponent; out
        DesignForm: TCustomForm; out ComponentContainer: TWinControl);
    class function DesignClass: TComponentClass; override;
    function GetAttributes: TCustomModuleAttributes; override;
    function ValidateComponentClass(ComponentClass: TComponentClass): Boolean;
        override;
  end;

  TGoSourceFile = class(TInterfacedObject, IOTAFile)
  private
    FSource: string;
  public
    function GetSource: string;
    function GetAge: TDateTime;
    constructor Create(const Source: string);
  end;

  TGoModuleCreator = class(TInterfacedObject, IOTACreator, IOTAModuleCreator)
  private
    FModuleBaseClass: string;
  public
    constructor CreateEx(AModuleBaseClass:string); virtual;
    // IOTACreator
    function GetCreatorType: string;
    function GetExisting: Boolean;
    function GetFileSystem: string;
    function GetOwner: IOTAModule;
    function GetUnnamed: Boolean;
    // IOTAModuleCreator
    function GetAncestorName: string;
    function GetImplFileName: string;
    function GetIntfFileName: string;
    function GetFormName: string;
    function GetMainForm: Boolean;
    function GetShowForm: Boolean;
    function GetShowSource: Boolean;
    function NewFormFile(const FormIdent, AncestorIdent: string): IOTAFile;
    function NewImplSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    function NewIntfSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    procedure FormCreated(const FormEditor: IOTAFormEditor);
  end;

  TGoModuleCreatorWizard = class(TNotifierObject, IOTAWizard,
    IOTARepositoryWizard,IOTARepositoryWizard60,{IOTARepositoryWizard80,} IOTAFormWizard,IOTAMenuWizard)
  private
    FFreeNotificator: TGoNotificator;
    FModuleCreateAction:TGoModuleCreateAction;
    FModuleCreateButton:TToolButton;
    FMenuItem:TMenuItem;
    FTimer: TTimer;
    procedure CreateActionItems;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
    procedure Tick(sender: tobject);
  protected
  public
    constructor Create; virtual;
    destructor Destroy; override;
    // IOTAWizard
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    // IOTARepositoryWizard
    function GetAuthor: string;
    function GetComment: string;
    function GetDesigner: string;
    //function GetGalleryCategory: IOTAGalleryCategory;
    function GetPage: string;
    {$IFDEF VER130} // Delphi 5
    function GetGlyph: HICON;
    {$ELSE not VER_140} // Delphi 6+
    function GetGlyph: Cardinal;
    // IOTAMenuWizard (creates a simple menu item on the help menu)
    function GetMenuText: string;
    function GetPersonality: string;
    {$ENDIF}
  end;


function RemoveT(Source:string): string;

procedure Register;

procedure RegisterActions(WizardActions: TCustomActionList);

procedure RegisterActionWithImageIndex(WizardAction: TCustomAction; const
    ImageRef: string);

function FindDelphiAction(const AName: string): TContainedAction;



implementation


function RemoveT(Source:string): string;
begin
  Result:=Copy(Source,2,Length(Source)-1);
end;

procedure Register;
begin
  RegisterCustomModule(TGoForm,TGoModuleDesignModule);
  RegisterPackageWizard(TGoModuleCreatorWizard.Create);
end;

//----------------------------------------------------------------------------------------------------------------------

procedure RegisterActions(WizardActions: TCustomActionList);

var
  NTAServices: INTAServices;
  DelphiActions: TCustomActionList;
  NewImageIndex: Integer;
  Action: TCustomAction;
  Bitmap: TBitmap;

begin
  NTAServices := BorlandIDEServices as INTAServices;
  DelphiActions := NTAServices.ActionList;

  with WizardActions do
    if Assigned(Images) then
    begin
      while ActionCount > 0 do
      begin
        if Actions[0] is TCustomAction then
        begin
          Action := TCustomAction(Actions[0]);
          with Action do
          begin
            Bitmap := TBitmap.Create;
            try
              Bitmap.Height := Images.Height;
              Bitmap.Width := Images.Width;
              Images.GetBitmap(ImageIndex, Bitmap);
              NewImageIndex := NTAServices.AddMasked(Bitmap, clWhite, Name + 'Image');

              ActionList := DelphiActions;
              ImageIndex := NewImageIndex;
            finally
              Bitmap.Free;
            end;
          end;
        end;
      end;
    end
    else
      while ActionCount > 0 do
        Actions[0].ActionList := DelphiActions;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure RegisterActionWithImageIndex(WizardAction: TCustomAction; const
    ImageRef: string);
var Bitmap:TBitmap;
begin
  with WizardAction do begin
    ActionList := (BorlandIDEServices as INTAServices40).ActionList;
    Bitmap := TBitmap.Create;
    try
      //draw simple image for action button
      Bitmap.Height := 16;
      Bitmap.Width := 16;
      Bitmap.Canvas.Brush.Color:=clFuchsia;
      Bitmap.Canvas.FillRect(Rect(0,0,16,16));
      Bitmap.Canvas.Pen.Color:=clBlack;
      Bitmap.Canvas.Rectangle(2,2,13,13);
//      Bitmap.Transparent:=True;
      ImageIndex := (BorlandIDEServices as INTAServices).AddMasked(Bitmap,clFuchsia,'$'+ImageRef);
    finally
      Bitmap.Free;
    end;
  end;
end;

//----------------------------------------------------------------------------------------------------------------------

function FindDelphiAction(const AName: string): TContainedAction;

var
  DelphiActions: TCustomActionList;
  I: Integer;

begin
  Result := nil;
  with BorlandIDEServices as INTAServices40 do
    DelphiActions := ActionList;
  if DelphiActions = nil then
    Exit;

  with DelphiActions do
    for I := 0 to ActionCount - 1 do
      if Actions[I].Name = AName then
      begin
        Result := Actions[I];
        Break;
      end;
end;

{ TGoSourceFile }

constructor TGoSourceFile.Create(const Source: string);
begin
  FSource := Source;
end;

function TGoSourceFile.GetAge: TDateTime;
begin
  Result := -1;
end;

function TGoSourceFile.GetSource: string;
begin
  Result := FSource;
end;

constructor TGoModuleCreator.CreateEx(AModuleBaseClass:string);
begin
  FModuleBaseClass:=AModuleBaseClass;
  Create;
end;

procedure TGoModuleCreator.FormCreated(const FormEditor:
    IOTAFormEditor);
begin
  // Nothing
end;

function TGoModuleCreator.GetAncestorName: string;
begin
  Result:=RemoveT(FModuleBaseClass);
end;

function TGoModuleCreator.GetCreatorType: string;
begin
  // Return sUnit or sText as appropriate
  Result := sForm;
end;

function TGoModuleCreator.GetExisting: Boolean;
begin
  Result := False;
end;

function TGoModuleCreator.GetFileSystem: string;
begin
  Result := '';
end;

function TGoModuleCreator.GetFormName: string;
begin
  Result := '';
end;

function TGoModuleCreator.GetImplFileName: string;
begin
  Result := '';
end;

function TGoModuleCreator.GetIntfFileName: string;
begin
  Result := '';
end;

function TGoModuleCreator.GetMainForm: Boolean;
begin
  Result := False;
end;

function TGoModuleCreator.GetOwner: IOTAModule;
var
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  NewModule: IOTAModule;
begin
  // You may prefer to return the project group's ActiveProject instead
  Result := nil;
  ModuleServices := (BorlandIDEServices as IOTAModuleServices);
  Module := ModuleServices.CurrentModule;

  if Module <> nil then
  begin
    if Module.QueryInterface(IOTAProject, NewModule) = S_OK then
      Result := NewModule

    {$IFDEF VER130} // Delphi 5
    else if Module.GetOwnerCount > 0 then
    begin
      NewModule := Module.GetOwner(0);
    {$ELSE not VER_140} // Delphi 6+
    else if Module.OwnerModuleCount > 0 then
    begin
      NewModule := Module.OwnerModules[0];
    {$ENDIF}
      if NewModule <> nil then
        if NewModule.QueryInterface(IOTAProject, Result) <> S_OK then
          Result := nil;
    end;
  end;
end;





function TGoModuleCreator.GetShowForm: Boolean;
begin
  Result := True;
end;

function TGoModuleCreator.GetShowSource: Boolean;
begin
  Result := True;
end;

function TGoModuleCreator.GetUnnamed: Boolean;
begin
  Result := True;
end;

function TGoModuleCreator.NewFormFile(const FormIdent, AncestorIdent:
    string): IOTAFile;
begin
   Result := nil;
end;

function TGoModuleCreator.NewImplSource(const ModuleIdent, FormIdent,
    AncestorIdent: string): IOTAFile;
const
  sSource =
  'unit %s;' + #13#10 +
  '// Created with TGoModuleCreator' + #13#10 +
  '' + #13#10 +
  'interface' + #13#10 +
  '' + #13#10 +
  'uses' + #13#10 +
  '  SysUtils, Classes, GoWidgetset;' + #13#10 +
  '' + #13#10 +
  'type' + #13#10 +
  '  T%s = class(T%s)' + #13#10 +
  '  private' + #13#10 +
  '    { Private declarations }' + #13#10 +
  '  public' + #13#10 +
  '    { Public declarations }' + #13#10 +
  '  end;' + #13#10 +
  '' + #13#10 +
  'var' + #13#10 +
  '  %s: T%s;' + #13#10 +
  '' + #13#10 +
  'implementation' + #13#10 +
  '' + #13#10 +
  '{$R *.DFM}' + #13#10 +
  '' + #13#10 +
  'initialization' + #13#10 +
  '' + #13#10 +
  '  //RegisterClasses([T%s])' + #13#10 +
  '' + #13#10 +
  'end.';
begin
  Result := TGoSourceFile.Create(Format(sSource, [ModuleIdent, FormIdent,
                           AncestorIdent, FormIdent, FormIdent, FormIdent]));
end;

function TGoModuleCreator.NewIntfSource(const ModuleIdent, FormIdent,
    AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

constructor TGoModuleCreatorWizard.Create;
begin
  inherited;
  FFreeNotificator:=TGoNotificator.Create(nil);
  FFreeNotificator.OnNotification:=Notification;
//  CreateActionItems;
  FTimer:= TTimer.Create(nil);
  FTimer.Interval:= 200;
  FTimer.OnTimer:=Tick;
  FTimer.Enabled:=True;
end;

destructor TGoModuleCreatorWizard.Destroy;
begin
  if FTimer<>nil then FTimer.Free;
  FreeAndNil(FFreeNotificator);
  if FMenuItem<>nil then FMenuItem.Free;
//  if FModuleCreateButton<>nil then FModuleCreateButton.Free;
  if FModuleCreateAction<>nil then FreeAndNil(FModuleCreateAction);
//  FreeAndNil(FModuleCreateAction);
  inherited;
end;

procedure TGoModuleCreatorWizard.CreateActionItems;
var IdeMainForm:TCustomForm;
    AToolBar:TToolBar;
//    AMenu:TMainMenu;
    j:integer;
begin
  IdeMainForm:=Application.FindComponent('AppBuilder') as TCustomForm;
  FModuleCreateAction:=TGoModuleCreateAction.Create(IdeMainForm);
  FModuleCreateAction.DisableIfNoHandler:=False;
  FModuleCreateAction.FreeNotification(FFreeNotificator);
  FModuleCreateAction.Caption:='New GoForm';
  FModuleCreateAction.Hint:='New GoForm';
//  FModuleCreateAction.ImageIndex:=1;
  FModuleCreateAction.Category:='goCat';
  RegisterActionWithImageIndex(FModuleCreateAction,'_go.CreateModule');
  AToolBar:=(BorlandIDEServices as INTAServices40).ToolBar[sViewToolBar];
  FModuleCreateButton:=nil;
  for j:=AToolBar.ButtonCount-1 downto 0 do
    if (AToolBar.Buttons[j].Caption=FModuleCreateAction.Caption) or
       (AToolBar.Buttons[j].Caption='') then
      begin
        FModuleCreateButton:=AToolBar.Buttons[j];
        Break;
      end;
  if FModuleCreateButton=nil then
    FModuleCreateButton:=TToolButton.Create(IdeMainForm);
  FModuleCreateButton.FreeNotification(FFreeNotificator);
  FModuleCreateButton.Action:=FModuleCreateAction;
  if AToolBar.ButtonCount=0 then
    FModuleCreateButton.Left:=0
  else FModuleCreateButton.Left:=AToolBar.Buttons[AToolBar.ButtonCount-1].Left+24;
  FModuleCreateButton.Parent:=AToolBar;
  FMenuItem:=TMenuItem.Create(nil);
  FMenuItem.FreeNotification(FFreeNotificator);
  FMenuItem.Action:=FModuleCreateAction;
//  AMenu:=(BorlandIDEServices as INTAServices).MainMenu;
//  AMenu.Items.Insert(AMenu.Items.Count-1,FMenuItem);
end;

{ TGoModuleCreatorWizard }

procedure TGoModuleCreatorWizard.Execute;
begin
  if FModuleCreateAction<>nil then FModuleCreateAction.Execute;
end;

function TGoModuleCreatorWizard.GetAuthor: string;
begin
  Result := 'x2nie';
end;

function TGoModuleCreatorWizard.GetComment: string;
begin
  Result := 'GoForm';
end;

function TGoModuleCreatorWizard.GetDesigner: string;
begin
  Result := dVCL;
end;

{function TGoModuleCreatorWizard.GetGalleryCategory: IOTAGalleryCategory;
begin
//  Result := (BorlandIDEServices as IOTAGalleryCategoryManager).FindCategory(sCategoryDelphiNewFiles);
  Result := nil;
end;}

function TGoModuleCreatorWizard.GetGlyph: Cardinal;
begin
  Result := 0;
end;

function TGoModuleCreatorWizard.GetIDString: string;
begin
  Result := 'xManagersModules.GoForm';
end;

function TGoModuleCreatorWizard.GetMenuText: string;
begin
  Result := 'New GoForm';
end;

function TGoModuleCreatorWizard.GetName: string;
begin
  Result := 'GoForm';
end;

function TGoModuleCreatorWizard.GetPage: string;
begin
  Result := 'xTest';
end;

function TGoModuleCreatorWizard.GetPersonality: string;
begin
  Result := 'sDelphiPersonality';
end;

function TGoModuleCreatorWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

procedure TGoModuleCreatorWizard.Notification(AComponent: TComponent;
    Operation: TOperation);
begin
  if Operation=opRemove then begin
    if AComponent=FMenuItem then FMenuItem:=nil
    else if AComponent=FModuleCreateButton then FModuleCreateButton:=nil
    else if AComponent=FModuleCreateAction then FModuleCreateAction:=nil;
  end;
end;

procedure TGoModuleCreatorWizard.Tick(sender: tobject);
var intf: INTAServices;
begin
  if BorlandIDEServices.QueryInterface(INTAServices,intf)=s_OK then begin
    FreeAndNil(FTimer);
    CreateActionItems;
  end;
end;

{ ICustomDesignForm }
procedure TGoModuleDesignModule.CreateDesignerForm(const Designer:
    IDesigner; Root: TComponent; out DesignForm: TCustomForm; out
    ComponentContainer: TWinControl);
begin
  DesignForm := TGoModuleDesignerForm.CreateEx(nil, Designer, ComponentContainer);
end;

class function TGoModuleDesignModule.DesignClass: TComponentClass;
begin
  Result := nil;
//  Result := TGoForm;
end;

function TGoModuleDesignModule.GetAttributes: TCustomModuleAttributes;
begin
  Result := [cmaVirtualSize];
end;

function TGoModuleDesignModule.ValidateComponentClass(ComponentClass:
    TComponentClass): Boolean;
begin
  Result := inherited ValidateComponentClass(ComponentClass) and
    ComponentClass.InheritsFrom(TGoWidget);
end;

function TGoModuleCreateAction.Execute: Boolean;
begin
  (BorlandIDEServices as IOTAModuleServices).CreateModule(TGoModuleCreator.CreateEx('TGoForm'));
  Result:=True;
end;

function TGoModuleCreateAction.Update: Boolean;
begin
  Enabled:=True;
  Result:=True;
end;

procedure TGoNotificator.Notification(AComponent: TComponent; Operation:
    TOperation);
begin
  inherited Notification(AComponent,Operation);//obavezno !!!!!
  if Assigned(FOnNotification) then FOnNotification(AComponent,Operation);
end;






end.


