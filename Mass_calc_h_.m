clc
clear all
close all
%#include "MDR1986VE3.h"

%T = readtable('Results_2024_06_11.xlsx',6);
[data, text, raw] = xlsread('Results_2024_06_11.xlsx',6);

Time = data(:,1); 
%Емкости
    for i=1:34
    CapacityArr(i) = struct('Val',zeros(length(data(:,1)),1),...
                            'NoData',true,...
                            'LineCut',false,...
                            'OutOfRange',false);
    end

LH_TK2_PR1 = data(:,2);%CapSensId_Sec2_L_DT1
LH_TK2_PR2 = data(:,3);%CapSensId_Sec2_L_DT2
LH_TK2_PR3 = data(:,4);%CapSensId_Sec2_L_DT3
LH_TK2_PR4 = data(:,5);%CapSensId_Sec2_L_DT4
LH_TK2_PR5 = data(:,6);%CapSensId_Sec2_L_DT5
LH_TK2_PR6 = data(:,7);%CapSensId_Sec2_L_DT6
LH_TK2_PR7andTS1 = data(:,8);%CapSensId_Sec2_L_DT7

LH_TK3_PR8 = data(:,9);%CapSensId_Sec3_L_DT8
LH_TK3_PR9 = data(:,10);%CapSensId_Sec3_L_DT9
LH_TK3_PR10 = data(:,11);%CapSensId_Sec3_L_DT10
LH_TK3_PR11 = data(:,12);%CapSensId_Sec3_L_DT11
LH_TK3_PR12 = data(:,13);%CapSensId_Sec3_L_DT12

LH_TK3_PR13_COL = data(:,14);%CapSensId_RO_L_DT13

CT_PR14 = data(:,15);%CapSensId_centr_DT14
CT_PR15 = data(:,16);%CapSensId_centr_DT15
CT_PR16 = data(:,17);%CapSensId_centr_DT16
CT_PR17 = data(:,18);%CapSensId_centr_DT17
CT_PR18andTS2 = data(:,19);%CapSensId_centr_DT18
CT_PR19 = data(:,20);%CapSensId_centr_DT19

RH_TK3_PR20_COL = data(:,21);%CapSensId_RO_R_DT20

RH_TK3_PR21 = data(:,22); %CapSensId_Sec3_R_DT21
RH_TK3_PR22 = data(:,23);%CapSensId_Sec3_R_DT22
RH_TK3_PR23 = data(:,24);%CapSensId_Sec3_R_DT23
RH_TK3_PR24 = data(:,25);%CapSensId_Sec3_R_DT24
RH_TK3_PR25 = data(:,26);%CapSensId_Sec3_R_DT25

RH_TK2_PR26andTS3 = data(:,27);%CapSensId_Sec2_R_DT26
RH_TK2_PR27 = data(:,28);%CapSensId_Sec2_R_DT27
RH_TK2_PR28 = data(:,29);%CapSensId_Sec2_R_DT28
RH_TK2_PR29 = data(:,30);%CapSensId_Sec2_R_DT29
RH_TK2_PR30 = data(:,31);%CapSensId_Sec2_R_DT30
RH_TK2_PR31 = data(:,32);%CapSensId_Sec2_R_DT31
RH_TK2_PR32 = data(:,33);%CapSensId_Sec2_R_DT32

LH_DENSITY = data(:,34);%WorkDensity_DHT1
RH_DENSITY = data(:,35);%WorkDensity_DHT1

LH_TK2_QTY = data(:,36);
LH_TK3_QTY = data(:,37);
CT_QTY = data(:,38);

RH_TK3_QTY = data(:,39);
RH_TK2_QTY = data(:,40);

LH_FEED_QTY = data(:,41);
RH_FEED_QTY = data(:,42);

IRS1_324_pitch_angle = data(:,43);%PRPrep_outData.OutPitch
IRS1_325_roll_angle = data(:,44);%PRPrep_outData.OutRoll

