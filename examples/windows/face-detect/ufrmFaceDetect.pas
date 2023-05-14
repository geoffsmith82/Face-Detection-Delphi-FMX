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
    cboProbability: TComboBox;
    lblProbability: TLabel;
    cboThreadCount: TComboBox;
    lblThreadCount: TLabel;
    cboInputSize: TComboBox;
    lblInputSize: TLabel;
    Label4: TLabel;
    lblBatchSize: TLabel;
    edtBatchSize: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnDetectFacesClick(Sender: TObject);
    procedure btnOpenImageClick(Sender: TObject);
    procedure cboThreadCountChange(Sender: TObject);
    procedure cboInputSizeChange(Sender: TObject);
  private
    FFaceDetect : TFaceDetect;
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
    FFaceDetect.LoadImage(ImageMain, OpenDialog.FileName);
end;

procedure TfrmFaceDetect.btnDetectFacesClick(Sender: TObject);
var
  Probability : Float32;
begin
  FFaceDetect.BatchSize := StrToIntDef(edtBatchSize.Text, 1);
  Probability := StrToFloat(cboProbability.Items[cboProbability.ItemIndex]);
  FFaceDetect.DetectFaces(Probability, ImageMain, OpenDialog.FileName);
end;


procedure TfrmFaceDetect.ReloadModel;
begin
  case cboInputSize.ItemIndex of
    0:
      begin
        FFaceDetect.FaceDetectionInputSize := 160;
        FFaceDetect.FaceDetectionOutputSize := 1575;
        FFaceDetect.LoadModel(ModelsPath + 'face_detection_160.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
      end;
    1:
      begin
        FFaceDetect.FaceDetectionInputSize := 192;
        FFaceDetect.FaceDetectionOutputSize := 2268;
        FFaceDetect.LoadModel(ModelsPath + 'face_detection_192.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
      end;
    2:
      begin
        FFaceDetect.FaceDetectionInputSize := 256;
        FFaceDetect.FaceDetectionOutputSize := 4032;
        FFaceDetect.LoadModel(ModelsPath + 'face_detection_256.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
      end;
    3:
      begin
        FFaceDetect.FaceDetectionInputSize := 320;
        FFaceDetect.FaceDetectionOutputSize := 6300;
        FFaceDetect.LoadModel(ModelsPath + 'face_detection_320.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
      end;
    4:
      begin
        FFaceDetect.FaceDetectionInputSize := 480;
        FFaceDetect.FaceDetectionOutputSize := 14175;
        FFaceDetect.LoadModel(ModelsPath + 'face_detection_480.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
      end;
    5:
      begin
        FFaceDetect.FaceDetectionInputSize := 640;
        FFaceDetect.FaceDetectionOutputSize := 25200;
        FFaceDetect.LoadModel(ModelsPath + 'face_detection_640.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
      end;
    6:
      begin
        FFaceDetect.FaceDetectionInputSize := 800;
        FFaceDetect.FaceDetectionOutputSize := 39375;
        FFaceDetect.LoadModel(ModelsPath + 'face_detection_800.tflite', StrToInt(cboThreadCount.Items[cboThreadCount.ItemIndex]));
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
  FFaceDetect := TFaceDetect.Create(Self);
  FFaceDetect.OnCompletion := OnCompletion;
  FFaceDetect.OnFoundFaces := OnFoundFaces;
{$ENDIF}
end;

procedure TfrmFaceDetect.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FreeAndNil(FFaceDetect);
end;

end.
