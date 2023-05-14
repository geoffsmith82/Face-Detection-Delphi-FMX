unit FaceDetectFMX;

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
  FMX.StdCtrls,
  FMX.Objects,
  FMX.Utils,
  FMX.ImgList,
  TensorFlowLiteFMX
  ;




type
  PInputDataFaceDetection = ^TInputDataFaceDetection;
  TInputDataFaceDetection = array [0 .. 800 * 800 - 1] of array [0 .. 3 - 1] of Float32;

type
  POutputDataFaceDetection = ^TOutputDataFaceDetection;
  TOutputDataFaceDetection = array [0 .. 39375 - 1] of array [0 .. 6 - 1] of Float32;

type
  TFace = record
    Rect: TRectF;
    Probability: Float32;
  end;

type
  TFaceList = record
    Faces: array of TFace;
    Count: Int32;
  end;

type
  TFaceDetectStatus = procedure(detectms: Integer; nms: Integer ; inCount: Integer) of object;
  TFoundFaces = procedure(faceList: TFaceList) of object;

  TFaceDetect = class(TComponent)
  private
    FFaceDetection: TTensorFlowLiteFMX;

    // AMD Ryzen 5 3500X, Windows 10, 8 threads, CPU
    // tflite models with static input shape
    // 160, 1575 - image with 160x160 pixels, inference time 0.009 sec, 110 frame per sec, good detection quality, perfect for selfies
    // 192, 2268
    // 256, 4032
    // 320, 6300 - image with 320x320 pixels, inference time 0.031 sec, 32 frame per sec, high detection quality
    // 480, 14175 - image with 480x480 pixels, inference time 0.064 sec, 15 frame per sec, high detection quality
    // 640, 25200 - image with 640x640 pixels, inference time 0.109 sec, 9 frame per sec, high quality detection
    // 800, 39375 - image with 800x800pixels, inference time 0.109 sec, 9 frame per sec, high quality detection

    FImageList: TImageList;
    procedure DoCompletion(detectms, nms: Int64; inCount: Integer);
    procedure DoFoundFaces(faceList: TFaceList);
  public
    OnCompletion : TFaceDetectStatus;
    OnFoundFaces : TFoundFaces;
    ThreadCount : Integer;
    BatchSize: UInt32;
    FaceDetectionInputSize: UInt32;
    FaceDetectionOutputSize: UInt32;
    procedure LoadImage(ImageMain: TImage; inFilename: string);
    procedure DetectFaces(Probability: Float32; ImageMain: TImage; inFilename: string);
    function LoadModel(ModelPath: String; InterpreterThreadCount: Integer): TFLiteStatus;
    function GetFaceList(Probability: Float32; NMS: UInt32; OutputData: POutputDataFaceDetection): TFaceList;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  HideProbability: Boolean = False;

const
  ModelsPath = '..\..\..\..\..\models\';

implementation


{ TFaceDetect }

constructor TFaceDetect.Create(AOwner: TComponent);
var
  LSourceItem : TCustomSourceItem;
begin
  FFaceDetection := TTensorFlowLiteFMX.Create(nil);
  // Currently Tensor Flow Lite for Windows supports only x64 CPU, GPU is not supported
  FaceDetectionInputSize := 640;
  FaceDetectionOutputSize := 25200;
  BatchSize := 1;
  FImageList := TImageList.Create(nil);
  LSourceItem := FImageList.Source.Add;
  LSourceItem.Name := 'Source';

  LSourceItem := FImageList.Source.Add;
  LSourceItem.Name := 'FaceSegment';

  LSourceItem := FImageList.Source.Add;
  LSourceItem.Name := 'IrisLeft';

  LSourceItem := FImageList.Source.Add;
  LSourceItem.Name := 'IrisRight';

  FFaceDetection.LoadModel(ModelsPath + 'face_detection_640.tflite', 8);
end;

destructor TFaceDetect.Destroy;
begin
  FreeAndNil(FFaceDetection);
  FreeAndNil(FImageList);
  inherited;
end;

