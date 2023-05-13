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
  FaceRecognitionFMX
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
    procedure FormCreate(Sender: TObject);
    procedure btnOpenFileImageAClick(Sender: TObject);
    procedure btnCompareAandBImageClick(Sender: TObject);
    procedure btnOpenFileImageBClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
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

procedure TfrmFaceRecognition.btnCompareAandBImageClick(Sender: TObject);
var
  i: DWORD;
  LFaceEmbeddingA, LFaceEmbeddingB: TOutputDataFaceNet;
  LEmbedded: Float32;
begin
  LEmbedded := 0;
  FFaceRec.CreateFaceEmbedding(ImageA, LFaceEmbeddingA);
  FFaceRec.CreateFaceEmbedding(ImageB, LFaceEmbeddingB);

    for i := 0 to FaceNetOutputSize - 1 do
      LFaceEmbeddingB[i] := (LFaceEmbeddingB[i]) - (LFaceEmbeddingA[i]);

    LEmbedded := System.Math.Norm(LFaceEmbeddingB);

    if LEmbedded < 0.41 then
      lblDetectionInfo.Text := 'Same Person: TRUE, Distance: ' + FloatToStr(LEmbedded)
    else
      lblDetectionInfo.Text := 'Same Person: FALSE, Distance: ' + FloatToStr(LEmbedded);
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