W_ON_W = data(:,45);

LH_CIC = data(:,46);
RH_CIC = data(:,47);

LH_TS_TEMP = data(:,48);
RH_TS_TEMP = data(:,49);
CT_TS_TEMP = data(:,50);
LH_FCS_TS_TEMP = data(:,51);%WorkTemperature_DHT1
RH_FCS_TS_TEMP = data(:,52);%WorkTemperature_DHT2

TOT_QTY = data(:,53);

IRS1_331_body_longitudinal_acceleration = data(:,54);
IRS1_332_body_lateral_acceleration = data(:,55);
IRS1_333_body_normal_acceleration = data(:,56);

%type suit75_all_angles.xml
%readtable('СУИТ75_23_05_24_все углы_Бак LH_FEED_QTY.xml')
%/ Количество топливных баков
TanksNum = 7;

%/ \name TankId_Group Идентификаторы топливных баков
%/ @{
TankId_Centr = 0+1;            %/< Идентификатор центрального топливного бака
TankId_RO_Left = 1+1;          %/< Идентификатор расходного отсека левого борта
TankId_Section21_Left = 2+1;   %/< Идентификатор бака 2 левого борта
TankId_Section31_Left = 3+1;   %/< Идентификатор бака 3 левого борта
TankId_RO_Right = 4+1;         %/< Идентификатор расходного отсека правого борта
TankId_Section21_Right = 5+1;  %/< Идентификатор бака 2 правого борта
TankId_Section31_Right = 6+1;  %/< Идентификатор бака 3 правого борта
TankId_DHT1 = 7+1;             %/< Идентификатор ДХТ1
TankId_DHT2 = 8+1;             %/< Идентификатор ДХТ2

Tank = [1,2,3,4,5,6,7,8,9];
%/ @}
%/ Количество топливных баков в градуировочных таблицах (только баки одного борта)
GradTanksNum = 4;

%/ Общее количество групп в баках (включая общие)
GroupsNumForTanks = 10;

%/ \name GradTankGroupId_Group Идентификаторы груп по бакам
%/ @{
GradTankGroupId_CT_All = 0+1;
GradTankGroupId_CT_G1 = 1+1;
GradTankGroupId_CT_G2 = 2+1;
GradTankGroupId_FEED_All = 3+1;
GradTankGroupId_TK2_All =  4+1;
GradTankGroupId_TK2_G1 = 5+1;
GradTankGroupId_TK2_G2 = 6+1;
GradTankGroupId_TK3_All = 7+1;
GradTankGroupId_TK3_G1 = 8+1;
GradTankGroupId_TK3_G2 = 9+1;
%/ @}

%/ \name GradTankId Идентификаторы топливных баков в градуировочных таблицах
%/ @{
GradTankId_Centr =  0+1;
GradTankId_RO = 1+1;
GradTankId_Section21 = 2+1;
GradTankId_Section31 = 3+1;
%/ @}

%/ Количество емкостных датчиков в системе
CapSensNum =  32 + 2; %2 - ёмкостные датчики ДХТ

%/ Количестко термосопротивлений в системе
ResSensNum = 5;

%Иденитфикатоы емкостных датчиков в массиве
%/ \name CapSensId.CapSensId_centr Иденитфикаторы емкостных датчиков центрального бака в массиве
%/ @{ 

CapSensId.CapSensId_centr_DT14 = 0+1;
CapSensId.CapSensId_centr_DT15 = 1+1;
CapSensId.CapSensId_centr_DT16 = 2+1;
CapSensId.CapSensId_centr_DT17 = 3+1;
CapSensId.CapSensId_centr_DT18 = 4+1;
CapSensId.CapSensId_centr_DT19 = 5+1;
%Заполнение
CapacityArr(CapSensId.CapSensId_centr_DT14).Val = CT_PR14;
CapacityArr(CapSensId.CapSensId_centr_DT15).Val = CT_PR15;
CapacityArr(CapSensId.CapSensId_centr_DT16).Val = CT_PR16;
CapacityArr(CapSensId.CapSensId_centr_DT17).Val = CT_PR17;
CapacityArr(CapSensId.CapSensId_centr_DT18).Val = CT_PR18andTS2;
CapacityArr(CapSensId.CapSensId_centr_DT19).Val = CT_PR19;
%/ @}

