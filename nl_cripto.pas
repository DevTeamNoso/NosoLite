unit nl_cripto;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, nl_data, nl_signerutils, HlpHashFactory, Base64, nl_language,
  nl_GUI, nl_network, MD5, infoform, forms;

Function CreateNewAddress(keysData:string = ''):WalletData;
function GetAddressFromPublicKey(PubKey:String):String;
Function HashMD5File(FileToHash:String):String;
function HashSha256String(StringToHash:string):string;
function HashMD160String(StringToHash:string):String;
function GetStringSigned(StringtoSign, PrivateKey:String):String;
function VerifySignedString(StringToVerify,SignedHash,PublicKey:String):boolean;
Procedure ImportKeys(Keysline:String);
function SendTo(Destination:String;Ammount:int64;Reference:String):string;

// Big Maths
function ClearLeadingCeros(numero:string):string;
function BMAdicion(numero1,numero2:string):string;
Function PonerCeros(numero:String;cuantos:integer):string;
Function BMMultiplicar(Numero1,Numero2:string):string;
Function BMDividir(Numero1,Numero2:string):DivResult;
Function BMExponente(Numero1,Numero2:string):string;
function BMHexToDec(numerohex:string):string;
function BMHexTo58(numerohex:string;alphabetnumber:integer):string;
function BMB58resumen(numero58:string):string;
function BMDecTo58(numero:string):string;

implementation

Uses
  nl_functions, dialogs;

// Creates a new address
Function CreateNewAddress(keysData:string = ''):WalletData;
var
  MyData : WalletData;
  Address: String;
  KeysPair: TKeyPair;
Begin
if Keysdata = '' then KeysPair := TSignerUtils.GenerateECKeyPair(TKeyType.SECP256K1)
else
   begin
   KeysPair.PublicKey := Parameter(keysData,0);
   KeysPair.PrivateKey := Parameter(keysData,1);
   end;
Address := GetAddressFromPublicKey(KeysPair.PublicKey);
MyData.Hash:=Address;
Mydata.Custom:='';
Mydata.PublicKey:=KeysPair.PublicKey;
MyData.PrivateKey:=KeysPair.PrivateKey;
MyData.Balance:=0;
MyData.Pending:=0;
MyData.Score:=0;
MyData.LastOP:= 0;
Result := MyData;
End;

// Generates the public hash from the public key
function GetAddressFromPublicKey(PubKey:String):String;
var
  PubSHAHashed,Hash1,Hash2,clave:String;
  sumatoria : string;
Begin
PubSHAHashed := HashSha256String(PubKey);
Hash1 := HashMD160String(PubSHAHashed);
hash1 := BMHexTo58(Hash1,58);
sumatoria := BMB58resumen(Hash1);
clave := BMDecTo58(sumatoria);
hash2 := hash1+clave;
Result := 'N'+hash2;
End;

// Returns the MD5 hash of a file
Function HashMD5File(FileToHash:String):String;
Begin
result := UpperCase(MD5Print(MD5File(FileToHash)));
End;

// Returns the SHA256 of a estring
function HashSha256String(StringToHash:string):string;
Begin
result :=
THashFactory.TCrypto.CreateSHA2_256().ComputeString(StringToHash, TEncoding.UTF8).ToString();
End;

// Returns hash MD160 of a string
function HashMD160String(StringToHash:string):String;
Begin
result :=
THashFactory.TCrypto.CreateRIPEMD160().ComputeString(StringToHash, TEncoding.UTF8).ToString();
End;

// Returns the signature of a specified string
function GetStringSigned(StringtoSign, PrivateKey:String):String;
var
  Signature, MessageAsBytes: TBytes;
Begin
MessageAsBytes :=StrToByte(DecodeStringBase64(StringtoSign));
Signature := TSignerUtils.SignMessage(MessageAsBytes, StrToByte(DecodeStringBase64(PrivateKey)),
      TKeyType.SECP256K1);
Result := EncodeStringBase64(ByteToString(Signature));
End;

// Verify if a signed string is valid
function VerifySignedString(StringToVerify,SignedHash,PublicKey:String):boolean;
var
  Signature, MessageAsBytes: TBytes;
