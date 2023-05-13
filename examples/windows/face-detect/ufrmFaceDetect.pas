unit ufrmFaceDetect;

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
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Objects,
  FMX.Utils,
  System.ImageList,
  FMX.ImgList,
  FMX.ListBox,
  FMX.Edit,
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
  TFaceDetect = class
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

    FaceDetectionInputSize: Int32;
    FaceDetectionOutputSize: Int32;
    procedure LoadImage(inFilename: string);
  public
    ImageList: TImageList;
    ThreadCount : Integer;
    BatchSize: Int32;
    procedure DetectFaces(inFilename: string);
    function LoadModel(ModelPath: String; InterpreterThreadCount: Integer): TFLiteStatus;
    function GetFaceList(Probability: Float32; NMS: Integer; OutputData: POutputDataFaceDetection): TFaceList;
    constructor Create;
    destructor Destroy; override;
  end;

  TfrmFaceDetect = class(TForm)
    ImageMain: TImage;
    btnOpenImage: TButton;
    btnDetectFaces: TButton;
    OpenDialog: TOpenDialog;
    ImageList2: TImageList;
    cboProbability: TComboBox;
    Label1: TLabel;
    cboThreadCount: TComboBox;
    Label2: TLabel;
    cboInputSize: TComboBox;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    edtBatchSize: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnDetectFacesClick(Sender: TObject);
    procedure btnOpenImageClick(Sender: TObject);
    procedure cboThreadCountChange(Sender: TObject);
    procedure cboInputSizeChange(Sender: TObject);
  private
    FaceDetect : TFaceDetect;
  public
    procedure ReloadModel;
  end;

var
  frmFaceDetect: TfrmFaceDetect;

implementation

{$R *.fmx}

const
  ModelsPath = '..\..\..\..\..\models\';


var
  HideProbability: Boolean = False;

procedure TFaceDetect.LoadImage(inFilename: string);
begin
  frmFaceDetect.Label4.Text := '';

{$IFDEF MSWINDOWS}
  if not FileExists(inFilename) then
    Exit;

  if frmFaceDetect.ImageMain.MultiResBitmap.Count > 0 then
    frmFaceDetect.ImageMain.MultiResBitmap[0].Free;

  frmFaceDetect.ImageMain.MultiResBitmap.Add;

  if FileExists(inFilename) then
  begin
    if ImageList.Source[0].MultiResBitmap.Count > 0 then
      ImageList.Source[0].MultiResBitmap[0].Free;

    ImageList.Source[0].MultiResBitmap.Add;
    ImageList.Source[0].MultiResBitmap[0].Bitmap.LoadFromFile(inFilename);
  end;

  if ImageList.Source[1].MultiResBitmap.Count > 0 then
    ImageList.Source[1].MultiResBitmap[0].Free;

  ImageList.Source[1].MultiResBitmap.Add;
  ImageList.Source[1].MultiResBitmap[0].Bitmap.Width := FaceDetectionInputSize;
  ImageList.Source[1].MultiResBitmap[0].Bitmap.Height := FaceDetectionInputSize;

  ImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.BeginScene;
  try
    ImageList.Source[0].MultiResBitmap[0].Bitmap.Canvas.BeginScene;
    try
      ImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.Clear(TAlphaColorRec.Null);

      if ImageList.Source[0].MultiResBitmap[0].Bitmap.Width > ImageList.Source[0].MultiResBitmap[0].Bitmap.Height then
      begin
        ImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.DrawBitmap(
          ImageList.Source[0].MultiResBitmap[0].Bitmap,
          RectF(0, 0, ImageList.Source[0].MultiResBitmap[0].Bitmap.Width, ImageList.Source[0].MultiResBitmap[0].Bitmap.Height),
          RectF(0, 0, FaceDetectionInputSize, ImageList.Source[0].MultiResBitmap[0].Bitmap.Height / (ImageList.Source[0].MultiResBitmap[0].Bitmap.Width / FaceDetectionInputSize)),
          1, True);
      end
      else
      begin
        ImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.DrawBitmap(
          ImageList.Source[0].MultiResBitmap[0].Bitmap,
          RectF(0, 0, ImageList.Source[0].MultiResBitmap[0].Bitmap.Width, ImageList.Source[0].MultiResBitmap[0].Bitmap.Height),
          RectF(0, 0, ImageList.Source[0].MultiResBitmap[0].Bitmap.Width / (ImageList.Source[0].MultiResBitmap[0].Bitmap.Height / FaceDetectionInputSize), FaceDetectionInputSize),
          1, True);
      end;

    finally
      ImageList.Source[0].MultiResBitmap[0].Bitmap.Canvas.EndScene;
    end;
  finally
    ImageList.Source[1].MultiResBitmap[0].Bitmap.Canvas.EndScene;
  end;

  frmFaceDetect.ImageMain.Bitmap.Assign(ImageList.Source[1].MultiResBitmap[0].Bitmap);

