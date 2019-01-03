unit uMain;

interface

{$I XSuperObject.inc}

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, DateUtils,Winapi.ShlObj,
  XSuperObject, FDxJoystick, FMX.TMSBaseControl, FMX.TMSGridCell,
  FMX.TMSGridOptions, FMX.TMSGridData, FMX.TMSCustomGrid, FMX.TMSGrid,
  FMX.StdCtrls, FMX.ListBox, FMX.Objects, FMX.Controls.Presentation;

type
  TMode = (mNone, mCalibration, mRecordingStart, mRecordingRunning);
  TWizard = (wFire, wPitchMin, wPitchMax, wNickMin, wNickMax, wGierMin, wGierMax, wRollMin, wRollMax);

  TfrmMain = class(TForm)
    btnCalib: TButton;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    comDevice: TComboBox;
    Label1: TLabel;
    tmrRun: TTimer;
    Label2: TLabel;
    comHID: TComboBox;
    lblStatus: TLabel;
    lblField: TLabel;
    lblValue: TLabel;
    grdSettings: TTMSFMXGrid;
    lblButton: TLabel;
    btnRecording: TButton;
    lblTimer: TLabel;
    DxJoystick: TFDxJoystick;
    saveCSV: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure comDeviceChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure comHIDChange(Sender: TObject);
    procedure btnCalibClick(Sender: TObject);
    procedure DxJoystickStateChange(Sender: TObject);
    procedure btnRecordingClick(Sender: TObject);
    procedure tmrRunTimer(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    fButtonPressed : Boolean;
    fMode : TMode;
    fStep : TWizard;
    fTimer : Int64;
    fObjectIndex : Int64;

    joystickMiddleStatus : ISuperObject;
    joystickNewStatus : ISuperObject;
    joystickReference : ISuperObject;
    joystickRecorder : ISuperObject;




    procedure fillJoystick;
    //procedure fillHid;
    procedure getJoystickValuesToObject(aReference : ISuperObject);
    procedure compareObjects(newStatus: ISuperObject);
    procedure nextPosition;
    procedure FillStandardValueTable;
    procedure fillReference(newStatus: ISuperObject);
    function getLocalPath: string;
    function GetSpecialFolderPath(Folder: Integer; CanCreate: Boolean): string;

    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

procedure TfrmMain.btnCalibClick(Sender: TObject);
begin
  btnCalib.Enabled := False;
  btnRecording.Enabled := False;
  comDevice.Enabled := False;
  lblButton.Text := '';


  getJoystickValuesToObject(joystickMiddleStatus);
  getJoystickValuesToObject(joystickNewStatus);

  lblStatus.Visible := True;
  lblStatus.Text := 'Lets start the callibration! Leave sticks in middle position and press the fire Button OR Return Key on Keyboard!';

  fMode := mCalibration;
  fStep := wFire;



end;

procedure TfrmMain.fillReference(newStatus: ISuperObject);
begin
  joystickRecorder.A['Results'].O[fObjectIndex].V['Time'] := fTimer;
  joystickRecorder.A['Results'].O[fObjectIndex].I['PitchCurrent'] := newStatus.I[joystickReference.S['PitchKey']];
  joystickRecorder.A['Results'].O[fObjectIndex].I['GierCurrent'] := newStatus.I[joystickReference.S['GierKey']];
  joystickRecorder.A['Results'].O[fObjectIndex].I['NickCurrent'] := newStatus.I[joystickReference.S['NickKey']];
  joystickRecorder.A['Results'].O[fObjectIndex].I['RollCurrent'] := newStatus.I[joystickReference.S['RollKey']];


end;

procedure TfrmMain.compareObjects(newStatus: ISuperObject);
var
  i : Integer;
  oldValue : Integer;
  newValue : Integer;
begin
  if (fStep <> wFire) then
  begin
    joystickMiddleStatus.First;
    newStatus.First;

    while not newStatus.EoF do
    begin
      if joystickMiddleStatus.CurrentValue.AsVariant <> null then
        oldValue := joystickMiddleStatus.CurrentValue.AsVariant
      else
        oldValue := 0;

      if newStatus.CurrentValue.AsVariant <> null then
        newValue := newStatus.CurrentValue.AsVariant
      else
        newValue := 0;

      if Abs(oldValue - newValue) > 500  then
      begin
        if fMode = mCalibration then
        begin
          case fStep of
            wPitchMin: begin
              joystickReference.I['PitchMin'] := newStatus.CurrentValue.AsVariant;
              joystickReference.S['PitchKey'] := newStatus.CurrentKey;
              lblField.Text := newStatus.CurrentKey;
              lblValue.Text := newStatus.CurrentValue.AsVariant;
              break;
            end;
            wPitchMax: begin
              if joystickReference.S['PitchKey'] = newStatus.CurrentKey then
              begin
                joystickReference.I['PitchMax'] := newStatus.CurrentValue.AsVariant;
                lblField.Text := newStatus.CurrentKey;
                lblValue.Text := newStatus.CurrentValue.AsVariant;

                // Check if the chanel is inverted
                if joystickReference.I['PitchMax'] < joystickReference.I['PitchMin'] then
                  joystickReference.B['PitchInv'] := true
                 else
                   joystickReference.B['PitchInv'] := false;

                break;
              end;
            end;
            wNickMin: begin
              if joystickReference.S['PitchKey'] <> newStatus.CurrentKey then
              begin
                joystickReference.I['NickMin'] := newStatus.CurrentValue.AsVariant;
                joystickReference.S['NickKey'] := newStatus.CurrentKey;
                lblField.Text := newStatus.CurrentKey;
                lblValue.Text := newStatus.CurrentValue.AsVariant;
                break;
              end;
            end;
            wNickMax: begin
              if joystickReference.S['NickKey'] = newStatus.CurrentKey then
              begin
                joystickReference.I['NickMax'] := newStatus.CurrentValue.AsVariant;
                lblField.Text := newStatus.CurrentKey;
                lblValue.Text := newStatus.CurrentValue.AsVariant;

                // Check if the chanel is inverted
                if joystickReference.I['NickMax'] < joystickReference.I['NickMin'] then
                  joystickReference.B['NickInv'] := true
                else
                   joystickReference.B['NickInv'] := false;

                break;
              end;
            end;
            wGierMin: begin
              if (joystickReference.S['PitchKey'] <> newStatus.CurrentKey) and
                 (joystickReference.S['NickKey'] <> newStatus.CurrentKey)  then
              begin
                joystickReference.I['GierMin'] := newStatus.CurrentValue.AsVariant;
                joystickReference.S['GierKey'] := newStatus.CurrentKey;
                lblField.Text := newStatus.CurrentKey;
                lblValue.Text := newStatus.CurrentValue.AsVariant;
                break;
              end;
            end;
            wGierMax: begin
              if joystickReference.S['GierKey'] = newStatus.CurrentKey then
              begin
                joystickReference.I['GierMax'] := newStatus.CurrentValue.AsVariant;
                lblField.Text := newStatus.CurrentKey;
                lblValue.Text := newStatus.CurrentValue.AsVariant;

                // Check if the chanel is inverted
                if joystickReference.I['GierMax'] < joystickReference.I['GierMin'] then
                  joystickReference.B['GierInv'] := true
                else
                   joystickReference.B['GierInv'] := false;

                break;
              end;
            end;
            wRollMin: begin
              if (joystickReference.S['PitchKey'] <> newStatus.CurrentKey) and
                 (joystickReference.S['NickKey'] <> newStatus.CurrentKey) and
                 (joystickReference.S['GierKey'] <> newStatus.CurrentKey) then
              begin
                joystickReference.I['RollMin'] := newStatus.CurrentValue.AsVariant;
                joystickReference.S['RollKey'] := newStatus.CurrentKey;
                lblField.Text := newStatus.CurrentKey;
                lblValue.Text := newStatus.CurrentValue.AsVariant;
                break;
              end;
            end;
            wRollMax: begin
              if joystickReference.S['RollKey'] = newStatus.CurrentKey then
              begin
                joystickReference.I['RollMax'] := newStatus.CurrentValue.AsVariant;
                lblField.Text := newStatus.CurrentKey;
                lblValue.Text := newStatus.CurrentValue.AsVariant;

                // Check if the chanel is inverted
                if joystickReference.I['RollMax'] < joystickReference.I['RollMin'] then
                  joystickReference.B['RollInv'] := true
                else
                   joystickReference.B['RollInv'] := false;
                break;
              end;
            end;
          end;

        end;

      end;
      joystickMiddleStatus.Next;
      newStatus.Next;
    end;
  end;

  if (fMode = mCalibration) and (fStep = wFire) then
  begin
    for I := 1 to 128 do
    begin
      if (joystickMiddleStatus.A['Buttons'].O[i - 1].B['B' + inttostr(i)] <> newStatus.A['Buttons'].O[i - 1].B['B'+ inttostr(i)])
      and newStatus.A['Buttons'].O[i - 1].B['B'+ inttostr(i)] then
      begin
        joystickReference.S['FireArray'] := 'Buttons';
        joystickReference.I['Position'] := i - 1;
        joystickReference.S['ButtonVariant'] := 'B' + inttostr(i);
        fButtonPressed := True;
        break
      end;
    end;

    if not (fButtonPressed) then
    begin

      for I := 0 to 11 do
        if (joystickMiddleStatus.A['ForceFeedbackState'].O[i].B['F'+ inttostr(i)] <> newStatus.A['ForceFeedbackState'].O[i].B['F'+ inttostr(i)])
         and newStatus.A['ForceFeedbackState'].O[i].B['F'+ inttostr(i)] then
        begin
          joystickReference.S['FireArray'] := 'ForceFeedbackState';
          joystickReference.I['Position'] := i;
          joystickReference.S['ButtonVariant'] := 'F' + inttostr(i);
          fButtonPressed := True;
          break;
        end;
    end;
  end else if (fMode = mCalibration) then
  begin
    if not fButtonPressed then
      fButtonPressed := newStatus.A[joystickReference.S['FireArray']].O[joystickReference.I['Position']].B[joystickReference.S['ButtonVariant']];
  end;



  if (fMode = mCalibration) and (fButtonPressed) then
    nextPosition;

end;


procedure TfrmMain.nextPosition;
begin
  fButtonPressed := False;
  case fStep of
    wFire : begin
      lblButton.Text := 'Button recognized!';
    end;
  end;

  FillStandardValueTable;

  if fStep = wRollMax then
  begin
    lblStatus.Visible := False;
    ForceDirectories(getLocalPath);
    joystickReference.SaveTo(getLocalPath + 'settings.json');
    fMode := mNone;
    fStep := wFire;
    btnCalib.Enabled := True;
    btnRecording.Enabled := True;
    comDevice.Enabled := True;
    exit;
  end;


  inc (fStep);

  case fStep of
    wPitchMin:
    begin
      lblStatus.Text := 'Go to minimum PITCH position and press RETURN!';
    end;

    wPitchMax:
    begin
      lblStatus.Text := 'Go to maximum PITCH position and press RETUEN';
    end;

    wNickMin:
    begin
      lblStatus.Text := 'Go to minimum NICK position and press RETUEN';
    end;

    wNickMax:
    begin
      lblStatus.Text := 'Go to maximum NICK position and press RETUEN';
    end;

    wGierMin:
    begin
      lblStatus.Text := 'Go to left GIER position and press RETUEN';
    end;

    wGierMax:
    begin
      lblStatus.Text := 'Go to right GIER position and press RETUEN';
    end;

    wRollMin:
    begin
      lblStatus.Text := 'Go to left ROLL position and press RETUEN';
    end;

    wRollMax:
    begin
      lblStatus.Text := 'Go to right ROLL position and press the fire Button!';
    end;

  end;


end;


procedure TfrmMain.tmrRunTimer(Sender: TObject);
var
  tmStep : TDateTime;
begin
  //
  tmStep := 0;
  tmrRun.Enabled := False;
  try
    fTimer := fTimer + tmrRun.Interval;

    tmStep := IncMilliSecond(tmStep, fTimer);
    lblTimer.Text := TimeToStr(tmStep);

  finally
    tmrRun.Enabled := True;
  end;
end;

procedure TfrmMain.FillStandardValueTable;
var
  i : Integer;
begin
  grdSettings.BeginUpdate;
  grdSettings.RowCount := 5;
  grdSettings.AllCells[1, 0] := 'Key';
  grdSettings.AllCells[2, 0] := 'Min';
  grdSettings.AllCells[3, 0] := 'Max';
  grdSettings.AllCells[4, 0] := 'Invert';


  i := 1;
  grdSettings.AllCells[0, i] := 'Pitch';
  grdSettings.AllCells[1, i] := joystickReference.S['PitchKey'];
  grdSettings.AllFloats[2, i] := joystickReference.I['PitchMin'];
  grdSettings.AllFloats[3, i] := joystickReference.I['PitchMax'];
  grdSettings.Booleans[4, i] := joystickReference.B['PitchInv'];
  inc(i);

  grdSettings.AllCells[0, i] := 'Nick';
  grdSettings.AllCells[1, i] := joystickReference.S['NickKey'];
  grdSettings.AllFloats[2, i] := joystickReference.I['NickMin'];
  grdSettings.AllFloats[3, i] := joystickReference.I['NickMax'];
  grdSettings.Booleans[4, i] := joystickReference.B['NickInv'];
  inc(i);

  grdSettings.AllCells[0, i] := 'Gier';
  grdSettings.AllCells[1, i] := joystickReference.S['GierKey'];
  grdSettings.AllFloats[2, i] := joystickReference.I['GierMin'];
  grdSettings.AllFloats[3, i] := joystickReference.I['GierMax'];
  grdSettings.Booleans[4, i] := joystickReference.B['GierInv'];
  inc(i);

  grdSettings.AllCells[0, i] := 'Roll';
  grdSettings.AllCells[1, i] := joystickReference.S['RollKey'];
  grdSettings.AllFloats[2, i] := joystickReference.I['RollMin'];
  grdSettings.AllFloats[3, i] := joystickReference.I['RollMax'];
  grdSettings.Booleans[4, i] := joystickReference.B['RollInv'];

  grdSettings.EndUpdate;


end;

procedure TfrmMain.btnRecordingClick(Sender: TObject);
begin
//
  lblStatus.Text := 'Press RETURN or Key to start / stopp recording!';
  lblStatus.Visible := True;
  btnCalib.Enabled := False;
  btnRecording.Enabled := False;
  comDevice.Enabled := False;
  fMode := mRecordingStart;

end;

procedure TfrmMain.comDeviceChange(Sender: TObject);
begin
  comHID.ItemIndex := -1;
  if comDevice.IsFocused then
  begin
    DxJoystick.Device := comDevice.ItemIndex + 1;
    DxJoystick.Active := True;
  end;
end;

procedure TfrmMain.comHIDChange(Sender: TObject);
begin
  comDevice.ItemIndex := -1;
end;


procedure TfrmMain.DxJoystickStateChange(Sender: TObject);
var
  csvTextFile : TextFile;
  j: integer;
begin
//
  case fMode of
    mCalibration :
    begin
      joystickNewStatus := SO;
      getJoystickValuesToObject(joystickNewStatus);
      compareObjects(joystickNewStatus);
    end;


    mRecordingStart :
    begin
      joystickNewStatus := SO;
      getJoystickValuesToObject(joystickNewStatus);
      if fButtonPressed or joystickNewStatus.A[joystickReference.S['FireArray']].O[joystickReference.I['Position']].B[joystickReference.S['ButtonVariant']] then
      begin
        fButtonPressed := False;
        tmrRun.Enabled := True;
        joystickRecorder := SO;
        fTimer := 0;
        fObjectIndex := 0;
        lblStatus.Text := 'Press RETUN to stop recording!';
        fMode := mRecordingRunning;
      end;
    end;


    mRecordingRunning :
    begin
      joystickNewStatus := SO;
      getJoystickValuesToObject(joystickNewStatus);
      inc(fObjectIndex);
      fillReference(joystickNewStatus);

      if fButtonPressed or joystickNewStatus.A[joystickReference.S['FireArray']].O[joystickReference.I['Position']].B[joystickReference.S['ButtonVariant']] then
      begin
        fButtonPressed := False;
        tmrRun.Enabled := False;
        lblStatus.Visible := False;
        btnCalib.Enabled := True;
        btnRecording.Enabled := True;
        comDevice.Enabled := True;

        if saveCSV.Execute then
        begin
          AssignFile(csvTextFile, saveCSV.FileName);
          Rewrite(csvTextFile);
          writeln(csvTextFile, '"time";"pitch";"gier";"nick";"roll"');
            for j := 0 to joystickRecorder.A['Results'].Length - 1 do
            begin
              try
                // ToDo: Hier muss die Umrechnung noch rein.
                writeln(csvTextFile,
                Inttostr(joystickRecorder.A['Results'].O[j].I['Time']) + ';' +
                Inttostr(joystickRecorder.A['Results'].O[j].I['PitchCurrent'])  + ';' +
                Inttostr(joystickRecorder.A['Results'].O[j].I['GierCurrent']) + ';' +
                Inttostr(joystickRecorder.A['Results'].O[j].I['NickCurrent']) + ';' +
                Inttostr(joystickRecorder.A['Results'].O[j].I['RollCurrent'])  + ';');
              except;

              end;
            end;

          CloseFile(csvTextFile);
        end;

        fMode := mNone;
      end;
    end;
  end;
end;

procedure TfrmMain.getJoystickValuesToObject(aReference : ISuperObject);
var
  bButtons : Word;
  i : Integer;
begin
  with DxJoystick do
  begin
    aReference.I['AccelerationX'] := AccelerationX;
    aReference.I['AccelerationY'] := AccelerationY;
    aReference.I['AccelerationZ'] := AccelerationZ;
    aReference.I['AccelerationRX'] := AccelerationRX;
    aReference.I['AccelerationRY'] := AccelerationRY;
    aReference.I['AccelerationRZ'] := AccelerationRZ;
    aReference.I['AccelerationSlider1'] := AccelerationSlider1;
    aReference.I['AccelerationSlider2'] := AccelerationSlider2;

    for I := 1 to 128 do
      aReference.A['Buttons'].O[i - 1].B['B' + inttostr(i)] :=  Button[i];

    aReference.A['ForceFeedbackState'].O[0].B['B0'] := fsEmpty in ForceFeedbackState;
    aReference.A['ForceFeedbackState'].O[1].B['B1'] := fsStopped in ForceFeedbackState;
    aReference.A['ForceFeedbackState'].O[2].B['B2'] := fsPaused in ForceFeedbackState;
    aReference.A['ForceFeedbackState'].O[3].B['B3'] := fsActuatorsOn in ForceFeedbackState;
    aReference.A['ForceFeedbackState'].O[4].B['B4'] := fsActuatorsOff in ForceFeedbackState;
    aReference.A['ForceFeedbackState'].O[5].B['B5'] := fsPowerOn in ForceFeedbackState;
    aReference.A['ForceFeedbackState'].O[6].B['B6'] := fsPowerOff in ForceFeedbackState;
    aReference.A['ForceFeedbackState'].O[7].B['B7'] := fsSafetySwitchOn in ForceFeedbackState;
    aReference.A['ForceFeedbackState'].O[8].B['B8'] := fsSafetySwitchOff in ForceFeedbackState;
    aReference.A['ForceFeedbackState'].O[9].B['B9'] := fsUserSwitchOn in ForceFeedbackState;
    aReference.A['ForceFeedbackState'].O[10].B['B10'] := fsUserSwitchOff in ForceFeedbackState;
    aReference.A['ForceFeedbackState'].O[11].B['B11'] := fsDeviceLost in ForceFeedbackState;

    aReference.I['ForceX'] := ForceX;
    aReference.I['ForceY'] := ForceY;
    aReference.I['ForceZ'] := ForceZ;

    aReference.I['ForceRX'] := ForceRX;
    aReference.I['ForceRY'] := ForceRY;
    aReference.I['ForceRZ'] := ForceRZ;

    aReference.I['ForceSlider1'] := ForceSlider1;
    aReference.I['ForceSlider2'] := ForceSlider2;
    aReference.I['PointOfView1'] := PointOfView1;

    aReference.I['PointOfView2'] := PointOfView2;
    aReference.I['PointOfView3'] := PointOfView3;
    aReference.I['PointOfView4'] := PointOfView4;

    aReference.I['PositionX'] := PositionX;
    aReference.I['PositionY'] := PositionY;

    aReference.I['PositionZ'] := PositionZ;
    aReference.I['PositionRx'] := PositionRx;
    aReference.I['PositionRy'] := PositionRy;
    aReference.I['PositionRz'] := PositionRz;
    aReference.I['PositionSlider1'] := PositionSlider1;
    aReference.I['PositionSlider2'] := PositionSlider2;


    aReference.I['VelocityX'] := VelocityX;
    aReference.I['VelocityY'] := VelocityY;
    aReference.I['VelocityZ'] := VelocityZ;
    aReference.I['VelocityRX'] := VelocityRX;
    aReference.I['VelocityRY'] := VelocityRY;
    aReference.I['VelocityRZ'] := VelocityRZ;
    aReference.I['VelocitySlider1'] := VelocitySlider1;
    aReference.I['VelocitySlider2'] := VelocitySlider2;

  end;

end;

procedure TfrmMain.fillJoystick();
var
  i : Integer;

begin
  for I := 1 to DxJoystick.DeviceCount do
  begin
    try
      DxJoystick.Device := I;
      DxJoystick.Active := True;
      comDevice.Items.Add(DxJoystick.InstanceName);
    finally
      DxJoystick.Active := False;
    end;
  end;

  if comDevice.Items.Count = 1 then
  begin
    comDevice.ItemIndex := 0;
    DxJoystick.Device := 1;
    DxJoystick.Active := True;
    btnCalib.Enabled := True;
    comDevice.Enabled := True;

  end;
end;

{
procedure TfrmMain.fillHid();
var
  i : Integer;
  Devices: TFHidDevices;
  Device: Integer;

begin
  Devices := Hid.Enumerate;
  for Device := 0 to Length(Devices) - 1 do
  begin
    comHID.Items.Add(Devices[Device].ProductName);
  end;
end;
}

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //
  if (grdSettings.RowCount > 4) then
  begin
    joystickReference.I['PitchMin'] := StrToInt(grdSettings.AllCells[2, 1]);
    joystickReference.I['PitchMax'] := StrToInt(grdSettings.AllCells[3, 1]);

    joystickReference.I['NickMin'] := StrToInt(grdSettings.AllCells[2, 2]);
    joystickReference.I['NickMax'] := StrToInt(grdSettings.AllCells[3, 2]);

    joystickReference.I['RollMin'] := StrToInt(grdSettings.AllCells[2, 3]);
    joystickReference.I['RollMax'] := StrToInt(grdSettings.AllCells[3, 3]);

    joystickReference.I['GierMin'] := StrToInt(grdSettings.AllCells[2, 4]);
    joystickReference.I['GierMax'] := StrToInt(grdSettings.AllCells[3, 4]);

    joystickReference.B['PitchInv'] := grdSettings.CheckBoxState[4, 1];
    joystickReference.B['NickInv'] := grdSettings.CheckBoxState[4, 2];
    joystickReference.B['RollInv'] := grdSettings.CheckBoxState[4, 3];
    joystickReference.B['GierInv'] := grdSettings.CheckBoxState[4, 4];

    joystickReference.SaveTo(getLocalPath + 'settings.json');
  end;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  aFile : TFileStream;
  aJson : String;
begin
  //Hid := TFHid.Create;

  fMode := mNone;
  DxJoystick.OnStateChange := DxJoystickStateChange;



  fillJoystick;

  joystickNewStatus := SO;
  joystickReference := SO;
  joystickMiddleStatus := SO;
  joystickRecorder := SO;

  lblStatus.Visible := False;



  if FileExists(getLocalPath + 'settings.json') then
  begin
    joystickReference := TSuperObject.ParseFile(getLocalPath + 'settings.json');

    FillStandardValueTable;
    btnRecording.Enabled := True;
  end;



  //fillHid;

end;

function TfrmMain.GetSpecialFolderPath(Folder: Integer; CanCreate: Boolean): string;

// Gets path of special system folders
//
// Call this routine as follows:
// GetSpecialFolderPath (CSIDL_PERSONAL, false)
//        returns folder as result
//
var
   FilePath: array [0..255] of char;

begin
  SHGetSpecialFolderPath(0, @FilePath[0], FOLDER, CanCreate);
  Result := FilePath;
  //Result := 'c:\ProgramData\';
end;

function TfrmMain.getLocalPath : string;
begin
  Result := GetSpecialFolderPath(CSIDL_COMMON_APPDATA , True) + '\avisoft_recorder\';
end;


procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  //Hid.Free;
end;

procedure TfrmMain.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
  //lblValue.Text :=  KeyChar;
  if Key = 13 then
  begin
    fButtonPressed := True;
    DxJoystickStateChange(Self);
  end;
end;

end.