Begin
MessageAsBytes := StrToByte(DecodeStringBase64(StringToVerify));
Signature := StrToByte(DecodeStringBase64(SignedHash));
Result := TSignerUtils.VerifySignature(Signature, MessageAsBytes,
      StrToByte(DecodeStringBase64(PublicKey)), TKeyType.SECP256K1);
End;

// Process a keys import
Procedure ImportKeys(Keysline:String);
var
  PublicK, PrivateK : string;
  Signature : String;
  SignProcess : boolean = false;
Begin
PublicK := Parameter(Keysline,0);
PrivateK := Parameter(Keysline,1);
TRY
Signature := GetStringSigned('VERIFICATION',PrivateK);
SignProcess := VerifySignedString('VERIFICATION',signature,PublicK);
EXCEPT on E:Exception do
   begin
   ToLog(rsDIA0003);
   end;
END{Try};
if SignProcess then
   begin
   TryInsertAddress(CreateNewAddress(Keysline));
   end;
End;

// Process a coin sent
function SendTo(Destination:String;Ammount:int64;Reference:String):string;
var
  CurrTime : String;
  fee : int64;
  ShowAmmount, ShowFee : int64;
  Remaining : int64;
  CoinsAvailable : int64;
  KeepProcess : boolean = true;
  ArrayTrfrs : Array of orderdata;
  counter : integer;
  OrderHashString : string;
  TrxLine : integer = 0;
  ResultOrderID : String = '';
  OrderString : string;
  PreviousRefresh : integer;
Begin
PreviousRefresh := WO_Refreshrate;
result := '';
if reference = '' then reference := 'null';
CurrTime := UTCTime.ToString;
fee := GetFee(Ammount);
ShowAmmount := Ammount;
ShowFee := fee;
Remaining := Ammount+fee;
if WO_Multisend then CoinsAvailable := Int_WalletBalance
else CoinsAvailable := GetAddressBalanceFromSumary(ARRAY_Addresses[0].Hash);
if Remaining > CoinsAvailable then
      begin
      ToLog(rsError0012);
      KeepProcess := false;
      end;
if KeepProcess then
   begin
   Setlength(ArrayTrfrs,0);
   counter := 0;
   OrderHashString := currtime;
   while Ammount > 0 do
      begin
      if ARRAY_Addresses[counter].Balance-GetAddressPendingPays(ARRAY_Addresses[counter].Hash) > 0 then
         begin
         TrxLine := TrxLine+1;
         Setlength(ArrayTrfrs,length(arraytrfrs)+1);
         ArrayTrfrs[length(arraytrfrs)-1]:= SendFundsFromAddress(ARRAY_Addresses[counter].Hash,
                                            Destination,ammount, fee, reference, CurrTime,TrxLine);
         fee := fee-ArrayTrfrs[length(arraytrfrs)-1].AmmountFee;
         ammount := ammount-ArrayTrfrs[length(arraytrfrs)-1].AmmountTrf;
         OrderHashString := OrderHashString+ArrayTrfrs[length(arraytrfrs)-1].TrfrID;
         end;
      counter := counter +1;
      end;
   for counter := 0 to length(ArrayTrfrs)-1 do
      begin
      ArrayTrfrs[counter].OrderID:=GetOrderHash(IntToStr(trxLine)+OrderHashString);
      ArrayTrfrs[counter].OrderLines:=trxLine;
      end;
   ResultOrderID := GetOrderHash(IntToStr(trxLine)+OrderHashString);
   result := ResultOrderID;
   OrderString := GetPTCEcn('ORDER')+'ORDER '+IntToStr(trxLine)+' $';
   for counter := 0 to length(ArrayTrfrs)-1 do
      begin
      OrderString := orderstring+GetStringfromOrder(ArrayTrfrs[counter])+' $';
      end;
   Setlength(orderstring,length(orderstring)-2);
   //ToLog(OrderString);
   Result := SendOrder(OrderString);
   end;
WO_Refreshrate := PreviousRefresh;
End;

// *****************************************************************************
// ***************************FUNCTIONS OF BIGMATHS*****************************
// *****************************************************************************

