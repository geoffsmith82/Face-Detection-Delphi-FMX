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
  FMX.Memo.Types
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
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Memo1: TMemo;
    Memo2: TMemo;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    function CreateFaceEmbedding(inFaceImage: TImage; var outFaceEmbedding: TOutputDataFaceNet): Boolean;
    { Private declarations }
  public
    procedure LoadImage(FileName: String; var Image: TImage);
  end;

var
  frmFaceRecognition: TfrmFaceRecognition;

implementation

{$R *.fmx}


uses TensorFlowLiteFMX;

const
  ModelsPath = '..\..\..\..\..\models\';

var
  FaceNet: TTensorFlowLiteFMX;

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
    GetMem(LInputData, FaceNet.Input.Tensors[0].DataSize);
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
      FaceNet.SetInputData(0, LInputData, FaceNet.Input.Tensors[0].DataSize);
    finally
      FreeMem(LInputData);
    end;
    FaceNet.Inference;
    FaceNet.GetOutputData(0, @outFaceEmbedding, FaceNet.Output.Tensors[0].DataSize);
    Result := True;
  end;
end;

procedure TfrmFaceRecognition.Button1Click(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  OpenDialog.Execute;

  LoadImage(OpenDialog.FileName, ImageA);
{$ENDIF MSWINDOWS}
end;

procedure TfrmFaceRecognition.Button2Click(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  OpenDialog.Execute;

  LoadImage(OpenDialog.FileName, ImageB);
{$ENDIF MSWINDOWS}
end;

procedure TfrmFaceRecognition.Button3Click(Sender: TObject);
var
  i, X, Y: DWORD;
  LFaceEmbeddingA, LFaceEmbeddingB: TOutputDataFaceNet;
  FEmbedded: Float32;
begin
  FEmbedded := 0;
  CreateFaceEmbedding(ImageA, LFaceEmbeddingA);
  CreateFaceEmbedding(ImageB, LFaceEmbeddingB);

    for i := 0 to FaceNetOutputSize - 1 do
      LFaceEmbeddingB[i] := (LFaceEmbeddingB[i]) - (LFaceEmbeddingA[i]);

    FEmbedded := System.Math.Norm(LFaceEmbeddingB);

    if FEmbedded < 0.41 then
      Label1.Text := 'Same Person: TRUE, Distance: ' + FloatToStr(FEmbedded)
    else
      Label1.Text := 'Same Person: FALSE, Distance: ' + FloatToStr(FEmbedded);
end;

procedure TfrmFaceRecognition.FormCreate(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  SetPriorityClass(GetCurrentProcess, HIGH_PRIORITY_CLASS);

  FaceNet := TTensorFlowLiteFMX.Create(Self);

  // Currently Tensor Flow Lite for Windows supports only x64 CPU, GPU is not supported

  FaceNet.LoadModel(ModelsPath + 'face_recognition.tflite', 8);

{$ENDIF}
end;

end.
