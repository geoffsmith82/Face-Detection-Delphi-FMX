unit ufrmFaceRecognition;

interface

uses
{$IFDEF MSWINDOWS}
  WinApi.Windows,
  Vcl.Graphics,
{$ENDIF}
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.IOUtils,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Utils,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Objects,
  System.ImageList,
  System.Math,
  FMX.ImgList,
  FMX.ScrollBox,
  FMX.Memo,
  FMX.ListBox,
  FMX.Filter.Effects,
  FMX.Edit,
  FMX.ComboEdit,
  FMX.Memo.Types,
  TensorFlowLiteFMX,
  FaceRecognitionFMX,
  FireDAC.Phys.PGDef,
  FireDAC.Stan.Intf,
  FireDAC.Phys,
  FireDAC.Phys.PG,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.FMXUI.Wait,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  Data.DB
  ;

type
  TfrmFaceRecognition = class(TForm)
    OpenDialog: TOpenDialog;
    ImageList: TImageList;
    ImageA: TImage;
    ImageB: TImage;
    btnOpenFileImageA: TButton;
    btnOpenFileImageB: TButton;
    btnCompareAandBImage: TButton;
    Memo1: TMemo;
    Memo2: TMemo;
    lblDetectionInfo: TLabel;
    Label1: TLabel;
    PhysPgDriverLink: TFDPhysPgDriverLink;
    EmbeddingConnection: TFDConnection;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnOpenFileImageAClick(Sender: TObject);
    procedure btnCompareAandBImageClick(Sender: TObject);
    procedure btnOpenFileImageBClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FFaceRec : TFaceRecognition;
  public
    procedure LoadImage(FileName: String; var Image: TImage);
  end;

var
  frmFaceRecognition: TfrmFaceRecognition;

implementation

{$R *.fmx}


procedure TfrmFaceRecognition.LoadImage(FileName: String; var Image: TImage);
begin
{$IFDEF MSWINDOWS}
  if not FileExists(FileName) then
    Exit;

  if Image.MultiResBitmap.Count > 0 then
    Image.MultiResBitmap[0].Free;

  Image.MultiResBitmap.Add;

  if FileExists(FileName) then
  begin
    if ImageList.Source[0].MultiResBitmap.Count > 0 then
      ImageList.Source[0].MultiResBitmap[0].Free;

    ImageList.Source[0].MultiResBitmap.Add;
    ImageList.Source[0].MultiResBitmap[0].Bitmap.LoadFromFile(FileName);
  end;

  if ImageList.Source[1].MultiResBitmap.Count > 0 then
    ImageList.Source[1].MultiResBitmap[0].Free;

  ImageList.Source[1].MultiResBitmap.Add;
  ImageList.Source[1].MultiResBitmap[0].Bitmap.Width := FaceNetInputSize;
  ImageList.Source[1].MultiResBitmap[0].Bitmap.Height := FaceNetInputSize;

  ImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.BeginScene;
  try
    ImageList.Source[0].MultiResBitmap[0].Bitmap.Canvas.BeginScene;
    try
      ImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.Clear(TAlphaColorRec.White);

      if ImageList.Source[0].MultiResBitmap[0].Bitmap.Width > ImageList.Source[0].MultiResBitmap[0].Bitmap.Height then
      begin
        ImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.DrawBitmap(
          ImageList.Source[0].MultiResBitmap[0].Bitmap,
          ImageList.Source[0].MultiResBitmap[0].Bitmap.BoundsF,
          RectF(0, 0, FaceNetInputSize, ImageList.Source[0].MultiResBitmap[0].Bitmap.Height / (ImageList.Source[0].MultiResBitmap[0].Bitmap.Width / FaceNetInputSize)),
          1, False);
      end
      else
      begin
        ImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.DrawBitmap(
          ImageList.Source[0].MultiResBitmap[0].Bitmap,
          ImageList.Source[0].MultiResBitmap[0].Bitmap.BoundsF,
          RectF(0, 0, ImageList.Source[0].MultiResBitmap[0].Bitmap.Width / (ImageList.Source[0].MultiResBitmap[0].Bitmap.Height / FaceNetInputSize), FaceNetInputSize),
          1, False);
      end;

    finally
      ImageList.Source[0].MultiResBitmap[0].Bitmap.Canvas.EndScene;
    end;
  finally
    ImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.EndScene;
  end;

  Image.Bitmap.Assign(ImageList.Source[1].MultiResBitmap[0].Bitmap);

{$ENDIF MSWINDOWS}
end;


