unit nl_data;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IdTCPClient, dateutils, strutils, formlog,nosotime,
  nosoconsensus,nosodebug,nosonosocfg;

Type

WalletData = Packed Record
   Hash : String[40];              // Public hash
   Custom : String[40];            // Custom alias
   PublicKey : String[255];        // Public key
   PrivateKey : String[255];       // Private key
   Balance : int64;                // Last known balance
   Pending : int64;                // Last pending balance
   Score : int64;                  // Aditional field
   LastOP : int64;                 // last operation block
   end;

DivResult = packed record
   cociente : string[255];
   residuo : string[255];
   end;


TUpdateThread = class(TThread)
    private
      procedure UpdateNodes;
      procedure UpdateAddresses;
      procedure UpdateLog;
      procedure UpdateStatus;
      procedure showsync;
      procedure hidesync;
      procedure showdownload;
      procedure hidedownload;
      procedure UpdateGVTs;
    protected
      procedure Execute; override;
    public
      Constructor Create(CreateSuspended : boolean);
    end;

NodeData = packed record
   host      : string[60];
   Peers     : integer;
   Version   : string[10];
   port      : integer;
   block     : integer;
   Pending   : integer;
   Branch    : String[40];
   MNsHash   : string[32];
   MNsCount  : integer;
   Updated   : integer;
   LBHash    : String[32];
   NMSDiff   : String[32];
   LBTimeEnd : Int64;
   Checks    : integer;
   Synced    : boolean;
   SumHash   : string[5];
   LBMiner   : String[32];
   LBPoW     : int64;
   LBSolDiff : string[32];
   GVTHash   : String[5];
   end;

ConsensusData = packed record
   Value : string[40];
   count : integer;
   end;

OrderData = Packed Record
   Block : integer;
   OrderID : String[64];
   OrderLines : Integer;
   OrderType : String[6];
   TimeStamp : Int64;
   Reference : String[64];
     TrxLine : integer;
     Sender : String[120];    // La clave publica de quien envia
     Address : String[40];
     Receiver : String[40];
     AmmountFee : Int64;
     AmmountTrf : Int64;
     Signature : String[120];
     TrfrID : String[64];
   end;

SumaryData = Packed Record
   Hash    : String[40]; // El hash publico o direccion
   Custom  : String[40]; // En caso de que la direccion este personalizada
   Balance : int64;      // el ultimo saldo conocido de la direccion
   Score   : int64;      // estado del registro de la direccion.
   LastOP  : int64;      // tiempo de la ultima operacion en UnixTime.
   end;

PendingData = Packed Record
   incoming : int64;
   outgoing : int64;
   end;

AppData     = packed record
   name     : string[20];
   code     : string[100];
   RegAddr  : string[40];
   end;

TMNData     = packed record
   ip      : string[15];
   port    : integer;
   Address : string[32];
   Count   : integer;
   end;

TGVT = packed record
     number   : string[2];
     owner    : string[32];
     Hash     : string[64];
     control  : integer;
     end;

TypeLabel = packed record
     Address  : string[32];
     LabelSt  : string[20];
     end;

CONST
  WalletDirectory   = 'wallet'+directoryseparator;  // Wallet folder
  DataDirectory     = 'data'+directoryseparator;
  WalletFileName    = WalletDirectory+'wallet.pkw';  // Wallet keys file
  TrashFilename     = WalletDirectory+'trash.pkw';
  SumaryFilename    = DataDirectory+'sumary.psk';
  ZipSumaryFilename = DataDirectory+'sumary.zip';
  OptionsFilename   = DataDirectory+'options.nsl';                // Options file
  MNsFilename       = DataDirectory+'masternodes.txt';
  GVTFilename       = DataDirectory+'gvts.psk';
  LabelsFilename    = DataDirectory+'labels.psk';
  StartLogFilename  = DataDirectory+'startlog.txt';
  MainLogFilename   = DataDirectory+'log.txt';
  DeepDebLogFilename = DataDirectory+DirectorySeparator+'deepdeb.txt';
  Customizationfee =25000;
  Comisiontrfr = 10000;
  MinimunFee = 1000000;
  Protocol = 2;
  ProgramVersion = '1.80';

  HexAlphabet : string = '0123456789ABCDEF';
  B58Alphabet : string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  B36Alphabet : string = '0123456789abcdefghijklmnopqrstuvwxyz';
  CustomValid : String = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890@*+-_:';
  Customfee   = 25000;