%/ \name CapSensId.CapSensId_RO_L Иденитфикаторы емкостных датчиков РО левый в массиве
%/ @{
CapSensId.CapSensId_RO_L_DT13 = 6+1;
CapacityArr(CapSensId.CapSensId_RO_L_DT13).Val = LH_TK3_PR13_COL;
%/ @}

%/ \name CapSensId.CapSensId_RO_R Иденитфикаторы емкостных датчиков РО правый в массиве
%/ @{
CapSensId.CapSensId_RO_R_DT20 = 7+1;
CapacityArr(CapSensId.CapSensId_RO_R_DT20).Val = RH_TK3_PR20_COL;
%/ @}

%/ \name CapSensId.CapSensId_Sec3_L Иденитфикаторы емкостных датчиков бака 3 левый в массиве
%/ @{
CapSensId.CapSensId_Sec3_L_DT8 = 8+1;
CapSensId.CapSensId_Sec3_L_DT9 = 9+1;
CapSensId.CapSensId_Sec3_L_DT10 = 10+1;
CapSensId.CapSensId_Sec3_L_DT11 = 11+1;
CapSensId.CapSensId_Sec3_L_DT12 = 12+1;
%Заполнение
CapacityArr(CapSensId.CapSensId_Sec3_L_DT8).Val = LH_TK3_PR8;
CapacityArr(CapSensId.CapSensId_Sec3_L_DT9).Val = LH_TK3_PR9;
CapacityArr(CapSensId.CapSensId_Sec3_L_DT10).Val = LH_TK3_PR10;
CapacityArr(CapSensId.CapSensId_Sec3_L_DT11).Val = LH_TK3_PR11;
CapacityArr(CapSensId.CapSensId_Sec3_L_DT12).Val = LH_TK3_PR12;
%/ @}

%/ \name CapSensId.CapSensId_Sec3_R Иденитфикаторы емкостных датчиков бака 3 правый в массиве
%/ @{
CapSensId.CapSensId_Sec3_R_DT21 = 13+1;
CapSensId.CapSensId_Sec3_R_DT22 = 14+1;
CapSensId.CapSensId_Sec3_R_DT23 = 15+1;
CapSensId.CapSensId_Sec3_R_DT24 = 16+1;
CapSensId.CapSensId_Sec3_R_DT25 = 17+1;
%Заполнение
CapacityArr(CapSensId.CapSensId_Sec3_R_DT21).Val = RH_TK3_PR21;
CapacityArr(CapSensId.CapSensId_Sec3_R_DT22).Val = RH_TK3_PR22;
CapacityArr(CapSensId.CapSensId_Sec3_R_DT23).Val = RH_TK3_PR23;
CapacityArr(CapSensId.CapSensId_Sec3_R_DT24).Val = RH_TK3_PR24;
CapacityArr(CapSensId.CapSensId_Sec3_R_DT25).Val = RH_TK3_PR25;
%/ @}