// REMOVES LEFT CEROS
function ClearLeadingCeros(numero:string):string;
var
  count : integer = 0;
  movepos : integer = 0;
Begin
result := '';
if numero[1] = '-' then movepos := 1;
for count := 1+movepos to length(numero) do
   begin
   if numero[count] <> '0' then result := result + numero[count];
   if ((numero[count]='0') and (length(result)>0)) then result := result + numero[count];
   end;
if result = '' then result := '0';
if ((movepos=1) and (result <>'0')) then result := '-'+result;
End;

// ADDS 2 NUMBERS
function BMAdicion(numero1,numero2:string):string;
var
  longitude : integer = 0;
  count: integer = 0;
  carry : integer = 0;
  resultado : string = '';
  thiscol : integer;
  ceros : integer;
Begin
longitude := length(numero1);
if length(numero2)>longitude then
   begin
   longitude := length(numero2);
   ceros := length(numero2)-length(numero1);
   while count < ceros do
      begin
      numero1 := '0'+numero1;
      count := count+1;
      end;
   end
else
   begin
   ceros := length(numero1)-length(numero2);
      while count < ceros do
      begin
      numero2 := '0'+numero2;
      count := count+1;
      end;
   end;
for count := longitude downto 1 do
   Begin
   thiscol := StrToInt(numero1[count]) + StrToInt(numero2[count])+carry;
   carry := 0;
   if thiscol > 9 then
      begin
      thiscol := thiscol-10;
      carry := 1;
      end;
   resultado := inttoStr(thiscol)+resultado;
   end;
if carry > 0 then resultado := '1'+resultado;
result := resultado;
End;

// DRAW CEROS FOR MULTIPLICATION
Function PonerCeros(numero:String;cuantos:integer):string;
var
  contador : integer = 0;
  NewNumber : string;
Begin
NewNumber := numero;
while contador < cuantos do
   begin
   NewNumber := NewNumber+'0';
   contador := contador+1;
   end;
result := NewNumber;
End;

// MULTIPLIER
Function BMMultiplicar(Numero1,Numero2:string):string;
var
  count,count2 : integer;
  sumandos : array of string;
  thiscol : integer;
  carry: integer = 0;
  cantidaddeceros : integer = 0;
  TotalSuma : string = '0';
Begin
setlength(sumandos,length(numero2));
for count := length(numero2) downto 1 do
   begin
   for count2 := length(numero1) downto 1 do
      begin
      thiscol := (StrToInt(numero2[count]) * StrToInt(numero1[count2])+carry);
      carry := thiscol div 10;
      ThisCol := ThisCol - (carry*10);
      sumandos[cantidaddeceros] := IntToStr(thiscol)+ sumandos[cantidaddeceros];
      end;
   if carry > 0 then sumandos[cantidaddeceros] := IntToStr(carry)+sumandos[cantidaddeceros];
   carry := 0;
   sumandos[cantidaddeceros] := PonerCeros(sumandos[cantidaddeceros],cantidaddeceros);
   cantidaddeceros := cantidaddeceros+1;
   end;
for count := 0 to length(sumandos)-1 do
   TotalSuma := BMAdicion(Sumandos[count],totalsuma);
result := ClearLeadingCeros(TotalSuma);
End;

// DIVIDES TO NUMBERS
Function BMDividir(Numero1,Numero2:string):DivResult;
var
  counter : integer;
  cociente : string = '';
  long : integer;
  Divisor : Int64;
  ThisStep : String = '';
Begin
long := length(numero1);
Divisor := StrToInt64(numero2);
for counter := 1 to long do
   begin
   ThisStep := ThisStep + Numero1[counter];
   if StrToInt(ThisStep) >= Divisor then
      begin
      cociente := cociente+IntToStr(StrToInt(ThisStep) div Divisor);
      ThisStep := (IntToStr(StrToInt(ThisStep) mod Divisor));
      end
   else cociente := cociente+'0';
   end;
result.cociente := ClearLeadingCeros(cociente);
result.residuo := ClearLeadingCeros(thisstep);
End;

