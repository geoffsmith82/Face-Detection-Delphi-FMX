unit ufrmFaceLandmark;

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
  FaceLandmarkFMX
  ;

type
  TfrmFaceLandmark = class(TForm)
    ImageMain: TImage;
    btnOpenImage: TButton;
    btnDetect: TButton;
    OpenDialog: TOpenDialog;
    ImageList: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnDetectClick(Sender: TObject);
    procedure btnOpenImageClick(Sender: TObject);
  private
    FFaceLandmarkFMX: TFaceLandmarkFMX;
  public
    procedure LoadImage(inFilename: string);
  end;

var
  frmFaceLandmark: TfrmFaceLandmark;

implementation

{$R *.fmx}


const
  ModelsPath = '..\..\..\..\..\models\';

procedure TfrmFaceLandmark.LoadImage(inFilename: string);
begin
{$IFDEF MSWINDOWS}
  if not FileExists(inFilename) then
    Exit;

  if ImageMain.MultiResBitmap.Count > 0 then
    ImageMain.MultiResBitmap[0].Free;

  ImageMain.MultiResBitmap.Add;

  if FileExists(inFilename) then
  begin
    if ImageList.Source[0].MultiResBitmap.Count > 0 then
      ImageList.Source[0].MultiResBitmap[0].Free;

    ImageList.Source[0].MultiResBitmap.Add;
    ImageList.Source[0].MultiResBitmap[0].Bitmap.LoadFromFile(inFilename);
  end;

  ImageMain.Bitmap.Assign(ImageList.Source[0].MultiResBitmap[0].Bitmap);

{$ENDIF MSWINDOWS}
end;

procedure TfrmFaceLandmark.btnOpenImageClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    LoadImage(OpenDialog.Filename);
end;

procedure TfrmFaceLandmark.btnDetectClick(Sender: TObject);
var
  I: DWORD;
  LFaceLandmarkData: TFaceLandmarkData;
begin
  LoadImage(OpenDialog.Filename);

  LFaceLandmarkData := FFaceLandmarkFMX.GetLandmarkData(ImageMain.Bitmap);

  ImageMain.Bitmap.Canvas.BeginScene;
  try
    ImageMain.Bitmap.Canvas.Fill.Color := TAlphaColorRec.White;
    ImageMain.Bitmap.Canvas.Stroke.Color := TAlphaColorRec.White;

    for I := 0 to LFaceLandmarkData.Count - 1 do
    begin
      ImageMain.Bitmap.Canvas.FillRect(
        RectF(
        LFaceLandmarkData.Points[I].X,
        LFaceLandmarkData.Points[I].Y,
        LFaceLandmarkData.Points[I].X + 5,
        LFaceLandmarkData.Points[I].Y + 5),
        0, 0, AllCorners, 1);
    end;

  finally
    ImageMain.Bitmap.Canvas.EndScene;
  end;
end;

procedure TfrmFaceLandmark.FormCreate(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  SetPriorityClass(GetCurrentProcess, HIGH_PRIORITY_CLASS);

  FFaceLandmarkFMX := TFaceLandmarkFMX.Create(Self);
  FFaceLandmarkFMX.LoadModel(ModelsPath + 'face_landmark.tflite', 8);
{$ENDIF}
end;

procedure TfrmFaceLandmark.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FFaceLandmarkFMX.Destroy;
end;

end.
