unit FaceRecognitionFMX;

interface

uses
{$IFDEF MSWINDOWS}
  WinApi.Windows,
{$ENDIF}
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Graphics,
  FMX.Utils,
  FMX.StdCtrls,
  FMX.Objects,
  System.Math,
  TensorFlowLiteFMX
  ;


const
  ModelsPath = '..\..\..\..\..\models\';

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
  TFaceRecognition = class
  private
    FFaceNet: TTensorFlowLiteFMX;
  public
    function CreateFaceEmbedding(inFaceImage: TImage; var outFaceEmbedding: TOutputDataFaceNet): Boolean;
    constructor Create;
    destructor Destroy; override;
  end;



implementation


constructor TFaceRecognition.Create;
begin
  FFaceNet := TTensorFlowLiteFMX.Create(nil);
  // Currently Tensor Flow Lite for Windows supports only x64 CPU, GPU is not supported

  FFaceNet.LoadModel(ModelsPath + 'face_recognition.tflite', 8);
end;

destructor TFaceRecognition.Destroy;
begin
  FreeAndNil(FFaceNet);
  inherited;
end;

function TFaceRecognition.CreateFaceEmbedding(inFaceImage: TImage; var outFaceEmbedding: TOutputDataFaceNet): Boolean;
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


end.