function TFaceDetect.LoadModel(ModelPath: String; InterpreterThreadCount: Integer): TFLiteStatus;
begin
  Result := FFaceDetection.LoadModel(ModelPath, InterpreterThreadCount);
end;

procedure TFaceDetect.LoadImage(ImageMain: TImage; inFilename: string);
begin
  if not FileExists(inFilename) then
    Exit;

  if ImageMain.MultiResBitmap.Count > 0 then
    ImageMain.MultiResBitmap[0].Free;

  ImageMain.MultiResBitmap.Add;

  if FileExists(inFilename) then
  begin
    if FImageList.Source[0].MultiResBitmap.Count > 0 then
      FImageList.Source[0].MultiResBitmap[0].Free;

    FImageList.Source[0].MultiResBitmap.Add;
    FImageList.Source[0].MultiResBitmap[0].Bitmap.LoadFromFile(inFilename);
  end;

  if FImageList.Source[1].MultiResBitmap.Count > 0 then
    FImageList.Source[1].MultiResBitmap[0].Free;

  FImageList.Source[1].MultiResBitmap.Add;
  FImageList.Source[1].MultiResBitmap[0].Bitmap.Width := FaceDetectionInputSize;
  FImageList.Source[1].MultiResBitmap[0].Bitmap.Height := FaceDetectionInputSize;

  FImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.BeginScene;
  try
    FImageList.Source[0].MultiResBitmap[0].Bitmap.Canvas.BeginScene;
    try
      FImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.Clear(TAlphaColorRec.Null);

      if FImageList.Source[0].MultiResBitmap[0].Bitmap.Width > FImageList.Source[0].MultiResBitmap[0].Bitmap.Height then
      begin
        FImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.DrawBitmap(
          FImageList.Source[0].MultiResBitmap[0].Bitmap,
          RectF(0, 0, FImageList.Source[0].MultiResBitmap[0].Bitmap.Width, FImageList.Source[0].MultiResBitmap[0].Bitmap.Height),
          RectF(0, 0, FaceDetectionInputSize, FImageList.Source[0].MultiResBitmap[0].Bitmap.Height / (FImageList.Source[0].MultiResBitmap[0].Bitmap.Width / FaceDetectionInputSize)),
          1, True);
      end
      else
      begin
        FImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.DrawBitmap(
          FImageList.Source[0].MultiResBitmap[0].Bitmap,
          RectF(0, 0, FImageList.Source[0].MultiResBitmap[0].Bitmap.Width, FImageList.Source[0].MultiResBitmap[0].Bitmap.Height),
          RectF(0, 0, FImageList.Source[0].MultiResBitmap[0].Bitmap.Width / (FImageList.Source[0].MultiResBitmap[0].Bitmap.Height / FaceDetectionInputSize), FaceDetectionInputSize),
          1, True);
      end;

    finally
      FImageList.Source[0].MultiResBitmap[0].Bitmap.Canvas.EndScene;
    end;
  finally
    FImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.EndScene;
  end;

  ImageMain.Bitmap.Assign(FImageList.Source[1].MultiResBitmap[0].Bitmap);

end;


function TFaceDetect.GetFaceList(Probability: Float32; NMS: UInt32; OutputData: POutputDataFaceDetection): TFaceList;
var
  i, X, Y: DWORD;
  LListNMS: array of TFace;
  LRect: TRectF;
  LExist: Boolean;