var
  FILE_Wallet   : File of WalletData; // Wallet file pointer
  FILE_Trash    : File of WalletData;
  FILE_Options  : textfile;
  FILE_Sumary   : File of SumaryData;
  FILE_MNs      : TextFile;
  FILE_CFG      : TextFile;
  FILE_GVTs     : File of TGVT;
  FILE_Labels   : TextFile;
  FILE_StartLog : TextFile;

  ARRAY_Addresses : array of WalletData;
  ARRAY_Nodes     : array of NodeData;
  ARRAY_Sumary    : array of SumaryData;
  ARRAY_Pending   : array of PendingData;
  ARRAY_GVTs      : array of TGVT;
  ARRAY_Labels    : array of TypeLabel;

  THREAD_Update : TUpdateThread;

  STR_SeedNodes : String = '0 20.199.50.27;8080:X:X '+
                           '107.172.21.121;8080:X:X '+
                           '107.172.214.53;8080:X:X '+
                           '198.23.134.105;8080:X:X '+
                           '107.173.210.55;8080:X:X '+
                           '5.230.55.203;8080:X:X '+
                           '141.11.192.215;8080:X:X '+
                           '4.233.61.8;8080:X:X '+
                           '84.247.143.153;8080:X:X ';

  LastNodesUpdateTime     : int64 = 0;
  Int_WalletBalance       : int64 = 0;
  Int_LockedBalance       : int64 = 0;
  Int_SumarySize          : int64 = 0;
  Int_LastPendingCount    : int64 = 0;
    Pendings_String       : string = '';
  Int_TotalSupply         : integer = 0;
  Int_StakeSize           : integer = 0;
  Int_GVTOwned            : integer = 0;
  LastLogLine             : string = '';

  WO_LastBlock    : integer = 0;
  WO_LastSumary   : string = '';
  WO_Refreshrate  : integer = 15;
  WO_Multisend    : boolean = false;
  WO_UseSeedNodes : Boolean = true;

  // Global variables
  SAVE_Wallet    : Boolean = false;
  Closing_App    : boolean = false;
  Wallet_Synced  : Boolean = false;
  REF_Addresses  : Boolean = false;
  REF_Nodes      : Boolean = false;
  REF_Status     : Boolean = false;
  REF_GVTS       : Boolean = false;
  //LogLines       : TStringList;
  G_Masternodes  : String = '';
  G_UTCTime      : int64;
  G_FirstRun     : boolean = true;
  MainNetOffSet  : int64 = 0;
  G_UpdatedMNs   : String = '';
  G_NosoCFGStr   : string = '';

  // Critical Sections
  CS_ARRAY_Addresses: TRTLCriticalSection;
  CS_LOG            : TRTLCriticalSection;
  CS_ArrayNodes     : TRTLCriticalSection;
  CS_Masternodes    : TRTLCriticalSection;

  // Apps Related
  LiqPoolHost       : String = '155.138.193.27';
  LiqPoolPort       : integer = 8085;


implementation

Uses
  nl_mainform, nl_network, nl_functions, nl_GUI, nl_language, nl_disk, nl_consensus, nl_cripto;

constructor TUpdateThread.Create(CreateSuspended : boolean);
Begin
inherited Create(CreateSuspended);
FreeOnTerminate := True;
End;

procedure TUpdateThread.UpdateNodes();
Begin
RefreshNodes();
REF_Nodes := false
End;

procedure TUpdateThread.UpdateAddresses();
Begin
RefreshAddresses;
REF_Addresses := false;
End;

