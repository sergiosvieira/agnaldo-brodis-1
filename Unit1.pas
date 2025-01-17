{
  PROGRAMANDO JOGOS - AGNALDO BRODIS
  OPEN SOURCE - DISTRIBUA LIVREMENTE. MANTENHA OS CR�DITOS
  DO AUTOR.
  AUTOR: ANTONIO S�RGIO DE SOUSA VIEIRA 2002
  AGRADECIMENTOS: FABR�CIO CATAE
  BRASIL - FORTALEZA - CE
  http://www15.brinkster.com/djddelphi
}

unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, StdCtrls;

type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    Iniciar1: TMenuItem;
    sergiosvieiraigcombr1: TMenuItem;
    procedure Iniciar1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
  TSentidoX = (Esquerda,Direita,Parado);
  TSentidoY = (Cima,Baixo);
  TBloco = Record
    BRect: TRect;
    Index: Integer;
    Solido: Boolean;
  end;
  TAgnaldo = Record
    PosX,PosY: Integer;
    ImgMascara: TBitmap;
    Frame: Integer;
    FXX: Integer;
    Visivel: Boolean;
    SentidoX: TSentidoX;
    SentidoY: TSentidoY;
    Pulo: Boolean;
    Veloc: Integer;
    Acele: Integer;
  end;
  TCoordenada = Record
    x,y: Integer;
  end;
  TCamera = Record
    PosX: Integer;
    PosY: Integer;
    Sentido: TSentidoX;
    Travada: Boolean;
  end;

const
  COL = 200;
  LIN = 8;
  TAM = 16;
  POT = 4;
  LAR = 320;
  ALT = 240;

var
  Form1: TForm1;
  cnjBlocos: array[0..COL,0..LIN] of TBloco;
  Blocos: array[0..5] of TBitmap;
  OFFScr: TBitmap;
  Imagem, Mascara: TBitmap;
  Mario: TAgnaldo;
  Res: TBitmap;
  Camera: TBitmap;
  Cam: TCamera;
  A,B,C,D: TCoordenada;
implementation

{$R *.dfm}

procedure TForm1.Iniciar1Click(Sender: TObject);
{ CAMERA }
procedure Desenhar_Camera;
begin
  BitBlt(Camera.Canvas.Handle,0,0,LAR,ALT,
         OFFScr.Canvas.Handle, Cam.PosX, Cam.PosY,SrcCopy);
end;
procedure Mover_Camera;
begin
  Cam.PosX:= Mario.PosX - LAR div 4;

  if Cam.PosX <= 0 then
     Cam.PosX:= 0
  else
     if Cam.PosX + LAR >= OFFScr.Width then
        Cam.PosX:= OFFScr.Width - LAR;
end;

procedure Carregar_Imagens(Nome: String);
var i: Integer;
    Bmp: TBitmap;
begin
  Bmp:= TBitmap.Create;
  Bmp.LoadFromFile(Nome);
  for i:= 0 to 5 do
      begin
        Blocos[i] := TBitmap.Create;
        Blocos[i].Width:= TAM;
        Blocos[i].Height:= TAM;
        BitBlt(Blocos[i].Canvas.Handle,0,0,TAM,TAM,
               Bmp.Canvas.Handle,(i * TAM) + 1,1,SrcCopy);
      end;
  Bmp.Free;
end;
procedure Carregar_Mapa(Nome: String);
var Arquivo: TextFile;
    x,y,i: Integer;
    Temp: Char;
begin
  x:=0;y:=0;
  i:=0;
  AssignFile(Arquivo,Nome);
  Reset(Arquivo);
  while not EOF(Arquivo) do
        begin
          Read(Arquivo,Temp);

          Case Temp of
            #13: Temp:= #48;
            #10: Temp:= #48;
            else
              begin
                i:= strtoint(Temp);
                cnjBlocos[x,y].BRect := Rect(x shl POT,y shl POT,
                                            (x shl POT) + TAM,
                                            (y shl POT) + TAM);
                cnjBlocos[x,y].Index := i;
                if (i>0) and (i<10) then
                   cnjBlocos[x,y].Solido:= True;
                if i = 0 then
                   cnjBlocos[x,y].Solido:= False;
                if x = COL - 1 then
                   begin
                     x:=0;
                     inc(y);
                   end
                else
                   Inc(x);
              end;
          end;
        end;
  CloseFile(Arquivo);