begin
  SetLength(Result.Faces, 0);
  Result.Count := 0;

  SetLength(LListNMS, 0);

  Y := 0;

  while True do
  begin
    if Y > FaceDetectionOutputSize then
      Break;

    if (OutputData[Y][4] >= Probability) and (OutputData[Y][4] <= 1.0) then
    begin
      SetLength(LListNMS, Length(LListNMS) + 1);
      LListNMS[Length(LListNMS) - 1].Rect.Left := ((FaceDetectionInputSize * OutputData[Y][0]) - ((FaceDetectionInputSize * OutputData[Y][2]) / 2));
      LListNMS[Length(LListNMS) - 1].Rect.Top := ((FaceDetectionInputSize * OutputData[Y][1]) - ((FaceDetectionInputSize * OutputData[Y][3]) / 2));
      LListNMS[Length(LListNMS) - 1].Rect.Width := (FaceDetectionInputSize * OutputData[Y][2]);
      LListNMS[Length(LListNMS) - 1].Rect.Height := (FaceDetectionInputSize * OutputData[Y][3]);
      LListNMS[Length(LListNMS) - 1].Probability := OutputData[Y][4];

      if Length(LListNMS) > 0 then
      begin
        for i := Y - NMS to Y + NMS - 1 do
        begin
          if (OutputData[i][4] > OutputData[Y][4]) then
          begin
            LRect.Left := ((FaceDetectionInputSize * OutputData[i][0]) - ((FaceDetectionInputSize * OutputData[i][2]) / 2));
            LRect.Top := ((FaceDetectionInputSize * OutputData[i][1]) - ((FaceDetectionInputSize * OutputData[i][3]) / 2));
            LRect.Width := (FaceDetectionInputSize * OutputData[i][2]);
            LRect.Height := (FaceDetectionInputSize * OutputData[i][3]);

            for X := 0 to Length(LListNMS) - 1 do
            begin
              if IntersectRect(LListNMS[X].Rect, LRect) then
              begin
                if (FaceDetectionInputSize * OutputData[i][0] > LListNMS[X].Rect.Left) and
                  (FaceDetectionInputSize * OutputData[i][0] < LListNMS[X].Rect.Right) and
                  (FaceDetectionInputSize * OutputData[i][1] > LListNMS[X].Rect.Top) and
                  (FaceDetectionInputSize * OutputData[i][1] < LListNMS[X].Rect.Bottom) and
                  (OutputData[i][4] > LListNMS[X].Probability)
                then
                begin
                  LListNMS[X].Rect.Left := LRect.Left;
                  LListNMS[X].Rect.Top := LRect.Top;
                  LListNMS[X].Rect.Width := LRect.Width;
                  LListNMS[X].Rect.Height := LRect.Height;
                  LListNMS[X].Probability := OutputData[i][4];
                end;
              end;
            end;
          end;
        end;
      end;
    end;

    Inc(Y);
  end;

  if Length(LListNMS) > 0 then
  begin
    for Y := 0 to Length(LListNMS) - 1 do
    begin
      LExist := False;

      if (Length(Result.Faces) > 0) then
      begin
        for i := 0 to Length(Result.Faces) - 1 do
        begin

          if (IntersectRect(Result.Faces[i].Rect, LListNMS[Y].Rect)) then
          begin
            if ((Abs(Result.Faces[i].Rect.Top - LListNMS[Y].Rect.Top) < Result.Faces[i].Rect.Height / 2)) and
              ((Abs(Result.Faces[i].Rect.Bottom - LListNMS[Y].Rect.Bottom) < Result.Faces[i].Rect.Height / 2)) and
              ((Abs(Result.Faces[i].Rect.Left - LListNMS[Y].Rect.Left) < Result.Faces[i].Rect.Width / 2)) and
              ((Abs(Result.Faces[i].Rect.Right - LListNMS[Y].Rect.Right) < Result.Faces[i].Rect.Width / 2)) then
            begin
              if LListNMS[Y].Probability > Result.Faces[i].Probability then
              begin
                Result.Faces[i].Probability := LListNMS[Y].Probability;
                Result.Faces[i].Rect.Left := LListNMS[Y].Rect.Left;
                Result.Faces[i].Rect.Top := LListNMS[Y].Rect.Top;
                Result.Faces[i].Rect.Right := LListNMS[Y].Rect.Right;
                Result.Faces[i].Rect.Bottom := LListNMS[Y].Rect.Bottom;
              end;

              LExist := True;
              Break;
            end;
          end;
        end;
      end;

      if (LExist = False) then
      begin
        SetLength(Result.Faces, Length(Result.Faces) + 1);
        Result.Faces[Length(Result.Faces) - 1].Rect.Left := LListNMS[Y].Rect.Left;
        Result.Faces[Length(Result.Faces) - 1].Rect.Top := LListNMS[Y].Rect.Top;
        Result.Faces[Length(Result.Faces) - 1].Rect.Width := LListNMS[Y].Rect.Width;
        Result.Faces[Length(Result.Faces) - 1].Rect.Height := LListNMS[Y].Rect.Height;
        Result.Faces[Length(Result.Faces) - 1].Probability := LListNMS[Y].Probability;

        Result.Count := Length(Result.Faces);
      end;
    end;
  end;
