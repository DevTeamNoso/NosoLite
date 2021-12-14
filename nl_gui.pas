unit nl_GUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_functions, nl_language, nl_data;

Procedure ResizeSGridAddresses();
Procedure ResizeSGridNodes();
Procedure LoadGUIInterface();
Procedure RefreshAddresses();
Procedure RefreshNodes();

implementation

uses
  nl_mainform;

// Resize the stringgrid containing the addresses
Procedure ResizeSGridAddresses();
var
  GridWidth : integer;
Begin
GridWidth := form1.SGridAddresses.Width;
form1.SGridAddresses.ColWidths[0] := ThisPercent(40,GridWidth);
form1.SGridAddresses.ColWidths[1] := ThisPercent(20,GridWidth);
form1.SGridAddresses.ColWidths[2] := ThisPercent(20,GridWidth);
form1.SGridAddresses.ColWidths[3] := ThisPercent(20,GridWidth,true);
End;

// Resize the stringgrid containing the nodes
Procedure ResizeSGridNodes();
var
  GridWidth : integer;
Begin
GridWidth := form1.SGridNodes.Width;
form1.SGridNodes.ColWidths[0] := ThisPercent(40,GridWidth);
form1.SGridNodes.ColWidths[1] := ThisPercent(20,GridWidth);
form1.SGridNodes.ColWidths[2] := ThisPercent(20,GridWidth);
form1.SGridNodes.ColWidths[3] := ThisPercent(20,GridWidth,true);
End;

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

form1.LabelBlock.Caption:='Block: '+WO_LastBlock.ToString;
End;

// Refresh the adressess grid
Procedure RefreshAddresses();
var
  counter : integer = 0;
Begin
form1.SGridAddresses.RowCount:=length(ARRAY_Addresses)+1;
if length(ARRAY_Addresses)>0 then
   begin
   for counter := 0 to length(ARRAY_Addresses)-1 do
      begin
      if ARRAY_Addresses[counter].Custom<>'' then form1.SGridAddresses.Cells[0,counter+1] := ARRAY_Addresses[counter].custom
      else form1.SGridAddresses.Cells[0,counter+1] := ARRAY_Addresses[counter].Hash;
      form1.SGridAddresses.Cells[1,counter+1] := Int2Curr(0);
      form1.SGridAddresses.Cells[2,counter+1] := Int2Curr(0);
      form1.SGridAddresses.Cells[3,counter+1] := Int2Curr(0);
      end;
   end;
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
      end;
   end;

End;

END. // END UNIT