end;
procedure Desenhar_Blocos(IX,FX: Integer);
var x,y,i: Integer;
begin
  for x:= IX to FX  do
      for y:= 0 to LIN  do
          with cnjBlocos[x,y] do
          begin
            OFFScr.Canvas.Draw(BRect.Left - 1,BRect.Top - 1,Blocos[cnjBlocos[x,y].Index]);
          end;
end;
{ AGNALDO }
procedure Criar_Imagem(Nome: String);
begin
  Imagem:= TBitmap.Create;
  Imagem.LoadFromFile(Nome);

  Mascara:= TBitmap.Create;
  Mascara.Assign(Imagem);
  Mascara.Mask(RGB(255,0,255));

  Mario.ImgMascara:= TBitmap.Create;
  Mario.ImgMascara.Width := Imagem.Width;
  Mario.ImgMascara.Height:= Imagem.Height;

  BitBlt(Mario.ImgMascara.Canvas.Handle, 0, 0, Imagem.Width, Imagem.Height,
         Mascara.Canvas.Handle, 0, 0, SrcCopy);
  BitBlt(Mario.ImgMascara.Canvas.Handle, 0, 0, Imagem.Width, Imagem.Height,
         Imagem.Canvas.Handle, 0, 0, SrcErase);

  Canvas.Draw(0,200,Mario.ImgMascara);
end;
procedure Desenhar_Mario(x,y,NFRAME,Repete: Integer);
begin
with Mario do
begin
 if Visivel then
    begin
      if Frame > NFRAME then
         Frame := 0;

      if Mario.SentidoX = Parado then
         Frame:= 0;

      if Mario.SentidoY = Cima then
         Frame:= 5
      else
         if Mario.Veloc < 0 then
            Frame:= 5;


         BitBlt(OFFScr.Canvas.Handle,x,y,17,17,Mascara.Canvas.Handle,
                Frame * 17,0,SrcAnd);
         BitBlt(OFFScr.Canvas.Handle,x,y,17,17,ImgMascara.Canvas.Handle,
                Frame * 17,0,SrcInvert);

      if FXX = Repete then
         begin
           if (Mario.SentidoX<>Parado) then
           Inc(Frame);
           FXX := 0;
         end
      else
         if (Mario.SentidoX<>Parado) then
         Inc(FXX);
    end;


{  if Frame > NFRAME then
     Frame := 0;

  BitBlt(OFFScr.Canvas.Handle,x,y,16,16,Mascara.Canvas.Handle,
         (Frame * 16) + 1,0,SrcAnd);
  BitBlt(OFFScr.Canvas.Handle,x,y,16,16,ImgMascara.Canvas.Handle,
         (Frame * 16) + 1,0,SrcInvert);
  if Mario.SentidoX <> Parado then
     inc(Frame);
  }
end;
end;
{ FUN��ES}
procedure Detectar_Bloco(x,y: Integer);
begin
  // PONTOS DA COLIS�O PELA DIREITA
  B.x:= (x + 1 shl POT) div (1 shl POT);
  B.y:= y div (1 shl POT);

  D.x:= (x + 1 shl POT) div (1 shl POT);
  D.y:= (y + 1 shl POT) div (1 shl POT);

  // PONTOS DA COLIS�O PELA ESQUERDA
  A.x:= x div (1 shl POT);
  A.y:= y div (1 shl POT);

  C.x:= x div (1 shl POT);
  C.y:= (y + 1 shl POT) div (1 shl POT);
end;

{ TECLADO }
procedure Ler_Teclado;
begin
  if GetKeyState(vk_left)<0 then
     Mario.SentidoX:= Esquerda
  else
     if GetKeyState(vk_right)<0 then
        Mario.SentidoX:= Direita
     else
        Mario.SentidoX:= Parado;

end;
procedure Mover_Mario(x,y,Velocidade: Integer);
var NovoXX,NovoXY: Integer;
    NovoYX,NovoYY: Integer;