%/ \name CapSensId.CapSensId_Sec2_L Иденитфикаторы емкостных датчиков бака 2 левый в массиве
%/ @{
CapSensId.CapSensId_Sec2_L_DT1 = 18+1;
CapSensId.CapSensId_Sec2_L_DT2 = 19+1;
CapSensId.CapSensId_Sec2_L_DT3 = 20+1;
CapSensId.CapSensId_Sec2_L_DT4 = 21+1;
CapSensId.CapSensId_Sec2_L_DT5 = 22+1;
CapSensId.CapSensId_Sec2_L_DT6 = 23+1;
CapSensId.CapSensId_Sec2_L_DT7 = 24+1;
%Заполнение
CapacityArr(CapSensId.CapSensId_Sec2_L_DT1).Val = LH_TK2_PR1;
CapacityArr(CapSensId.CapSensId_Sec2_L_DT2).Val = LH_TK2_PR2;
CapacityArr(CapSensId.CapSensId_Sec2_L_DT3).Val = LH_TK2_PR3;
CapacityArr(CapSensId.CapSensId_Sec2_L_DT4).Val = LH_TK2_PR4;
CapacityArr(CapSensId.CapSensId_Sec2_L_DT5).Val = LH_TK2_PR5;
CapacityArr(CapSensId.CapSensId_Sec2_L_DT6).Val = LH_TK2_PR6;
CapacityArr(CapSensId.CapSensId_Sec2_L_DT7).Val = LH_TK2_PR7andTS1;
%/ @}

%/ \name CapSensId.CapSensId_Sec2_R Иденитфикаторы емкостных датчиков бака 2 правый в массиве
%/ @{
CapSensId.CapSensId_Sec2_R_DT26 = 25+1;
CapSensId.CapSensId_Sec2_R_DT27 = 26+1;
CapSensId.CapSensId_Sec2_R_DT28 = 27+1;
CapSensId.CapSensId_Sec2_R_DT29 = 28+1;
CapSensId.CapSensId_Sec2_R_DT30 = 29+1;
CapSensId.CapSensId_Sec2_R_DT31 = 30+1;
CapSensId.CapSensId_Sec2_R_DT32 = 31+1;
%Заполнение
CapacityArr(CapSensId.CapSensId_Sec2_R_DT26).Val = RH_TK2_PR26andTS3;
CapacityArr(CapSensId.CapSensId_Sec2_R_DT27).Val = RH_TK2_PR27;
CapacityArr(CapSensId.CapSensId_Sec2_R_DT28).Val = RH_TK2_PR28;
CapacityArr(CapSensId.CapSensId_Sec2_R_DT29).Val = RH_TK2_PR29;
CapacityArr(CapSensId.CapSensId_Sec2_R_DT30).Val = RH_TK2_PR30;
CapacityArr(CapSensId.CapSensId_Sec2_R_DT31).Val = RH_TK2_PR31;
CapacityArr(CapSensId.CapSensId_Sec2_R_DT32).Val = RH_TK2_PR32;
%/ @}

%/ \name CapSensId.CapSensId_DHT Иденитфикаторы емкостных датчиков ДХТ в массиве
%/ @{
CapSensId.CapSensId_Sec3_L_DHT1 = 32+1;%LH_CIC
CapSensId.CapSensId_Sec3_R_DHT2 = 33+1;%RH_CIC
CapacityArr(CapSensId.CapSensId_Sec3_L_DHT1).Val = LH_CIC;
CapacityArr(CapSensId.CapSensId_Sec3_R_DHT2).Val = RH_CIC;

%/ @}

%
%/ \name ResSensId Иденитфикаторы термосопротивлений в массиве
%/ @{
ResSensId_centr_DT18 = 0+1;  %Центральный бак
ResSensId_Sec2_L_DT7 = 1+1;  %Отсек 2 левый
ResSensId_Sec2_R_DT26 = 2+1;  %Отсек 2 правый
ResSensId_Sec3_L_DHT1 = 3+1; %Отсек 3 левый. Тербодатчик ДХТ1
ResSensId_Sec3_R_DHT2 = 4+1; %Отсек 3 правый. Тербодатчик ДХТ2
%/ @}

%------------------------------------------------------------------------------

%/ Размер одной записи в стартовой таблице
Memory_MainTableRecordSize = 4;

%/ Размер стартовой таблицы
Memory_MainTableSize = Memory_MainTableRecordSize*GroupsNumForTanks + 2;

%/ Размер одной записи в таблице векторов
Memory_VectorTableRecordSize = 10;

%/ Размер одной записи в градуировочной таблице
Memory_GradTableRecordSize = 8;

