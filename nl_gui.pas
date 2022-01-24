unit nl_GUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_functions, nl_language, nl_data, graphics, DateUtils;

Procedure LoadGUIInterface();
Procedure RefreshAddresses();
Procedure RefreshNodes();
Procedure RefreshStatus();

implementation

uses
  nl_mainform;


// Loads all the GUI
Procedure LoadGUIInterface();
Begin
form1.SGridAddresses.FocusRectVisible:=false;
form1.SGridAddresses.Cells[0,0] := rsGUI0001;
form1.SGridAddresses.Cells[1,0] := rsGUI0002;
form1.SGridAddresses.Cells[2,0] := rsGUI0003;
form1.SGridAddresses.Cells[3,0] := rsGUI0004;
form1.SGridNodes.FocusRectVisible:=false;
form1.SGridNodes.Cells[0,0] := rsGUI0005;
form1.SGridNodes.Cells[1,0] := rsGUI0006;
form1.SGridNodes.Cells[2,0] := rsGUI0007;
form1.SGridNodes.Cells[3,0] := rsGUI0008;
form1.SGridNodes.Cells[4,0] := rsGUI0018;
form1.SGridNodes.Cells[5,0] := rsGUI0019;
Form1.SGridSC.Cells[0,0]:=rsGUI0014;
Form1.SGridSC.Cells[0,1]:=rsGUI0015;
Form1.SGridSC.Cells[0,2]:=rsGUI0016;
form1.CBMultisend.Checked:=WO_Multisend;
End;

// Refresh the adressess grid
Procedure RefreshAddresses();
var
  counter : integer = 0;
Begin
Int_WalletBalance := 0;
Int_LockedBalance := 0;
EnterCriticalSection(CS_ARRAY_Addresses);
form1.SGridAddresses.RowCount:=length(ARRAY_Addresses)+1;
if length(ARRAY_Addresses)>0 then
   begin
   for counter := 0 to length(ARRAY_Addresses)-1 do
      begin
      form1.SGridAddresses.Cells[0,counter+1] := GetAddressToShow(ARRAY_Addresses[counter].Hash);
      form1.SGridAddresses.Cells[1,counter+1] := Int2Curr(ARRAY_Pending[counter].incoming);
      form1.SGridAddresses.Cells[2,counter+1] := Int2Curr(ARRAY_Pending[counter].outgoing);
      form1.SGridAddresses.Cells[3,counter+1] := Int2Curr(ARRAY_Addresses[counter].Balance-ARRAY_Pending[counter].outgoing);
      if ARRAY_Addresses[counter].PrivateKey[1] = '*' then
         Int_LockedBalance := Int_LockedBalance+ARRAY_Addresses[counter].Balance-ARRAY_Pending[counter].outgoing
      else Int_WalletBalance := Int_WalletBalance+ARRAY_Addresses[counter].Balance-ARRAY_Pending[counter].outgoing;
      end;
   end;
LeaveCriticalSection(CS_ARRAY_Addresses);
form1.LBalance1.Caption:=Format(rsGUI0009,[Int2Curr(Int_WalletBalance)]);
form1.LabelLocked.Caption:=Format(rsGUI0009,[Int2Curr(Int_LockedBalance)]);
End;

// Refresh the nodes grid
Procedure RefreshNodes();
var
  counter : integer = 0;
Begin
form1.SGridNodes.RowCount:=length(ARRAY_Nodes)+1;
if length(ARRAY_Nodes)>0 then
   begin
   for counter := 0 to length(ARRAY_Nodes)-1 do
      begin
      form1.SGridNodes.Cells[0,counter+1] := ARRAY_Nodes[counter].Host;
      form1.SGridNodes.Cells[1,counter+1] := ARRAY_Nodes[counter].Block.ToString;
      form1.SGridNodes.Cells[2,counter+1] := ARRAY_Nodes[counter].Pending.ToString;
      form1.SGridNodes.Cells[3,counter+1] := ARRAY_Nodes[counter].Branch;
      form1.SGridNodes.Cells[4,counter+1] := ARRAY_Nodes[counter].MNsHash;
      form1.SGridNodes.Cells[5,counter+1] := ARRAY_Nodes[counter].MNsCount.ToString;
      end;
   end;
End;

// Refresh the status bar
Procedure RefreshStatus();
Begin
if Wallet_Synced then form1.PanelBlockInfo.Color:=clGreen
else form1.PanelBlockInfo.Color:=clRed;
form1.LabelBlockInfo.Caption:=WO_LastBlock.ToString;
form1.LabelTime.Caption:=TimestampToDate(G_UTCTime);
End;

END. // END UNIT