begin
  if Mario.SentidoX = Esquerda then
     begin
       NovoXX:= Mario.PosX - Velocidade;
       NovoXY:= Mario.PosY;
       Detectar_Bloco(NovoXX,NovoXY);
       if cnjBlocos[A.x,A.y].Solido then
          begin
            NovoXX:= cnjBlocos[A.x,A.y].BRect.Right + 1;
          end
       else
          if cnjBlocos[c.x,c.y].Solido then
             begin
               NovoXX:= cnjBlocos[c.x,c.y].BRect.Right + 1;
             end;
       if NovoXX<0 then
          NovoXX:=0;

       Mario.PosX:= NovoXX;
       Mario.PosY:= NovoXY;
     end
  else
     if Mario.SentidoX = Direita then
        begin
          NovoXX:= Mario.PosX + Velocidade;
          NovoXY:= Mario.PosY;
          Detectar_Bloco(NovoXX,NovoXY);
          if cnjBlocos[B.x,B.y].Solido then
             begin
               NovoXX:= cnjBlocos[B.x,B.y].BRect.Left - TAM - 1;
             end
          else
             if cnjBlocos[D.x,D.y].Solido then
                begin
                  NovoXX:= cnjBlocos[D.x,D.y].BRect.Left - TAM - 1;
                end;

          if NovoXX+TAM>OFFScr.Width then
             NovoXX:= OFFScr.Width - TAM;

          Mario.PosX:= NovoXX;
          Mario.PosY:= NovoXY;
        end
     else
        Mario.SentidoX:= Parado;
end;
procedure Checar_Pulo;
begin
  if GetKeyState(vk_control)<0 then
     begin
       Mario.Pulo:= True;
       Mario.Veloc:= 13;
     end;
end;
procedure Pular(Repete: Integer);
var NovoYX,NovoYY: Integer;
begin
  if Mario.Pulo then
     begin

       Dec(Mario.Veloc,Mario.Acele);
       Dec(Mario.PosY,Mario.Veloc);

       if Mario.Veloc < -6 then
          Mario.Veloc:= -6;
       //OFFScr.Canvas.TextOut(Cam.PosX,0,'TRUE');
     end;
//  else
//     OFFScr.Canvas.TextOut(Cam.PosX,0,'FALSE');

  if Mario.Veloc > 0 then
     Mario.SentidoY := Cima
  else
     if Mario.Veloc < 0 then
        Mario.SentidoY := Baixo;

  if Mario.PosY>OFFScr.Height then
     begin
       Mario.Pulo:= True;
       ShowMessage('GAME OVER');
       Mario.PosX:= 0;
       Mario.PosY:= 0;
     end;

        if Mario.SentidoY = Cima then
           begin
             //OFFScr.Canvas.TextOut(Cam.PosX,30,'Cima');
             NovoYX:= Mario.PosX;
             NovoYY:= Mario.PosY;
             Detectar_Bloco(NovoYX,NovoYY);

             if cnjBlocos[A.x,A.y].Solido then
                begin
                  NovoYY:= cnjBlocos[A.x,A.y].BRect.Top + TAM + 1;
                end
             else
                if cnjBlocos[B.x,B.y].Solido then
                   begin
                     NovoYY:= cnjBlocos[B.x,B.y].BRect.Top + TAM + 1;
                   end;

             if NovoYY<0 then
                NovoYY:= 0;

                  Mario.PosX:= NovoYX;
                  Mario.PosY:= NovoYY;
           end
        else
           if Mario.SentidoY = Baixo then
              begin
                //OFFScreen.Canvas.TextOut(Cam.PosX,30,'Baixo');

                NovoYY:= Mario.PosY;
                NovoYX:= Mario.PosX;
                Detectar_Bloco(NovoYX,NovoYY);

                if cnjBlocos[C.x,C.y].Solido then
                   begin
                     NovoYY:= cnjBlocos[C.x,C.y].BRect.Top - TAM - 1;
                     Mario.Veloc:= 0;
                     Mario.Pulo:= False;
                   end
                else
                   if cnjBlocos[D.x,D.y].Solido then
                      begin
                        NovoYY:= cnjBlocos[D.x,D.y].BRect.Top - TAM - 1;
                        Mario.Veloc:= 0;
                        Mario.Pulo:= False;
                      end
                   else
                      if Mario.SentidoX <> Parado then Mario.Pulo:= True;

                Mario.PosX:= NovoYX;
                Mario.PosY:= NovoYY;
              end;

  Sleep(15);