%/ Структура для хранения записей главых таблиц микросхем
MainTableRecordStructDef = struct('Address',zeros(100,1),...
                                   'VectorRecordsNum',zeros(100,1));

%/ Структура для хранения данных одного вектора, указывающего на таблицу
VectorTableRecordStructDef = struct('TankNum',zeros(1,1),...
                                     'Pitch',zeros(1,1),...
                                     'Roll',zeros(1,1),...
                                     'RecordNum',zeros(1,1),...
                                     'Address',zeros(1,1),...
                                     'CRC8',zeros(1,1)); 

%/ Структура для хранения одной записи градуировочной таблицы
GradTableRecordStructDef = struct('Capacity',zeros(1,1),'Volume',zeros(1,1));

%/ Тип анализируемого параметра: емкость, плотность, сопротивление.
ParmEnumType = struct('ParmType_Cap',zeros(1,1),...
    'ParmType_Res',zeros(1,1),...
    'ParmType_Dens',zeros(1,1));

%/ Структура для хранения параметров получаемых от БКД 
%Значение параметра 
%Признак того что данные от устройства не поступили
% Обрыв линии. 
%Параметр за границами допустимого диапазона
for i=1:5
BKD_Param_Stuct(i) = struct('Val',zeros(1,1),...
                         'NoData',zeros(1,1),...
                         'LineCut',zeros(1,1),...
                         'OutOfRange',zeros(1,1),...
                         'TempArr',zeros(1,7));
end
%/ Структура данных хранящая данные матрицы состояния параметра
BKD_ParmValStateMatrixStruct =  struct('Rezerv',0,...
                                       'Sensor_Cut',0,...
                                       'Sensor_OutOfRage',0,...
                                       'Sensor_InFuel',0,...
                                       'Sensor_Test',0,...
                                       'Sensor_Short',0);
%/ Объединение для преобразования данных матрицы состояния параметров union
StateMatrixUnDef =  struct('BKD_ParmValStateMatrixStruct_StructData',zeros(1,1),...
                           'BitData',zeros(1,1));
%-----------------------------------------------------------------------------

%/ Идентификатор группы датчиков в баке
SensorsGroupEnumDef =  struct('GrType_All',1,'GrType_G1',2,'GrType_G2',3);

%/ Структура для хранения результатов вычисления масс
MassDataStructDef =  struct('Value',zeros(1,1),'InvalidData',0,'NoData',0);
%------------------------------------------------------------------------------

%/ Структура отказов БКД МТ
BKD_MT_Errors_StructDef =  struct('BKD_L_MT1_Failure',0,...%/< Отказ БКД лев устройство 1
                                  'BKD_L_MT2_Failure',0,...
                                  'BKD_R_MT1_Failure',0,...
                                  'BKD_R_MT2_Failure',0,...
                                   ...
                                  'Left_DT_Failure',0,...
                                  'Right_DT_Failure',0,...
                                  'Centr_DT_Failure',0);  
%------------------------------------------------------------------------------
%/ Температурная поправка плотности топлива
kp_t_i = 0.768;

%/ Температурная поправка диэлектрической проницаемости
ke_t_i = 0.00149;

%/ Значение плотности топлива по умолчанию
p_def =  788;

%/ Значение диэлектрической проницаемости топлива по умолчанию
et_20_def = 2.096;

%------------------------------------------------------------------------------
%---ПРОТОТИПЫ ФУНКЦИЙ----------------------------------------------------------
% void MassCalc_SetDefaultVals();%Установка значений по умолчанию для параметров учавствующих в расчёте масс
% void MassCalc_FillFuelSensorsArr();%Преобразованиние принятых по CAN данных в значения параметров
% void MassCalc_Wings_DT_Failure();%Расчёт отказов датчиков ДТ в крыльях и центральном баке
% 
% MassDataStructDef MassCalc_GetTankTemperature(uint8_t Tank);%Формирует значение температуры в указанном баке на основании показаний термодатчиков
% 
% void MassCalc_ReadStartTables();%Чтение наборов стартовых таблиц микросхем памяти
% void MassCalc_AllTanksFuelMassCalc(void);%Вычисление массы топлива в каждом баке;
% 
% float GetSummCapForGroup(uint8_t Tank, SensorsGroupEnumDef Group);%Формирование суммарной ёмкости группы датчиков в баке

