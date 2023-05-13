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
  TensorFlowLiteFMX,
  FaceDetectFMX
  ;

type
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
    procedure OnCompletion(detectms: Integer; nms: Integer ; inCount: Integer);
    procedure OnFoundFaces(faceList: TFaceList);
  public
    procedure ReloadModel;
  end;

var
  frmFaceDetect: TfrmFaceDetect;

implementation

{$R *.fmx}

procedure TfrmFaceDetect.OnCompletion(detectms: Integer; nms: Integer ; inCount: Integer);
begin
  Label4.Text := 'detect time: ' + detectms.ToString + ', nms time: ' + nms.ToString + ', face count: ' + inCount.ToString;
end;


procedure TfrmFaceDetect.OnFoundFaces(faceList: TFaceList);
var
  i : Integer;
  LRect: TRectF;
begin
  LRect.Width := Screen.Width;
  LRect.Height := Screen.Height;

  ImageMain.Bitmap.Canvas.BeginScene;
  try
    ImageMain.Bitmap.Canvas.Font.Size := 11;
    ImageMain.Bitmap.Canvas.MeasureText(LRect, '0,00', False, [], TTextAlign.Leading, TTextAlign.Leading);
    ImageMain.Bitmap.Canvas.Stroke.Color := TAlphaColorRec.Orangered;
    ImageMain.Bitmap.Canvas.Stroke.Thickness := 1.5;

    for i := 0 to faceList.Count - 1 do
    begin
      ImageMain.Bitmap.Canvas.DrawRect(faceList.Faces[i].Rect, 0, 0, AllCorners, 1);

      ImageMain.Bitmap.Canvas.Fill.Color := TAlphaColorRec.White;
      if not HideProbability then
        ImageMain.Bitmap.Canvas.FillText(
          RectF(faceList.Faces[i].Rect.Left, faceList.Faces[i].Rect.Top - LRect.Height, faceList.Faces[i].Rect.Right + LRect.Width, faceList.Faces[i].Rect.Bottom),
          Copy(FloatToStr(faceList.Faces[i].Probability), 1, 4),
          False, 1, [], TTextAlign.Leading, TTextAlign.Leading);
    end;
  finally
    ImageMain.Bitmap.Canvas.EndScene;
  end;
end;

procedure TfrmFaceDetect.btnOpenImageClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    FaceDetect.LoadImage(ImageMain, OpenDialog.FileName);
end;

procedure TfrmFaceDetect.btnDetectFacesClick(Sender: TObject);
var
  Probability : Float32;
begin
  FaceDetect.BatchSize := StrToIntDef(edtBatchSize.Text, 1);
  Probability := StrToFloat(cboProbability.Items[cboProbability.ItemIndex]);
  FaceDetect.DetectFaces(Probability, ImageMain, OpenDialog.FileName);
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
  FaceDetect := TFaceDetect.Create(Self);
  FaceDetect.OnCompletion := OnCompletion;
  FaceDetect.OnFoundFaces := OnFoundFaces;
{$ENDIF}
end;

procedure TfrmFaceDetect.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FreeAndNil(FaceDetect);
end;

end.
