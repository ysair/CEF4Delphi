// ************************************************************************
// ***************************** CEF4Delphi *******************************
// ************************************************************************
//
// CEF4Delphi is based on DCEF3 which uses CEF to embed a chromium-based
// browser in Delphi applications.
//
// The original license of DCEF3 still applies to CEF4Delphi.
//
// For more information about CEF4Delphi visit :
//         https://www.briskbard.com/index.php?lang=en&pageid=cef
//
//        Copyright � 2022 Salvador Diaz Fau. All rights reserved.
//
// ************************************************************************
// ************ vvvv Original license and comments below vvvv *************
// ************************************************************************
(*
 *                       Delphi Chromium Embedded 3
 *
 * Usage allowed under the restrictions of the Lesser GNU General Public License
 * or alternatively the restrictions of the Mozilla Public License 1.1
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * Unit owner : Henri Gourvest <hgourvest@gmail.com>
 * Web site   : http://www.progdigy.com
 * Repository : http://code.google.com/p/delphichromiumembedded/
 * Group      : http://groups.google.com/group/delphichromiumembedded
 *
 * Embarcadero Technologies, Inc is not permitted to use or redistribute
 * this source code without explicit permission.
 *
 *)

unit uBrowserTab;

{$I cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
  Winapi.Windows, System.Classes, Winapi.Messages, Vcl.ComCtrls, Vcl.Controls,
  Vcl.Forms, System.SysUtils,
  {$ELSE}
  Windows, Classes, Messages, ComCtrls, Controls,
  Forms, SysUtils,
  {$ENDIF}
  uCEFInterfaces, uCEFTypes, uBrowserFrame;

type
  TBrowserTab = class(TTabSheet)
    protected
      FBrowserFrame : TBrowserFrame;
      FTabID        : cardinal;

      function    GetParentForm : TCustomForm;
      function    GetInitialized : boolean;
      function    GetClosing : boolean;

      function    PostFormMessage(aMsg : cardinal; aWParam : WPARAM = 0; aLParam : LPARAM = 0) : boolean;

      procedure   BrowserFrame_OnBrowserCreated(Sender: TObject);
      procedure   BrowserFrame_OnBrowserDestroyed(Sender: TObject);
      procedure   BrowserFrame_OnBrowserTitleChange(Sender: TObject; const aTitle : string);

      property    ParentForm : TCustomForm  read GetParentForm;

    public
      constructor Create(AOwner: TComponent; aTabID : cardinal; const aCaption : string); reintroduce;
      procedure   NotifyMoveOrResizeStarted;
      procedure   CreateFrame(const aHomepage : string = '');
      procedure   CreateBrowser(const aHomepage : string);
      procedure   CloseBrowser;
      procedure   ShowBrowser;
      procedure   HideBrowser;
      procedure   HandleBrowserMessage(var Msg: tagMSG; var Handled: Boolean);
      function    CreateClientHandler(var windowInfo : TCefWindowInfo; var client : ICefClient; const targetFrameName : string; const popupFeatures : TCefPopupFeatures) : boolean;
      function    DoOnBeforePopup(var windowInfo : TCefWindowInfo; var client : ICefClient; const targetFrameName : string; const popupFeatures : TCefPopupFeatures; targetDisposition : TCefWindowOpenDisposition) : boolean;
      function    DoOpenUrlFromTab(const targetUrl : string; targetDisposition : TCefWindowOpenDisposition) : boolean;

      property    TabID             : cardinal   read FTabID;
      property    Closing           : boolean    read GetClosing;
      property    Initialized       : boolean    read GetInitialized;
  end;

implementation

uses
  uMainForm;

constructor TBrowserTab.Create(AOwner: TComponent; aTabID : cardinal; const aCaption : string);
begin
  inherited Create(AOwner);

  FTabID        := aTabID;
  Caption       := aCaption;
  FBrowserFrame := nil;
end;

function TBrowserTab.GetParentForm : TCustomForm;
var
  TempParent : TWinControl;
begin
  TempParent := Parent;

  while (TempParent <> nil) and not(TempParent is TCustomForm) do
    TempParent := TempParent.Parent;

  if (TempParent <> nil) and (TempParent is TCustomForm) then
    Result := TCustomForm(TempParent)
   else
    Result := nil;
end;

function TBrowserTab.GetInitialized : boolean;
begin
  Result := (FBrowserFrame <> nil) and
            FBrowserFrame.Initialized;
end;

function TBrowserTab.GetClosing : boolean;
begin
  Result := (FBrowserFrame <> nil) and
            FBrowserFrame.Closing;
end;

function TBrowserTab.PostFormMessage(aMsg : cardinal; aWParam : WPARAM; aLParam : LPARAM) : boolean;
var
  TempForm : TCustomForm;
begin
  TempForm := ParentForm;
  Result   := (TempForm <> nil) and
              TempForm.HandleAllocated and
              PostMessage(TempForm.Handle, aMsg, aWParam, aLParam);
end;

procedure TBrowserTab.NotifyMoveOrResizeStarted;
begin
  FBrowserFrame.NotifyMoveOrResizeStarted;
end;

procedure TBrowserTab.CreateFrame(const aHomepage : string);
begin
  if (FBrowserFrame = nil) then
    begin
      FBrowserFrame                      := TBrowserFrame.Create(self);
      FBrowserFrame.Name                 := 'BrowserFrame' + IntToStr(TabID);
      FBrowserFrame.Parent               := self;
      FBrowserFrame.Align                := alClient;
      FBrowserFrame.Visible              := True;
      FBrowserFrame.OnBrowserCreated     := BrowserFrame_OnBrowserCreated;
      FBrowserFrame.OnBrowserDestroyed   := BrowserFrame_OnBrowserDestroyed;
      FBrowserFrame.OnBrowserTitleChange := BrowserFrame_OnBrowserTitleChange;
    end;

  FBrowserFrame.Homepage := aHomepage;
end;

procedure TBrowserTab.CreateBrowser(const aHomepage : string);
begin
  CreateFrame(aHomepage);

  if (FBrowserFrame <> nil) then
    FBrowserFrame.CreateBrowser;
end;

procedure TBrowserTab.CloseBrowser;
begin
  if (FBrowserFrame <> nil) then
    FBrowserFrame.CloseBrowser;
end;

procedure TBrowserTab.ShowBrowser;
begin
  if (FBrowserFrame <> nil) then
    FBrowserFrame.ShowBrowser;
end;

procedure TBrowserTab.HideBrowser;
begin
  if (FBrowserFrame <> nil) then
    FBrowserFrame.HideBrowser;
end;

procedure TBrowserTab.HandleBrowserMessage(var Msg: tagMSG; var Handled: Boolean);
begin
  if (FBrowserFrame <> nil) then
    FBrowserFrame.HandleBrowserMessage(Msg, Handled);
end;

procedure TBrowserTab.BrowserFrame_OnBrowserDestroyed(Sender: TObject);
begin
  PostFormMessage(CEF_DESTROYTAB, TabID);
end;

procedure TBrowserTab.BrowserFrame_OnBrowserCreated(Sender: TObject);
begin
  PostFormMessage(CEF_SHOWTABID, TabID);
end;

procedure TBrowserTab.BrowserFrame_OnBrowserTitleChange(Sender: TObject; const aTitle : string);
begin
  Caption := aTitle;
end;

function TBrowserTab.CreateClientHandler(var   windowInfo        : TCefWindowInfo;
                                         var   client            : ICefClient;
                                         const targetFrameName   : string;
                                         const popupFeatures     : TCefPopupFeatures) : boolean;
begin
  Result := (FBrowserFrame <> nil) and
            FBrowserFrame.CreateClientHandler(windowInfo, client, targetFrameName, popupFeatures);
end;

function TBrowserTab.DoOnBeforePopup(var   windowInfo        : TCefWindowInfo;
                                     var   client            : ICefClient;
                                     const targetFrameName   : string;
                                     const popupFeatures     : TCefPopupFeatures;
                                           targetDisposition : TCefWindowOpenDisposition) : boolean;
var
  TempForm : TCustomForm;
begin
  TempForm := ParentForm;
  Result   := (TempForm <> nil) and
              (TempForm is TMainForm) and
              TMainForm(TempForm).DoOnBeforePopup(windowInfo, client, targetFrameName, popupFeatures, targetDisposition);
end;

function TBrowserTab.DoOpenUrlFromTab(const targetUrl         : string;
                                            targetDisposition : TCefWindowOpenDisposition) : boolean;
var
  TempForm : TCustomForm;
begin
  TempForm := ParentForm;
  Result   := (TempForm <> nil) and
              (TempForm is TMainForm) and
              TMainForm(TempForm).DoOpenUrlFromTab(targetUrl, targetDisposition);
end;

end.