%~
%~ @file MassCalculation.c
%~ @date 09.09.2020
%~ @author Зяблицкий Александр Валерьевич
%~ @brief Предназначен для выполнения расчётов масс топлива в баках
%~

%#include "TanksInformation.h"
%TankId_Section31_Right
%/ Значение минимального шага крена и тангажа в градуировочных таблицах
GradTableStep 	=	1;

%/ Значение половины минимального шага крена и тангажа в градуировочных таблицах
GradTableHalhStep =	(GradTableStep/2);

%/ Значение количества хранмых значений предыдущего состояния ёмкости
LastCapArrSize    =      5;

%/ Количество сохраняемых предыдущих значений масс топлива в баках 
LastMassArrSize    =     15;

%/ Значение относительной диэлектрической проницаемости воздуха при 19 С
e_v_i              =     1.000576;

%CapSensNum = 1;
CAN_dev_LinesNum = 1;
CAN_dev_BKD_L_MT1_MesNum = 1;
CAN_dev_BKD_L_MT2_MesNum = 1;
CAN_dev_BKD_R_MT1_MesNum = 1;
CAN_dev_BKD_R_MT2_MesNum = 1;
Memory2_ChipsNum = 1;

%MassDataStructDef = struct();
%BKD_Param_Stuct = struct();
%SensorsGroupEnumDef = struct();
%BKD_MT_Errors_StructDef = struct();

MassDataStructDef.SummFuelMass = 0;%/< Суммарное значение массы топлива
MassDataStructDef.TankMassArr( TanksNum ) = 0;%/< Массы топлива в баках
MassDataStructDef.TankDensityArr( TanksNum ) = 0;%/< Массив плотностей топлива в баках
MassDataStructDef.TankVolumeArr( TanksNum ) = 0;%/< Массив объёмов топлива по бакам

 LastMassArr( TanksNum,LastMassArrSize ) =0;%Последние значения масс для медианного фильтра
 LastMassArrPointer = 1;%Указатель текущей позиции в массиве последних значений масс

SensorsGroupEnumDef.TankSensorsWorkGroup( TanksNum ) =0;%/< Указатель того по какой группе датчиков необходимо считать бак
% BKD_Param_Stuct.CapacitySummArr( TanksNum ) = 0;%/< Суммы ёмкостей датчиков по бакам
% BKD_Param_Stuct.CapacityArr( CapSensNum ) = 0;%/< Массив ёмкостей датчиков
% BKD_Param_Stuct.TempArr( ResSensNum ) = 0;%/< Массив температур датчиков

 LastCapArr( CapSensNum, LastCapArrSize ) = 0;%/< Для каждого ёмкостного датчика копится 5 последних значений
 LastCapArrPointer = 0;%/< Указатель текущей позиции в массиве накопленных значений ёмкостей

MassDataStructDef.MinTemp = 0;%/< Значение минимальной температуры
MassDataStructDef.AverageTemp = 0;%/< Среднее значение температуры
MassDataStructDef.e_t_i = 0;

BKD_MT_Errors_StructDef.BKD_MT_Errors = 0;%/< Отказы модулей топливомеров БКД

%extern void * CAN_dev_MessageDataArr(CAN_dev_ConnectedDevNum);%/< Приёмный буфер CAN %(номер устройства,номер лини CAN,номер посылки)