{$ENDIF MSWINDOWS}
end;

procedure TfrmFaceDetect.btnOpenImageClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    FaceDetect.LoadImage(OpenDialog.FileName);
end;

function TFaceDetect.GetFaceList(Probability: Float32; NMS: Integer; OutputData: POutputDataFaceDetection): TFaceList;
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

procedure TfrmFaceDetect.btnDetectFacesClick(Sender: TObject);
begin
  FaceDetect.BatchSize := StrToIntDef(edtBatchSize.Text, 1);
  FaceDetect.DetectFaces(OpenDialog.FileName);
end;


procedure TFaceDetect.DetectFaces(inFilename: string);
var
  LBatch, i, X, Y, LPixel: DWORD;
  LColors: PAlphaColorArray;
  LBitmapData: TBitmapData;
  LInputData: PInputDataFaceDetection;
  LOutputData: POutputDataFaceDetection;
  LStatus: TFLiteStatus;
  LFaceList: TFaceList;
  LRect: TRectF;
  LTickCountInference, LTickCountNMS: Int64;
begin

  LoadImage(inFilename);

  if ImageList.Source[1].MultiResBitmap.Count = 0 then
    Exit;

  if (ImageList.Source[1].MultiResBitmap[0].Bitmap.Map(TMapAccess.ReadWrite, LBitmapData)) then
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

          LFaceList := GetFaceList(StrToFloat(frmFaceDetect.cboProbability.Items[frmFaceDetect.cboProbability.ItemIndex]), 10, LOutputData);

          if LBatch = BatchSize - 1 then
          begin
            frmFaceDetect.ImageMain.Bitmap.Canvas.BeginScene;
            try
              LRect.Width := Screen.Width;
              LRect.Height := Screen.Height;

              if LFaceList.Count > 0 then
              begin
                frmFaceDetect.Label4.Text := 'detect time: ' + FloatToStr((TThread.GetTickCount64 - LTickCountInference) / 1000 / BatchSize) + ', nms time: ' + FloatToStr((TThread.GetTickCount64 - LTickCountNMS) / 1000) + ', face count: ' + IntToStr(LFaceList.Count);

                frmFaceDetect.ImageMain.Bitmap.Canvas.Font.Size := 11;
                frmFaceDetect.ImageMain.Bitmap.Canvas.MeasureText(LRect, '0,00', False, [], TTextAlign.Leading, TTextAlign.Leading);
                frmFaceDetect.ImageMain.Bitmap.Canvas.Stroke.Color := TAlphaColorRec.Orangered;
                frmFaceDetect.ImageMain.Bitmap.Canvas.Stroke.Thickness := 1.5;

                for i := 0 to LFaceList.Count - 1 do
                begin
                  frmFaceDetect.ImageMain.Bitmap.Canvas.DrawRect(LFaceList.Faces[i].Rect, 0, 0, AllCorners, 1);

                  frmFaceDetect.ImageMain.Bitmap.Canvas.Fill.Color := TAlphaColorRec.White;
                  if not HideProbability then
                    frmFaceDetect.ImageMain.Bitmap.Canvas.FillText(
                      RectF(LFaceList.Faces[i].Rect.Left, LFaceList.Faces[i].Rect.Top - LRect.Height, LFaceList.Faces[i].Rect.Right + LRect.Width, LFaceList.Faces[i].Rect.Bottom),
                      Copy(FloatToStr(LFaceList.Faces[i].Probability), 1, 4),
                      False, 1, [], TTextAlign.Leading, TTextAlign.Leading);
                end;
              end;
            finally
              frmFaceDetect.ImageMain.Bitmap.Canvas.EndScene;
            end;
          end;

        finally
          FreeMem(LOutputData);
        end;

      end;
    finally
      ImageList.Source[1].MultiResBitmap[0].Bitmap.Unmap(LBitmapData);
    end;
  end;
