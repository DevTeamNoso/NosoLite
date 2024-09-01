unit nl_network;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_data, IdGlobal, dialogs, nl_functions, nl_language,
  IdTCPClient, splashform,nosodebug,nosoconsensus;

function SendOrder(OrderString:String):String;
function GetPendings():string;
//function GetMainnetTimestamp(MaxTrys:integer=5):int64;
function GetMNsFromNode(MaxTrys:integer=5):string;
function GetNosoCFGFromNode(MaxTrys:integer=5):string;

implementation

Uses
  nl_mainform, nl_Disk;

// Sends a order to the mainnet
function SendOrder(OrderString:String):String;
var
  Client    : TidTCPClient;
  RanNode   : integer;
  ThisNode  : String;
  TrysCount : integer = 0;
  WasOk     : Boolean = false;
Begin
Result := '';
Client := TidTCPClient.Create(nil);
REPEAT
Inc(TrysCount);
ThisNode := GetRandonNode;
Client.Host := Parameter(ThisNode,0);
Client.Port := StrToIntDef(Parameter(ThisNode,1),8080);
Client.ConnectTimeout:= 3000;
Client.ReadTimeout:=3000;
TRY
Client.Connect;
Client.IOHandler.WriteLn(OrderString);
Result := Client.IOHandler.ReadLn(IndyTextEncoding_UTF8);
WasOK := True;
EXCEPT on E:Exception do
   begin
   ToLog('main',Format(rsError0015,[E.Message]));
   end;
END{Try};
UNTIL ( (WasOk) or (TrysCount=3) );
if result <> '' then REF_Addresses := true;
if client.Connected then Client.Disconnect();
client.Free;
End;

function GetPendings():string;
var
  Client : TidTCPClient;
  RanNode  : integer;
  ThisNode : string;
Begin
Result := '';
Client := TidTCPClient.Create(nil);
ThisNode       := GetRandonNode;
Client.Host := Parameter(ThisNode,0);
Client.Port := StrToIntDef(Parameter(ThisNode,1),8080);
Client.ConnectTimeout:= 1000;
Client.ReadTimeout:=1000;
TRY
Client.Connect;
Client.IOHandler.WriteLn('NSLPEND');
Result := Client.IOHandler.ReadLn(IndyTextEncoding_UTF8);
REF_Addresses := true;
EXCEPT on E:Exception do
   begin
   ToLog('main',Format(rsError0014,[E.Message]));
   Int_LastPendingCount := 0;
   end;
END;{Try}
if client.Connected then Client.Disconnect();
client.Free;
End;

{
function GetMainnetTimestamp(MaxTrys:integer=5):int64;
var
  Client   : TidTCPClient;
  RanNode  : integer;
  ThisNode : NodeData;
  WasDone  : boolean = false;
  Trys     : integer = 0;
Begin
Result := 0;
Client := TidTCPClient.Create(nil);
REPEAT
   ThisNode := PickRandomNode;
   Client.Host:=ThisNode.host;
   Client.Port:=ThisNode.port;
   Client.ConnectTimeout:= 1000;
   Client.ReadTimeout:= 1000;
   TRY
   Client.Connect;
   Client.IOHandler.WriteLn('NSLTIME');
   Result := StrToInt64Def(Client.IOHandler.ReadLn(IndyTextEncoding_UTF8),0);
   WasDone := true;
   EXCEPT on E:Exception do
      begin
      WasDone := False;
      end;
   END{Try};
Inc(Trys);
UNTIL ( (WasDone) or (Trys = MaxTrys) );
if client.Connected then Client.Disconnect();
client.Free;
End;
}

function GetMNsFromNode(MaxTrys:integer=5):string;
var
  Client   : TidTCPClient;
  RanNode  : integer;
  ThisNode : string;
  WasDone  : boolean = false;
  Trys     : integer = 0;
Begin
Result := '';
Client := TidTCPClient.Create(nil);
REPEAT
  ThisNode       := GetRandonNode;
  Client.Host := Parameter(ThisNode,0);
  Client.Port := StrToIntDef(Parameter(ThisNode,1),8080);
   Client.ConnectTimeout:= 3000;
   Client.ReadTimeout:= 3000;
   TRY
   Client.Connect;
   Client.IOHandler.WriteLn('NSLMNS');
   Result := Client.IOHandler.ReadLn(IndyTextEncoding_UTF8);
   WasDone := true;
   EXCEPT on E:Exception do
      begin
      WasDone := False;
      end;
   END{Try};
Inc(Trys);
UNTIL ( (WasDone) or (Trys = MaxTrys) );
if client.Connected then Client.Disconnect();
client.Free;
End;

function GetNosoCFGFromNode(MaxTrys:integer=5):string;
var
  Client   : TidTCPClient;
  RanNode  : integer;
  ThisNode : string;
  WasDone  : boolean = false;
  Trys     : integer = 0;
Begin
Result := '';
Client := TidTCPClient.Create(nil);
REPEAT
   ThisNode := GetRandonNode;
   Client.Host := Parameter(ThisNode,0);
   Client.Port := StrToIntDef(Parameter(ThisNode,1),8080);
   Client.ConnectTimeout:= 3000;
   Client.ReadTimeout:= 3000;
   TRY
   Client.Connect;
   Client.IOHandler.WriteLn('NSLCFG');
   Result := Client.IOHandler.ReadLn(IndyTextEncoding_UTF8);
   WasDone := true;
   EXCEPT on E:Exception do
      begin
      WasDone := False;
      end;
   END{Try};
Inc(Trys);
UNTIL ( (WasDone) or (Trys = MaxTrys) );
if client.Connected then Client.Disconnect();
client.Free;
End;

END. // END UNIT.