end;
procedure ChangeMode;
const
  ENUM_CURRENT_SETTINGS = Cardinal(-1);
  ENUM_REGISTRY_SETTINGS = Cardinal(-2);
var
  D: TDevMode;
  FLastMode : TDevMOde;
begin
  if not EnumDisplaySettings(nil, ENUM_REGISTRY_SETTINGS, FLastMode) then begin
    ShowMessage('N�o consegui pegar as configura��es atuais do v�deo. N�o vou mudar de modo');
  end else begin
    FillChar(D, SizeOf(TDevMode), 0);
    D.dmSize := SizeOf(TDevMode);
    D.dmPelsWidth := 320;
    D.dmPelsHeight := 240;
    D.dmBitsPerPel := 16;
    D.dmFields := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
    if ChangeDisplaySettings(D, CDS_FULLSCREEN) <> DISP_CHANGE_SUCCESSFUL then begin
      ShowMessage('N�o consegui mudar o modo de v�deo...');
    end;
  end;
end;
var i: Integer;
begin
  //BorderStyle:= bsNone;
  Color := ClBlack;
  Canvas.Font.Color := clWhite;
  //WindowState := wsMaximized;
  //MainMenu1.AutoMerge := True;
  //ChangeMode;
  Carregar_Imagens('001.bmp');
  Carregar_Mapa('Fase1.txt');
  Criar_Imagem('Agnaldo.bmp');
  while not Application.Terminated do
  begin
    Desenhar_Blocos(Cam.PosX div TAM,(Cam.PosX div TAM) + 10);
    Ler_Teclado;
    if not Mario.Pulo then
       Checar_Pulo;
    Pular(5);
    Mover_Mario(Mario.PosX, Mario.PosY, 3);
    Desenhar_Mario(Mario.PosX,Mario.PosY,4,3);
    Desenhar_Camera;
    Mover_Camera;

    //Canvas.Draw(0,0,OFFScr);
    StretchBlt(Res.Canvas.Handle,0,0,320,240,
       Camera.Canvas.Handle,0,0,160,120,SrcCopy);
    Canvas.Draw(0,0,Res);
    Application.ProcessMessages;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin

  OFFScr:= TBitmap.Create;
  OFFScr.Width:= COL * TAM;
  OFFScr.Height:= LIN * TAM;

  Res:= TBitmap.Create;
  Res.Width:= 320;
  Res.Height:= 240;

  Camera:= TBitmap.Create;
  Camera.Width:= LAR;
  Camera.Height:= ALT;

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  OFFScr.Free;
end;
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
procedure ChangeMode2;
const
  ENUM_CURRENT_SETTINGS = Cardinal(-1);
  ENUM_REGISTRY_SETTINGS = Cardinal(-2);
var
  D: TDevMode;
  FLastMode : TDevMOde;
begin
{  if not EnumDisplaySettings(nil, ENUM_REGISTRY_SETTINGS, FLastMode) then begin
    ShowMessage('N�o consegui pegar as configura��es atuais do v�deo. N�o vou mudar de modo');
  end else begin
    FillChar(D, SizeOf(TDevMode), 0);
    D.dmSize := SizeOf(TDevMode);
    D.dmPelsWidth := 800;
    D.dmPelsHeight := 600;
    D.dmBitsPerPel := 16;
    D.dmFields := DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
    if ChangeDisplaySettings(D, CDS_FULLSCREEN) <> DISP_CHANGE_SUCCESSFUL then begin
      ShowMessage('N�o consegui mudar o modo de v�deo...');
    end;
  end;}
end;

begin
  ShowMessage('EathSun Games');
  ChangeMode2;
end;

initialization
  Cam.PosX:= 0;
  Cam.PosY:= 0;
  Cam.Travada:= False;


  Mario.Frame:=0;
  Mario.PosX:= 1;
  Mario.PosY:= 40;
  Mario.Acele:= 1;
  Mario.Pulo:= True;
  Mario.SentidoY:= Baixo;
  Mario.Pulo:= True;
  Mario.Visivel:= True;
  Mario.FXX:= 0;

end.