%Массивы принимаемых данных
%БКД левый CAN_dev_RecMessageDef
CAN_dev_BKD_L_MT1_Arr(CAN_dev_LinesNum,CAN_dev_BKD_L_MT1_MesNum) = 0;%/< Приёмный буфер данных CAN от БКД лев МТ1
CAN_dev_BKD_L_MT2_Arr(CAN_dev_LinesNum,CAN_dev_BKD_L_MT2_MesNum) = 0;%/< Приёмный буфер данных CAN от БКД лев МТ2

%БКД правый CAN_dev_RecMessageDef 
CAN_dev_BKD_R_MT1_Arr(CAN_dev_LinesNum,CAN_dev_BKD_R_MT1_MesNum) = 0;%/< Приёмный буфер данных CAN от БКД прав МТ1
CAN_dev_BKD_R_MT2_Arr(CAN_dev_LinesNum,CAN_dev_BKD_R_MT2_MesNum) = 0;%/< Приёмный буфер данных CAN от БКД прав МТ2

%Буфер для чтения данных из памяти
Memory_Com_Arr = zeros(100,1);%/< Буфер для чтения данных из микросхемы памяти (Memory_Com_Arr_Size)

%Стартовые таблицы микросхем памяти
MainTableRecordStructDef.Chips_MainTable(Memory2_ChipsNum,GroupsNumForTanks) = 0;%/< Буфер в котором хранятся стартовые таблицы из микросхем памяти

AllChipsFault = false;%/< Признак того что все три микросхемы памяти неработоспособны

%/Значение количества хранмых значений предыдущего состояния ёмкости датчиков ДХТ
 DHT_Cap_average_size = 10;

 DHT1_Cap_average_pointer = 0;%/< Указатель текущей позиции в массиве последних значений емкостей ДХТ1
 DHT1_Cap_average_pointer_cycle = false;%/< Признак того что указатель позиции в массиве последних значений емкостей ДХТ1 (DHT1_Cap_average_pointer) сделал круг
 DHT1_Cap_average(DHT_Cap_average_size) = 0;%/< Массив хранящий последние значения ёмкости ДХТ1
 DHT2_Cap_average_pointer = 0;%/< Указатель текущей позиции в массиве последних значений емкостей ДХТ2
 DHT2_Cap_average_pointer_cycle = false;%/< Признак того что указатель позиции в массиве последних значений емкостей ДХТ2 (DHT2_Cap_average_pointer) сделал круг
 DHT2_Cap_average(DHT_Cap_average_size)= 0;%/< Массив хранящий последние значения ёмкости ДХТ2

 PRPrep_inData = struct();
 PRPrep_outData = struct();
 BNR_Normal = struct();
 
 PRPrep_outData.OutPitch = IRS1_324_pitch_angle;
 PRPrep_outData.OutRoll = IRS1_325_roll_angle;
 
 SCADE_OutData =  struct('W_ON_W',1,...
                            'WOW_DISAGREE',false);