end;


procedure TFaceDetect.DetectFaces(Probability: Float32; ImageMain: TImage; inFilename: string);
var
  LBatch, X, Y, LPixel: DWORD;
  LColors: PAlphaColorArray;
  LBitmapData: TBitmapData;
  LInputData: PInputDataFaceDetection;
  LOutputData: POutputDataFaceDetection;
  LStatus: TFLiteStatus;
  LFaceList: TFaceList;
  LTickCountInference, LTickCountNMS: UInt64;
begin

  LoadImage(ImageMain, inFilename);

  if FImageList.Source[1].MultiResBitmap.Count = 0 then
    Exit;

  if (FImageList.Source[1].MultiResBitmap[0].Bitmap.Map(TMapAccess.ReadWrite, LBitmapData)) then
  begin
    try
      LTickCountInference := TThread.GetTickCount64;

      for LBatch := 0 to BatchSize - 1 do
      begin
        GetMem(LInputData, FFaceDetection.Input.Tensors[0].DataSize);
        try
          LPixel := 0;

          for Y := 0 to FaceDetectionInputSize - 1 do
          begin
            LColors := PAlphaColorArray(LBitmapData.GetScanline(Y));

            for X := 0 to FaceDetectionInputSize - 1 do
            begin
              LInputData[LPixel][0] := (TAlphaColorRec(LColors[X]).R / 255);
              LInputData[LPixel][1] := (TAlphaColorRec(LColors[X]).G / 255);
              LInputData[LPixel][2] := (TAlphaColorRec(LColors[X]).B / 255);

              Inc(LPixel);
            end;
          end;

          LStatus := FFaceDetection.SetInputData(0, LInputData, FFaceDetection.Input.Tensors[0].DataSize);
        finally
          FreeMem(LInputData);
        end;

        if LStatus <> TFLiteOk then
        begin
          ShowMessage('SetInputData Error');
          Exit;
        end;

        LStatus := FFaceDetection.Inference;

        if LStatus <> TFLiteOk then
        begin
          ShowMessage('Inference Error');
          Exit;
        end;

        GetMem(LOutputData, FFaceDetection.Output.Tensors[0].DataSize);
        try
          LStatus := FFaceDetection.GetOutputData(0, LOutputData, FFaceDetection.Output.Tensors[0].DataSize);

          if LStatus <> TFLiteOk then
            Exit;

          LTickCountNMS := TThread.GetTickCount64;

          LFaceList := GetFaceList(Probability, 10, LOutputData);

          if LBatch = BatchSize - 1 then
          begin
            if LFaceList.Count > 0 then
            begin
              DoCompletion(Trunc((TThread.GetTickCount64 - LTickCountInference) / BatchSize),
                 TThread.GetTickCount64 - LTickCountNMS,
                 LFaceList.Count);
              DoFoundFaces(LFaceList);
            end;
          end;

        finally
          FreeMem(LOutputData);
        end;

      end;
    finally
      FImageList.Source[1].MultiResBitmap[0].Bitmap.Unmap(LBitmapData);
    end;
  end;
end;
procedure TFaceDetect.DoCompletion(detectms, nms: Int64; inCount: Integer);
begin
  if Assigned(OnCompletion) then
  begin
    OnCompletion(detectms, nms, inCount);
  end;
end;

procedure TFaceDetect.DoFoundFaces(faceList: TFaceList);
begin
  if Assigned(OnFoundFaces) then
  begin
    OnFoundFaces(faceList);
  end;

end;

end.