// CALCULATES A EXPONENTIAL NUMBER
Function BMExponente(Numero1,Numero2:string):string;
var
  count : integer = 0;
  resultado : string = '';
Begin
if numero2 = '1' then result := numero1
else if numero2 = '0' then result := '1'
else
   begin
   resultado := numero1;
   for count := 2 to StrToInt(numero2) do
      resultado := BMMultiplicar(resultado,numero1);
   result := resultado;
   end;
End;

// HEX TO DECIMAL
function BMHexToDec(numerohex:string):string;
var
  DecValues : array of integer;
  ExpValues : array of string;
  MultipliValues : array of string;
  counter : integer;
  Long : integer;
  Resultado : string = '0';
Begin
Long := length(numerohex);
numerohex := uppercase(numerohex);
setlength(DecValues,0);
setlength(ExpValues,0);
setlength(MultipliValues,0);
setlength(DecValues,Long);
setlength(ExpValues,Long);
setlength(MultipliValues,Long);
for counter := 1 to Long do
   DecValues[counter-1] := Pos(NumeroHex[counter],HexAlphabet)-1;
for counter := 1 to long do
   ExpValues[counter-1] := BMExponente('16',IntToStr(long-counter));
for counter := 1 to Long do
   MultipliValues[counter-1] := BMMultiplicar(ExpValues[counter-1],IntToStr(DecValues[counter-1]));
for counter := 1 to long do
   Resultado := BMAdicion(resultado,MultipliValues[counter-1]);
result := resultado;
End;

// Hex a base 58
function BMHexTo58(numerohex:string;alphabetnumber:integer):string;
var
  decimalvalue : string;
  restante : integer;
  ResultadoDiv : DivResult;
  Resultado : string = '';
  AlpahbetUsed : String;
Begin
AlpahbetUsed := B58Alphabet;
if alphabetnumber=36 then AlpahbetUsed := B36Alphabet;
decimalvalue := BMHexToDec(numerohex);
while length(decimalvalue) >= 2 do
   begin
   ResultadoDiv := BMDividir(decimalvalue,IntToStr(alphabetnumber));
   DecimalValue := Resultadodiv.cociente;
   restante := StrToInt(ResultadoDiv.residuo);
   resultado := AlpahbetUsed[restante+1]+resultado;
   end;
if StrToInt(decimalValue) >= alphabetnumber then
   begin
   ResultadoDiv := BMDividir(decimalvalue,IntToStr(alphabetnumber));
   DecimalValue := Resultadodiv.cociente;
   restante := StrToInt(ResultadoDiv.residuo);
   resultado := AlpahbetUsed[restante+1]+resultado;
   end;
if StrToInt(decimalvalue) > 0 then resultado := AlpahbetUsed[StrToInt(decimalvalue)+1]+resultado;
result := resultado;
End;

// RETURN THE SUMATORY OF A BASE58
function BMB58resumen(numero58:string):string;
var
  counter, total : integer;
Begin
total := 0;
for counter := 1 to length(numero58) do
   begin
   total := total+Pos(numero58[counter],B58Alphabet)-1;
   end;
result := IntToStr(total);
End;

// CONVERTS A DECIMAL VALUE TO A BASE58 STRING
function BMDecTo58(numero:string):string;
var
  decimalvalue : string;
  restante : integer;
  ResultadoDiv : DivResult;
  Resultado : string = '';
Begin
decimalvalue := numero;
while length(decimalvalue) >= 2 do
   begin
   ResultadoDiv := BMDividir(decimalvalue,'58');
   DecimalValue := Resultadodiv.cociente;
   restante := StrToInt(ResultadoDiv.residuo);
   resultado := B58Alphabet[restante+1]+resultado;
   end;
if StrToInt(decimalValue) >= 58 then
   begin
   ResultadoDiv := BMDividir(decimalvalue,'58');
   DecimalValue := Resultadodiv.cociente;
   restante := StrToInt(ResultadoDiv.residuo);
   resultado := B58Alphabet[restante+1]+resultado;
   end;
if StrToInt(decimalvalue) > 0 then resultado := B58Alphabet[StrToInt(decimalvalue)+1]+resultado;
result := resultado;
End;

End. // END UNIT