procedure TfrmFaceRecognition.btnOpenFileImageAClick(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  OpenDialog.Execute;

  LoadImage(OpenDialog.FileName, ImageA);
{$ENDIF MSWINDOWS}
end;

procedure TfrmFaceRecognition.btnOpenFileImageBClick(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  OpenDialog.Execute;

  LoadImage(OpenDialog.FileName, ImageB);
{$ENDIF MSWINDOWS}
end;

procedure TfrmFaceRecognition.Button1Click(Sender: TObject);
var
  query : TFDQuery;
  filenames : TArray<string>;
  i, j: Integer;
  ImageA : TImage;
  LFaceEmbeddingA, LFaceEmbeddingB, LFaceEmbeddingC: TOutputDataFaceNet;
begin
  query := TFDQuery.Create(nil);
  try
    query.Connection := EmbeddingConnection;
    filenames := TDirectory.GetFiles('D:\Programming\ADUG\Symposium2023\Libs\FaceRecognition\Face-Detection-Delphi-FMX\examples\windows\face-recognition\Win64\Release\images\', '*.jpg');

    for i := 0 to High(filenames) do
    begin
      ImageA := TImage.Create(nil);
      try
        ImageA.Bitmap := TBitmap.Create;
        ImageA.Bitmap.LoadFromFile(filenames[i]);
        FFaceRec.CreateFaceEmbedding(ImageA, LFaceEmbeddingA);
        var vectorStr : string := '[';
        vectorStr := vectorStr + LFaceEmbeddingA[0].ToString + ', ';
        for j := 1 to High(LFaceEmbeddingA)  do
        begin
          vectorStr := vectorStr + LFaceEmbeddingA[j].ToString + ', ';
        end;
        vectorStr := vectorStr.TrimRight;
        vectorStr := vectorStr.TrimRight([',']);
        vectorStr := vectorStr + ']';
        query.SQL.Text := 'INSERT INTO "PeopleEmbeddings" (filename, embedding) VALUES(:file, cast(:vect as VECTOR));';
        query.ParamByName('file').AsString := ExtractFilename(filenames[i]);
        query.ParamByName('vect').Size := 10000;
        query.ParamByName('vect').AsString := vectorStr;
        query.ExecSQL;

      finally
        FreeAndNil(ImageA);
      end;
    end;
  finally
    FreeAndNil(query);
  end;
end;

function CosineDistance(const Vector1, Vector2: TOutputDataFaceNet): Double;
var
  DotProduct, Magnitude1, Magnitude2: Double;
  i: Integer;
begin
  DotProduct := 0;
  Magnitude1 := 0;
  Magnitude2 := 0;

  // Calculate dot product and magnitudes
  for i := 0 to Length(Vector1) - 1 do
  begin
    DotProduct := DotProduct + (Vector1[i] * Vector2[i]);
    Magnitude1 := Magnitude1 + Sqr(Vector1[i]);
    Magnitude2 := Magnitude2 + Sqr(Vector2[i]);
  end;

  Magnitude1 := Sqrt(Magnitude1);
  Magnitude2 := Sqrt(Magnitude2);

  // Calculate cosine distance
  Result := 1 - (DotProduct / (Magnitude1 * Magnitude2));
end;


procedure ConvertToUnitVector(var arr: TOutputDataFaceNet);
var
  i: Integer;
  magnitude: Double;
begin
  // Calculate the magnitude
  magnitude := 0.0;
  for i := 0 to Length(arr) - 1 do
    magnitude := magnitude + Sqr(arr[i]);
  magnitude := Sqrt(magnitude);

  // Divide each component by the magnitude
  for i := 0 to Length(arr) - 1 do
    arr[i] := arr[i] / magnitude;
end;


procedure TfrmFaceRecognition.btnCompareAandBImageClick(Sender: TObject);
var
  i: DWORD;
  LFaceEmbeddingA, LFaceEmbeddingB, LFaceEmbeddingC: TOutputDataFaceNet;
  LFaceEmbeddingA1, LFaceEmbeddingB1: TOutputDataFaceNet;
  LEmbedded: Float32;
begin
  LEmbedded := 0;
  FFaceRec.CreateFaceEmbedding(ImageA, LFaceEmbeddingA);
  FFaceRec.CreateFaceEmbedding(ImageB, LFaceEmbeddingB);

  for i := 0 to FaceNetOutputSize - 1 do
  begin
    LFaceEmbeddingA1[i] := LFaceEmbeddingA[i];
    LFaceEmbeddingB1[i] := LFaceEmbeddingB[i];
  end;
  ConvertToUnitVector(LFaceEmbeddingA1);
  ConvertToUnitVector(LFaceEmbeddingB1);


  for i := 0 to FaceNetOutputSize - 1 do
    LFaceEmbeddingC[i] := (LFaceEmbeddingB[i]) - (LFaceEmbeddingA[i]);

  LEmbedded := System.Math.Norm(LFaceEmbeddingC);

  if LEmbedded < 0.41 then
    lblDetectionInfo.Text := 'Same Person: TRUE, Distance: ' + FloatToStr(LEmbedded)
  else
    lblDetectionInfo.Text := 'Same Person: FALSE, Distance: ' + FloatToStr(LEmbedded);

  Label1.Text := 'Cosine ' + FloatToStr(CosineDistance(LFaceEmbeddingA1, LFaceEmbeddingB1));
end;

procedure TfrmFaceRecognition.FormCreate(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  SetPriorityClass(GetCurrentProcess, HIGH_PRIORITY_CLASS);
  FFaceRec := TFaceRecognition.Create;

{$ENDIF}
end;

procedure TfrmFaceRecognition.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FFaceRec);
end;
end.