procedure TUpdateThread.UpdateLog();
Begin
  Form5.memolog.lines.Add(LastLogLine);

End;

procedure TUpdateThread.UpdateStatus();
Begin
RefreshStatus();
REF_Status := false;
End;

procedure TUpdateThread.showsync();
Begin
Form1.Panelsync.Visible:=true;
End;

procedure TUpdateThread.hidesync();
Begin
Form1.Panelsync.Visible:=false;
End;

procedure TUpdateThread.showdownload();
Begin
Form1.PanelDownload.Visible:=true;
End;

procedure TUpdateThread.hidedownload();
Begin
Form1.PanelDownload.Visible:=false;
End;

procedure TUpdateThread.UpdateGVTs();
Begin
RefreshGVTs();
REF_GVTs := false;
End;

procedure TUpdateThread.Execute;
var
  counter : integer;
  LLine : String = '';
  ActualTime : int64;
  LastRefNodes : int64;
  NewCFGData : string;
Begin
While not terminated do
   begin
   if LastRefNodes <> LastConsensusTime then
     begin
     REF_Nodes := true;
     LastRefNodes := LastConsensusTime;
     end;
   //{
   if Getconsensus(3).ToInteger{Pendings} > Int_LastPendingCount then
     begin
     Pendings_String := GetPendings();
     ProcessPendings();
     Int_LastPendingCount := Getconsensus(3).ToInteger;
     end;
   //}
   //{
   if ( (GetConsensus(2){lastblock}.ToInteger>GetSumaryLastBlock) and (not GettingSum) and (not SumReceived) ) then
      // NEW BLOCK
      begin
      Synchronize(@showdownload);
      Int_LastPendingCount := 0;
      Pendings_String := '';
      ProcessPendings();
      REF_Addresses := true;
      ToLog('main','Downloading sumary');
      RunGetSumary();
      REF_Status := true;
      end;
   //}

   //{
   if SumReceived then
      begin
      ToLog('main','Sumary downloaded');
      Synchronize(@hidedownload);
      if GoodSumary then
         begin
         UnZipSumary;
         LoadSumary();
         REF_Addresses := true;
         G_UpdatedMNs := GetMNsFromNode;
         if StrToIntDef(Parameter(G_UpdatedMNs,0),-1)> MasternodesLastBlock then
            begin
            SaveMnsToFile(G_UpdatedMNs);
            FillArrayNodes;
            LastNodesUpdateTime := 0;
            end;
         //G_NosoCFGStr := GetNosoCFGFromNode;
         end;
      SumReceived := false;
      end;
   //}
   //{
   If Copy(HashMD5File(GVTFilename),1,5) <> Copy(GetConsensus(18),1,5) then
      begin
      if (not UpdatingGVTs) then
         begin
         UpdatingGVTs := true;
         RunUpdateGVTs();
         end;
      end;
   if Copy(GetCFGHash,1,5) <> Copy(GetConsensus(19),1,5) then
      begin
      //ToLog('main','CFG dont match');
      NewCFGData := GetNosoCFGFromNode;
      if NewCFGData <> '' then
         begin
         SaveCFGToFile(NewCFGData);
         FillArrayNodes;
         end;
      end;
   //}
   if GetConsensus(2){lastblock}.ToInteger=GetSumaryLastBlock then Wallet_Synced := true
   else Wallet_Synced := false;
   //if SAVE_Wallet then SaveWallet;
   if REF_Addresses then Synchronize(@UpdateAddresses);
   while GetLogLine('main',lastlogline) do Synchronize(@UpdateLog);
   Repeat
   until not GetDeepDebLine(lastlogline);

   if REF_Nodes then Synchronize(@UpdateNodes);
   if REF_Status then Synchronize(@UpdateStatus);
   if REF_GVTs then Synchronize(@UpdateGVTs);

   if UTCTime <> G_UTCTime then
      begin
      G_UTCTime := UTCTime;
      REF_Status := true;
      end;
   Sleep(1000);
   end;
End;

END. // END UNIT