end;

procedure TfrmFaceDetect.ReloadModel;
begin
  case cboInputSize.ItemIndex of
    0:
      begin
        FaceDetect.FaceDetectionInputSize := 160;
        FaceDetect.FaceDetectionOutputSize := 1575;
        FaceDetect.LoadModel(ModelsPath + 'face_detection_160.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
      end;
    1:
      begin
        FaceDetect.FaceDetectionInputSize := 192;
        FaceDetect.FaceDetectionOutputSize := 2268;
        FaceDetect.LoadModel(ModelsPath + 'face_detection_192.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
      end;
    2:
      begin
        FaceDetect.FaceDetectionInputSize := 256;
        FaceDetect.FaceDetectionOutputSize := 4032;
        FaceDetect.LoadModel(ModelsPath + 'face_detection_256.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
      end;
    3:
      begin
        FaceDetect.FaceDetectionInputSize := 320;
        FaceDetect.FaceDetectionOutputSize := 6300;
        FaceDetect.LoadModel(ModelsPath + 'face_detection_320.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
      end;
    4:
      begin
        FaceDetect.FaceDetectionInputSize := 480;
        FaceDetect.FaceDetectionOutputSize := 14175;
        FaceDetect.LoadModel(ModelsPath + 'face_detection_480.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
      end;
    5:
      begin
        FaceDetect.FaceDetectionInputSize := 640;
        FaceDetect.FaceDetectionOutputSize := 25200;
        FaceDetect.LoadModel(ModelsPath + 'face_detection_640.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
      end;
    6:
      begin
        FaceDetect.FaceDetectionInputSize := 800;
        FaceDetect.FaceDetectionOutputSize := 39375;
        FaceDetect.LoadModel(ModelsPath + 'face_detection_800.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
      end;
  end;
end;

procedure TfrmFaceDetect.cboThreadCountChange(Sender: TObject);
begin
  ReloadModel;
end;

procedure TfrmFaceDetect.cboInputSizeChange(Sender: TObject);
begin
  ReloadModel;
end;

procedure TfrmFaceDetect.FormCreate(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  SetPriorityClass(GetCurrentProcess, HIGH_PRIORITY_CLASS);
  FaceDetect := TFaceDetect.Create;
{$ENDIF}
end;

procedure TfrmFaceDetect.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FreeAndNil(FaceDetect);
end;

{ TFaceDetect }

constructor TFaceDetect.Create;
var
  LSourceItem : TCustomSourceItem;
begin
  FFaceDetection := TTensorFlowLiteFMX.Create(nil);
  // Currently Tensor Flow Lite for Windows supports only x64 CPU, GPU is not supported
  FaceDetectionInputSize :=640;
  FaceDetectionOutputSize := 25200;
  BatchSize := 1;
  ImageList := TImageList.Create(nil);
  LSourceItem := ImageList.Source.Add;
  LSourceItem.Name := 'Source';

  LSourceItem := ImageList.Source.Add;
  LSourceItem.Name := 'FaceSegment';

  LSourceItem := ImageList.Source.Add;
  LSourceItem.Name := 'IrisLeft';

  LSourceItem := ImageList.Source.Add;
  LSourceItem.Name := 'IrisRight';

  FFaceDetection.LoadModel(ModelsPath + 'face_detection_640.tflite', 8);
end;

destructor TFaceDetect.Destroy;
begin
  FreeAndNil(FFaceDetection);
  FreeAndNil(ImageList);
  inherited;
end;

function TFaceDetect.LoadModel(ModelPath: String; InterpreterThreadCount: Integer): TFLiteStatus;
begin
  Result := FFaceDetection.LoadModel(ModelPath, InterpreterThreadCount);
end;

end.
