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
  TensorFlowLiteFMX
  ;

const
  FaceNetInputSize = 112;
  FaceNetOutputSize = 256;

type
  PInputDataFaceNet = ^TInputDataFaceNet;
  TInputDataFaceNet = array [0 .. FaceNetInputSize - 1] of array [0 .. FaceNetInputSize - 1] of array [0 .. 3 - 1] of Float32;

type
  POutputDataFaceNet = ^TOutputDataFaceNet;
  TOutputDataFaceNet = array [0 .. FaceNetOutputSize - 1] of Float32;

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
    FFaceNet: TTensorFlowLiteFMX;
    function CreateFaceEmbedding(inFaceImage: TImage; var outFaceEmbedding: TOutputDataFaceNet): Boolean;
    { Private declarations }
  public
    procedure LoadImage(FileName: String; var Image: TImage);
  end;

var
  frmFaceRecognition: TfrmFaceRecognition;

implementation

{$R *.fmx}

const
  ModelsPath = '..\..\..\..\..\models\';

procedure TfrmFaceRecognition.LoadImage(FileName: String; var Image: TImage);
begin
{$IFDEF MSWINDOWS}
  if not FileExists(FileName) then
    Exit;

  if Image.MultiResBitmap.Count > 0 then
    Image.MultiResBitmap[0].Free;

  Image.MultiResBitmap.Add;

  if FileExists(OpenDialog.FileName) then
  begin
    if ImageList.Source[0].MultiResBitmap.Count > 0 then
      ImageList.Source[0].MultiResBitmap[0].Free;

    ImageList.Source[0].MultiResBitmap.Add;
    ImageList.Source[0].MultiResBitmap[0].Bitmap.LoadFromFile(OpenDialog.FileName);
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

function TfrmFaceRecognition.CreateFaceEmbedding(inFaceImage: TImage; var outFaceEmbedding: TOutputDataFaceNet): Boolean;
var
  Y: Cardinal;
  X: Cardinal;
  LColors: PAlphaColorArray;
  LInputData: PInputDataFaceNet;
  LBitmapData: TBitmapData;
begin
  Result := False;
  // ImageA
  if (inFaceImage.Bitmap.Map(TMapAccess.ReadWrite, LBitmapData)) then
  begin
    GetMem(LInputData, FFaceNet.Input.Tensors[0].DataSize);
    try
      for Y := 0 to FaceNetInputSize - 1 do
      begin
        LColors := PAlphaColorArray(LBitmapData.GetScanline(Y));
        for X := 0 to FaceNetInputSize - 1 do
        begin
          LInputData[Y][X][0] := (TAlphaColorRec(LColors[X]).R / 255);
          LInputData[Y][X][1] := (TAlphaColorRec(LColors[X]).G / 255);
          LInputData[Y][X][2] := (TAlphaColorRec(LColors[X]).B / 255);
        end;
      end;
      FFaceNet.SetInputData(0, LInputData, FFaceNet.Input.Tensors[0].DataSize);
    finally
      FreeMem(LInputData);
    end;
    FFaceNet.Inference;
    FFaceNet.GetOutputData(0, @outFaceEmbedding, FFaceNet.Output.Tensors[0].DataSize);
    Result := True;
  end;
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
  i, X, Y: DWORD;
  LFaceEmbeddingA, LFaceEmbeddingB: TOutputDataFaceNet;
  LEmbedded: Float32;
begin
  LEmbedded := 0;
  CreateFaceEmbedding(ImageA, LFaceEmbeddingA);
  CreateFaceEmbedding(ImageB, LFaceEmbeddingB);

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

  FFaceNet := TTensorFlowLiteFMX.Create(Self);

  // Currently Tensor Flow Lite for Windows supports only x64 CPU, GPU is not supported

  FFaceNet.LoadModel(ModelsPath + 'face_recognition.tflite', 8);

{$ENDIF}
end;

procedure TfrmFaceRecognition.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FFaceNet);
end;

end.
