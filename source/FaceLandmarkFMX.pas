unit FaceLandmarkFMX;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  System.IOUtils,
  FMX.Utils,
  FMX.Graphics,
  TensorFlowLiteFMX
  ;

const
  FaceLandmarkInputSize = 160;
  FaceLandmarkOutputSize = 136;

type
  PInputDataFaceLandmark = ^TInputDataFaceLandmark;
  TInputDataFaceLandmark = array [0 .. FaceLandmarkInputSize - 1] of array [0 .. FaceLandmarkInputSize - 1] of array [0 .. 3 - 1] of Float32;

type
  POutputDataFaceLandmark = ^TOutputDataFaceLandmark;
  TOutputDataFaceLandmark = array [0 .. 68 - 1] of array [0 .. 2 - 1] of Float32;

type
  TFaceLandmarkData = record
    Points: array of TPointF;
    Count: Int32;
  end;

type
  EFaceLandmarkFMXError = class(Exception);

  TFaceLandmarkFMX = class(TComponent)
  private
    FFaceLandmark: TTensorFlowLiteFMX;

    FInputData: TInputDataFaceLandmark;
    FOutputData: TOutputDataFaceLandmark;
  public
    UseGpu: Boolean;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function LoadModel(ModelPath: String; ThreadCount: Integer): TFLiteStatus;
    procedure UnloadModel;

    function GetLandmarkData(Bitmap: TBitmap): TFaceLandmarkData;
  end;

implementation

function TFaceLandmarkFMX.GetLandmarkData(Bitmap: TBitmap): TFaceLandmarkData;
var
  LPixel, X, Y: DWORD;
  LColors: PAlphaColorArray;
  LBitmapData: TBitmapData;
  LBitmap: TBitmap;
  LStatus: TFLiteStatus;
  LRect: TRectF;
begin
  SetLength(Result.Points, 0);
  Result.Count := 0;

  if not Assigned(Bitmap) then
    Exit;

  LBitmap := TBitmap.Create;

  LBitmap.Width := FaceLandmarkInputSize;
  LBitmap.Height := FaceLandmarkInputSize;

  LBitmap.Canvas.BeginScene;
  try
    LBitmap.Canvas.Clear(TAlphaColorRec.Null);

    Bitmap.Canvas.BeginScene;
    try
      LRect.Left := 0;
      LRect.Top := 0;
      LRect.Width := FaceLandmarkInputSize;
      LRect.Height := FaceLandmarkInputSize;

      LBitmap.Canvas.DrawBitmap(
        Bitmap,
        Bitmap.BoundsF,
        LRect,
        1, False);
    finally
      Bitmap.Canvas.EndScene;
    end;
  finally
    LBitmap.Canvas.EndScene;
  end;

  if (LBitmap.Map(TMapAccess.ReadWrite, LBitmapData)) then
  begin
    try
      for Y := 0 to FaceLandmarkInputSize - 1 do
      begin
        LColors := PAlphaColorArray(LBitmapData.GetScanline(Y));

        for X := 0 to FaceLandmarkInputSize - 1 do
        begin
          FInputData[Y][X][0] := (TAlphaColorRec(LColors[X]).R);
          FInputData[Y][X][1] := (TAlphaColorRec(LColors[X]).G);
          FInputData[Y][X][2] := (TAlphaColorRec(LColors[X]).B);
        end;
      end;

      LStatus := FFaceLandmark.SetInputData(0, @FInputData, FFaceLandmark.Input.Tensors[0].DataSize);

      if LStatus <> TFLiteOk then
      begin
        raise ETensorFlowLiteFMXError.Create('Error: SetInputData');
        Exit;
      end;

      LStatus := FFaceLandmark.Inference;

      if LStatus <> TFLiteOk then
      begin
        raise ETensorFlowLiteFMXError.Create('Error: Inference');
        Exit;
      end;

      LStatus := FFaceLandmark.GetOutputData(2, @FOutputData, FFaceLandmark.Output.Tensors[2].DataSize);

      if LStatus <> TFLiteOk then
      begin
        raise ETensorFlowLiteFMXError.Create('Error: GetOutputData');
        Exit;
      end;

      SetLength(Result.Points, FaceLandmarkOutputSize div 2);
      Result.Count := FaceLandmarkOutputSize div 2;

      LPixel := 0;

      for X := 0 to FaceLandmarkOutputSize div 2 - 1 do
      begin
        Result.Points[LPixel].X := FOutputData[LPixel][0] * Bitmap.Width;
        Result.Points[LPixel].Y := FOutputData[LPixel][1] * Bitmap.Height;

        Inc(LPixel);
      end;

    finally
      LBitmap.Unmap(LBitmapData);
    end;
  end;
end;

function TFaceLandmarkFMX.LoadModel(ModelPath: String; ThreadCount: Integer): TFLiteStatus;
begin
  FFaceLandmark.UseGpu := UseGpu;

  Result := FFaceLandmark.LoadModel(ModelPath, ThreadCount);
end;

procedure TFaceLandmarkFMX.UnloadModel;
begin
  FFaceLandmark.UnloadModel;
end;

constructor TFaceLandmarkFMX.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  UseGpu := False;

  FFaceLandmark := TTensorFlowLiteFMX.Create(Self);
end;

destructor TFaceLandmarkFMX.Destroy;
begin
  FFaceLandmark.Destroy;

  inherited Destroy;
end;

end.
