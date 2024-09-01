unit splashform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, LCLIntf,
  LCLType, StdCtrls;

type

  { TForm4 }

  TForm4 = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    LabelSplash: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure LabelSplashClick(Sender: TObject);
  private

  public

  end;

var
  Form4: TForm4;

implementation

uses
  nl_data;

{$R *.lfm}

{ TForm4 }

procedure TForm4.FormCreate(Sender: TObject);
var
  MyRegion: HRGN;
begin
MyRegion := CreateEllipticRgn(10, 10, 310, 310);
SetWindowRgn(Handle, MyRegion, True);
Label1.Caption:='Nosolite v'+ProgramVersion;
end;

procedure TForm4.LabelSplashClick(Sender: TObject);
begin

end;

END. // END UNIT