%/// \defgroup TanksInfo_ZeroReg_Group Индексы баков в массиве регулировочных коэффициентов нуля
%/// @{
%/// \name Индексы баков в массиве регулировочных коэффициентов нуля
%/// @{
TanksInfo_ZeroReg_GrID_All_Centr    =            0+1;       %///< Индекс в массиве регулировочного коэффициента нуля полной группы датчиков центрального бака
TanksInfo_ZeroReg_GrID_G1_Centr      =           1+1;       %///< Индекс в массиве регулировочного коэффициента нуля группы 1 датчиков центрального бака
TanksInfo_ZeroReg_GrID_G2_Centr      =           2+1;      %///< Индекс в массиве регулировочного коэффициента нуля группы 2 датчиков центрального бака
TanksInfo_ZeroReg_GrID_All_RO_L      =           3+1;     %///< Индекс в массиве регулировочного коэффициента нуля полной группы датчиков расходного отсека левого бота
TanksInfo_ZeroReg_GrID_All_Section21_L  =        4+1;    %///< Индекс в массиве регулировочного коэффициента нуля полной группы датчиков бака 2 левого бота
TanksInfo_ZeroReg_GrID_G1_Section21_L    =       5+1;       %///< Индекс в массиве регулировочного коэффициента нуля группы 1 датчиков бака 2 левого бота
TanksInfo_ZeroReg_GrID_G2_Section21_L    =       6+1;       %///< Индекс в массиве регулировочного коэффициента нуля группы 2 датчиков бака 2 левого бота
TanksInfo_ZeroReg_GrID_All_Section31_L    =      7+1;       %///< Индекс в массиве регулировочного коэффициента нуля полной группы датчиков бака 3 левого бота
TanksInfo_ZeroReg_GrID_G1_Section31_L     =      8+1;       %///< Индекс в массиве регулировочного коэффициента нуля группы 1 датчиков бака 3 левого бота
TanksInfo_ZeroReg_GrID_G2_Section31_L      =     9+1;       %///< Индекс в массиве регулировочного коэффициента нуля группы 2 датчиков бака 3 левого бота
TanksInfo_ZeroReg_GrID_All_RO_R           =      10+1;      %///< Индекс в массиве регулировочного коэффициента нуля полной группы датчиков расходного отсека правого бота
TanksInfo_ZeroReg_GrID_All_Section21_R    =      11+1;      %///< Индекс в массиве регулировочного коэффициента нуля полной группы датчиков бака 2 правого бота
TanksInfo_ZeroReg_GrID_G1_Section21_R     =      12+1;      %///< Индекс в массиве регулировочного коэффициента нуля группы 1 датчиков бака 2 правого бота
TanksInfo_ZeroReg_GrID_G2_Section21_R     =      13+1;      %///< Индекс в массиве регулировочного коэффициента нуля группы 2 датчиков бака 2 правого бота
TanksInfo_ZeroReg_GrID_All_Section31_R   =       14+1;      %///< Индекс в массиве регулировочного коэффициента нуля полной группы датчиков бака 3 правого бота
TanksInfo_ZeroReg_GrID_G1_Section31_R     =      15+1;      %///< Индекс в массиве регулировочного коэффициента нуля группы 1 датчиков бака 3 правого бота
TanksInfo_ZeroReg_GrID_G2_Section31_R     =      16+1;      %///< Индекс в массиве регулировочного коэффициента нуля группы 2 датчиков бака 3 правого бота
TanksInfo_ZeroReg_DHT1                   =       17+1;      %///< Индекс в массиве регулировочного коэффициента нуля датчика ДХТ1
TanksInfo_ZeroReg_DHT2                  =        18+1;      %///< Индекс в массиве регулировочного коэффициента нуля датчика ДХТ2  
                        
%// Размер массива, хранящего регулировочные коэффициенты нуля
TanksInfo_ZeroRegArrSize = (GroupsNumForTanks * 2 - 3 + 2);               

%// Подготовка данных для модели Температуры и Плотности с ДХТ1 и ДХТ2
   WorkDensity = struct('WorkDensity_DHT1',zeros(1,1),...
                         'WorkDensity_DHT2',zeros(1,1)); 
    WorkDensity.WorkDensity_DHT1 = LH_DENSITY;
    WorkDensity.WorkDensity_DHT2 = RH_DENSITY;
    
    WorkTemperature = struct('WorkTemperature_DHT1',zeros(1,1),...
                             'WorkTemperature_DHT2',zeros(1,1),...
                             'WorkTemperature_LH',zeros(1,1),...
                             'WorkTemperature_RH',zeros(1,1),...
                             'WorkTemperature_CT',zeros(1,1));
                         
    WorkTemperature.WorkTemperature_DHT1 = LH_FCS_TS_TEMP;
    WorkTemperature.WorkTemperature_DHT2 = RH_FCS_TS_TEMP;
    WorkTemperature.WorkTemperature_LH = LH_TS_TEMP;
    WorkTemperature.WorkTemperature_RH = RH_TS_TEMP;
    WorkTemperature.WorkTemperature_CT = CT_TS_TEMP;