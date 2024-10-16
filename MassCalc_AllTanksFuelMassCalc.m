%/ \brief Вычисление массы топлива в баках объекта. <br>
%/ Запуск последовательности вычисления масс в топливных баках.
%/ \return  Возвращаемое значение отсутствует
%function [TankMassArr] = MassCalc_AllTanksFuelMassCalc(PRPrep_inData, PRPrep_outData, BNR_Normal) 
    %/ - Подготовка данных крена и тангажа. Вызов функции @ref Pitch_Roll_Prepare_Architect
   %Pitch_Roll_Prepare_Architect(PRPrep_inData, PRPrep_outData);
     
    %/ - Нахождение масс в соответствии с нужным креном и тангажом @ref MassCalc_AllTanksFuelMassCalc_PR
    MassCalc_AllTanksFuelMassCalc_PR(PRPrep_outData.OutPitch, PRPrep_outData.OutRoll, BKD_Param_Stuct,SCADE_OutData,ResSensId_Sec3_L_DHT1,...
        ResSensId_Sec3_R_DHT2,TanksNum,CapSensId,SensorsGroupEnumDef,TankId_RO_Left,TankId_RO_Right,TankId_Section31_Left,...
        TankId_Section31_Right,TankId_Section21_Left,TankId_Section21_Right,...
        MassDataStructDef, CapacityArr, WorkTemperature, LastMassArrPointer, LastMassArrSize);%Крен зафиксирован по #412
    
    %/ - Выставление признаков недостоверности масс(InvalidData) в случае если крен или тангаж были не достоверными
    if((PRPrep_outData.OutPitch_SMM ~= BNR_Normal) || (PRPrep_outData.OutRoll_SMM ~= BNR_Normal))
    
        %Поскольку таблицы возможно не соответствуют реальным данным все данные помечаем как InvalidData        
        for Tank = 0+1:TanksNum
        
            TankMassArr(Tank) = true;
        end
        SummFuelMass.InvalidData = true;
    end  
%end 


%/ \brief Вычисление масс топлива по бакам объекта
%/ \param[in] Pitch Тангаж
%/ \param[in] Roll Крен
%/ \return  Возвращаемое значение отсутствует
function MassCalc_AllTanksFuelMassCalc_PR(Pitch, Roll, BKD_Param_Stuct,SCADE_OutData,ResSensId_Sec3_L_DHT1,ResSensId_Sec3_R_DHT2...
    ,TanksNum,CapSensId,SensorsGroupEnumDef,TankId_RO_Left,TankId_RO_Right,TankId_Section31_Left,TankId_Section31_Right,TankId_Section21_Left,...
    TankId_Section21_Right, MassDataStructDef, CapacityArr, WorkTemperature, LastMassArrPointer, LastMassArrSize)
    %/ <b>Последовательность работы </b> 
%     e_t_dht1 = struct();
%     e_t_dht2 = struct();
%     e_t_dht1 = MassDataStructDef;
%     e_t_dht2 = MassDataStructDef;
    %extern float TanksInfo_MaxRegArr[ TanksInfo_MaxRegArrSize ];
    
    %/ - Преобразование значения термосопротивлений в температуру @ref TranslateResToTemp
    %ДАННЫЕ ТЕМПЕРАТУР ВЗЯТЫ ИЗ ESCEL ТАБЛИЦЫ
    [WorkTemperature_DHT1,WorkTemperature_DHT2] = TranslateResToTemp(BKD_Param_Stuct,SCADE_OutData,ResSensId_Sec3_L_DHT1,ResSensId_Sec3_R_DHT2);
    CapacitySummArr = struct();
    %/ - Формирование суммарных значения емкостей ( помещаются в @ref CapacitySummArr ) @ref MakeSummCap
    [CapacitySummArr] = MakeSummCap(TanksNum,CapSensId,SensorsGroupEnumDef,TankId_RO_Left,TankId_RO_Right, TankId_Section31_Left, TankId_Section31_Right,...
        TankId_Section21_Left,TankId_Section21_Right,CapacityArr);

    %/ - Расчёт диэлектрической проницаемости топлива в баке (п.3.3) @ref MassCalc_DielPronCalcDHT1 , @ref MassCalc_DielPronCalcDHT2
    e_t_dht1 = MassCalc_DielPronCalcDHT1(MassDataStructDef,CapacityArr,CapSensId,SensorsGroupEnumDef);
    e_t_dht2 = MassCalc_DielPronCalcDHT2(MassDataStructDef,CapacityArr,CapSensId,SensorsGroupEnumDef);
    %
    %/ - Перебор баков самолёта(цикл)
    WorkDensity =0;
    for Tank = 0+1:TanksNum
	%MassDataStructDef.WorkTemperature;%Текущее значение температуры топлива в баке
	%MassDataStructDef.WorkDensity;%Значение плотности расчитанное под текущую температуру
        
        %/ - (В цикле) Расчёт значения объёма топлива в баке по емкостям @ref MassCalc_FindVolume . 
        %/ Тут же происходит расчёт плотности топлива в баке и
        %/ температуры топлива в баке.
        
        [MassDataStructDef.Volume, WorkDensity] = MassCalc_FindVolume(Tank, Pitch, Roll, WorkDensity,...
            WorkTemperature, CapacitySummArr, BKD_Param_Stuct, MassDataStructDef,e_t_dht1,e_t_dht2,...
            WorkTemperature_DHT1,WorkTemperature_DHT2);
        Volume = MassDataStructDef.Volume;
        %/ - (В цикле) Сохранение полученного объёма в @ref TankVolumeArr
        MassDataStructDef.TankVolumeArr(Tank) = Volume.Value;
        MassDataStructDef.TankVolumeArr(Tank) = MassDataStructDef.TankVolumeArr(Tank) * 1;%TanksInfo_MaxRegArr(Tank);
        
        Volume.Value = Volume.Value * 0.001;%Перевод объёма в м3

        %/ - (В цикле) Сохранение полученной плотности в @ref TankDensityArr
        MassDataStructDef.TankDensityArr(Tank) = WorkDensity.Value;
        
	 if(Volume.NoData)
	    %Если данных по объёму нет считать массу бесполезно
	    MassDataStructDef.TankMassArr(Tank).Value = 0;
	    MassDataStructDef.TankMassArr(Tank).NoData = true;
	    MassDataStructDef.TankMassArr(Tank).InvalidData = true;
	 else
	
	    %/ - (В цикле) Пересчёт объёма и плотности в массу топлива в баке @ref VolumeToMassCalc
            MassDataStructDef.TankMassArr(Tank) = VolumeToMassCalc(Tank, Volume, WorkDensity).Value;
            LastMassArr = MassDataStructDef.TankMassArr;%LastMassArr(Tank,LastMassArrPointer) = MassDataStructDef.TankMassArr(Tank);
            MassDataStructDef.TankMassArr(Tank) = MedianFiltr_GetValue(LastMassArr, length(LastMassArr));           
     end
    end

    LastMassArrPointer = LastMassArrPointer+1;

    if(LastMassArrPointer >= LastMassArrSize)
        LastMassArrPointer = 0;
    end
    
    %/ - Расчёт суммарной массы топлива
    SummFuelMass.Value = 0;
    SummFuelMass.NoData = false;
    SummFuelMass.InvalidData = false;

    for Tank = 0+1:TanksNum
    
	SummFuelMass.Value = SummFuelMass.Value + TankMassArr(Tank).Value;

        if((TankMassArr(Tank).InvalidData) || (TankMassArr(Tank).NoData))
            SummFuelMass.InvalidData = true;
        end
    end
end


%/ \brief Установка значений масс и температур в значения по умолчанию
%/ \return Возвращаемое значение отсутствует
function MassCalc_SetDefaultVals(tank,TanksNum)

    %Значения по умолчанию масс
    for tank = 0+1:TanksNum
    
	MassDataStructDef TankDefVal;
	BKD_Param_Stuct SumCapData;

	TankDefVal.InvalidData = true;
	TankDefVal.NoData = true;
	TankDefVal.Value = 0;

	SumCapData.NoData = true;
	SumCapData.LineCut = false;
	SumCapData.OutOfRange = false;
	SumCapData.Val = 0;

	TankMassArr(tank) = TankDefVal;
        TankDensityArr(tank) = TankDefVal;
        TankVolumeArr(tank) = TankDefVal;
	CapacitySummArr(tank) = SumCapData;
        
        for l = 0+1:LastMassArrSize 
            LastCapArr(tank,l) = 0;
        end        
    end
    SummFuelMass.InvalidData = true;
    SummFuelMass.NoData = true;
    SummFuelMass.Value = 0;

    %Значения по умолчанию для ёмкостей
    for c = 0+1:CapSensNum
    BKD_Param_Stuct CapData;

	CapData.NoData = true;
	CapData.LineCut = false;
	CapData.OutOfRange = false;
	CapData.Val = 0;

	CapacityArr(c) = CapData;
        
        for l = 0+1:LastCapArrSize
           LastCapArr(c,l) = 0;
        end
    end

    %Значения по умолчанию для термосопротивлений
    for r = 0+1:ResSensNum
    BKD_Param_Stuct ResData;

	ResData.NoData = true;
	ResData.LineCut = false;
	ResData.OutOfRange = false;
	ResData.Val = 49;

	TempArr(r) = ResData;
    end   
end

%/ \brief Преобразование полученных по CAN данных в указанные параметры
%/ \param(in) Dev идентификатор устройства(FID)
%/ \param(in) Mes идентификатор посылки устройства(DOC)
%/ \param(in) MulCoef цена младшего значащего разряда
%/ \param(out) DestStruct указатель на структуру куда будет помкщён результат
%/ \param(in) ParmType тип анализируемого параметра(ParmType_Cap- ёмкость; ParmType_Res- сопротивление)
%/ \return Возвращаемое значение отсутствует
function [DestStruct] = GetParm ( Dev,  Mes,  MulCoef, DestStruct, ParmType)
 %{
     if(MesNum == 0)%Если индекс устройства неизветен
	DestStruct.NoData = true;
	DestStruct.LineCut = true;
	DestStruct.OutOfRange = true;
	DestStruct.Val = 0;
	return;
    end
    
    NoData = false;%Изначально считаем что данные есть
    Ptr = (CAN_dev_RecMessageDef *)CAN_dev_MessageDataArr(Dev) + CAN_dev_CAN1_LineNum * MesNum + Mes;
    if( Ptr.CyclesFromLast >= CAN_dev_ReciveTimeOut )
	%Если по основной линии данные не были получены проверить резервную
	Ptr = (CAN_dev_RecMessageDef *)CAN_dev_MessageDataArr(Dev) + CAN_dev_CAN2_LineNum * MesNum + Mes;
        if( Ptr.CyclesFromLast >= CAN_dev_ReciveTimeOut)
           %По резервной линии данные тоже не поступают
           NoData = true;
        end
    end 
 %}
    NoData = false;%Изначально считаем что данные есть
    if(~NoData)
    
	%Данные были получены их надо обработать
	UnMatrix.BitData = Ptr.DataArr(0);

	DestStruct.NoData = false;
	    if(ParmType == ParmType_Cap)
	        %Анализируемый параметр Ёмкость
	        DestStruct.LineCut = UnMatrix.StructData.Sensor_Cut;%Обрыв линии
	        DestStruct.OutOfRange =  UnMatrix.StructData.Sensor_OutOfRage;%Значение за границами диапазона
       
               if(DestStruct.Val < 0)
                DestStruct.NoData = true;
                DestStruct.LineCut = false;
                DestStruct.OutOfRange = false;
                DestStruct.Val = 0;
                end
        
        else
	        %Анализируемый параметр Термосопротивление
	        DestStruct.LineCut = UnMatrix.StructData.Sensor_Cut;%Обрыв линии
	        DestStruct.OutOfRange =  UnMatrix.StructData.Sensor_OutOfRage;%Значение за границами диапазона
        end
        DestStruct.Val = BytesTo(Ptr.DataArr + 1) * MulCoef;
    else
	    %Данные не были получены ни по основной ни по резервной линиям
	    DestStruct.NoData = true;
	    DestStruct.LineCut = false;
	    DestStruct.OutOfRange = false;
	    DestStruct.Val = 0;

    end
end

%/ \brief Преобразует полученные ранее значения термосопротивлений в температуру
%/ \return Возвращаемое значение отсутствует
function  [WorkTemperature_DHT1,WorkTemperature_DHT2] = TranslateResToTemp(TempArr, SCADE_OutData, ResSensId_Sec3_L_DHT1,ResSensId_Sec3_R_DHT2)

    AverageCounter = 0;
    ResSensNum = 5;
    
    MinTemp.Value = 20;%Значение по умолчанию минимальной температуры
    MinTemp.NoData = true;
    MinTemp.InvalidData = true;

    AverageTemp.Value = 0;
    AverageTemp.NoData = true;
    AverageTemp.InvalidData = true;

    for tsens = 0+1 : ResSensNum
        if(TempArr(tsens).NoData)
	        TempArr(tsens).Val = 20;%20 градусов - значение по умолчанию
        else
            %тут скорее всего температуры из массива надо брать
	        TempArr(tsens).Val = 0;%GetTemperatureByResistance( TempArr(tsens).Val );

	        AverageTemp.Value =AverageTemp.Value + TempArr(tsens).Val;
	        AverageCounter=AverageCounter+1;

	        %Формирование значения минимальной температуры
	        if(MinTemp.NoData)
	    
		        MinTemp.Value = TempArr(tsens).Val;
		        MinTemp.NoData = false;
		        MinTemp.InvalidData = false;
	        else
		        if(TempArr(tsens).Val < MinTemp.Value)
		            MinTemp.Value = TempArr(tsens).Val;
                end
	        end
	    end
    end

    %Расчёт среднего значения
    if(AverageCounter > 0)
	    AverageTemp.Value = AverageTemp.Value / AverageCounter;
	    AverageTemp.NoData = false;
	    AverageTemp.InvalidData = false;
    end
    
    %Подмена значения температуры ДХТ
    %extern outC_Main_Logic_A_Architect SCADE_OutData;
    %extern BKD_Param_Stuct WorkTemperature_DHT1;%Температура полученная от ДХТ1
    %extern BKD_Param_Stuct WorkTemperature_DHT2;%Температура полученная от ДХТ2
    
    %Когда мы на земле производим подмену температуры ДХТ
    if((SCADE_OutData.W_ON_W)&&(SCADE_OutData.WOW_DISAGREE == false))
    
        %ДХТ1
        if((TempArr(ResSensId_Sec3_L_DHT1).NoData == false) && ...
            (TempArr(ResSensId_Sec3_L_DHT1).LineCut == false) && ...
            (TempArr(ResSensId_Sec3_L_DHT1).OutOfRange == false))
        
            %Температура в порядке. Подставляю её вместо температуры ДХТ
            WorkTemperature_DHT1.Val = TempArr(ResSensId_Sec3_L_DHT1).Val;
            WorkTemperature_DHT1.NoData = false;
            WorkTemperature_DHT1.LineCut = false;
            WorkTemperature_DHT1.OutOfRange = false;
        end
        
        %ДХТ2
        if((TempArr(ResSensId_Sec3_R_DHT2).NoData == false) && ...
           (TempArr(ResSensId_Sec3_R_DHT2).LineCut == false) && ...
           (TempArr(ResSensId_Sec3_R_DHT2).OutOfRange == false))
        
            %Температура в порядке. Подставляю её вместо температуры ДХТ
            WorkTemperature_DHT2.Val = TempArr(ResSensId_Sec3_R_DHT2).Val;
            WorkTemperature_DHT2.NoData = false;
            WorkTemperature_DHT2.LineCut = false;
            WorkTemperature_DHT2.OutOfRange = false;
        end
    end   
end

%/ \brief Получение значения температуры в указанном баке
%/ \param(in) Tank Идентификатор топливного бака
%/ \return Значение температуры в указанном баке
function [Result] = MassCalc_GetTankTemperature(Tank,TempArr,MassDataStructDef)
Result = MassDataStructDef;
TankId_Centr = 0+1;            %/< Идентификатор центрального топливного бака
TankId_RO_Left = 1+1;          %/< Идентификатор расходного отсека левого борта
TankId_Section21_Left = 2+1;   %/< Идентификатор бака 2 левого борта
TankId_Section31_Left = 3+1;   %/< Идентификатор бака 3 левого борта
TankId_RO_Right = 4+1;         %/< Идентификатор расходного отсека правого борта
TankId_Section21_Right = 5+1;  %/< Идентификатор бака 2 правого борта
TankId_Section31_Right = 6+1;  %/< Идентификатор бака 3 правого борта
TankId_DHT1 = 7+1;             %/< Идентификатор ДХТ1
TankId_DHT2 = 8+1;             %/< Идентификатор ДХТ2

ResSensId_centr_DT18 = 0+1;  %Центральный бак
ResSensId_Sec2_L_DT7 = 1+1;  %Отсек 2 левый
ResSensId_Sec2_R_DT26 = 2+1;  %Отсек 2 правый
ResSensId_Sec3_L_DHT1 = 3+1; %Отсек 3 левый. Тербодатчик ДХТ1
ResSensId_Sec3_R_DHT2 = 4+1; %Отсек 3 правый. Тербодатчик ДХТ2

    %Если температуры в баке нет взять температуру с симетричного борта
    %Если и там нет взять минимальную
    %Если и её нет пометить как данные отсутствуют

    MassDataStructDef.Result.Value = 0;
    MassDataStructDef.Result.NoData = false;
    MassDataStructDef.Result.InvalidData = false;

    %TankSensId;%Номер основного термодатчика указанного бака

    switch Tank
        case TankId_Centr
            TankSensId = ResSensId_centr_DT18;
	        
        case TankId_RO_Left
	        TankSensId = ResSensId_Sec3_L_DHT1;%Баки связаны и датчик стоит рядом с расходным
	        
        case TankId_Section21_Left
	        TankSensId = ResSensId_Sec2_L_DT7;
	        
        case TankId_Section31_Left
	            TankSensId = ResSensId_Sec3_L_DHT1;
	        
        case TankId_RO_Right
	        TankSensId = ResSensId_Sec3_R_DHT2;%Баки связаны и датчик стоит рядом с расходным
	        
        case TankId_Section21_Right
	        TankSensId = ResSensId_Sec2_R_DT26;
	        
        case TankId_Section31_Right
	        TankSensId = ResSensId_Sec3_R_DHT2;
	        
        otherwise
	        MassDataStructDef.Result.Value = 0;
	        MassDataStructDef.Result.NoData = true;
	        MassDataStructDef.Result.InvalidData = true;
	        MassDataStructDef.Result;
	    
    end

    if(TempArr(TankSensId).NoData || TempArr(TankSensId).LineCut || TempArr(TankSensId).OutOfRange)
    
	    %Попробовать взять по симетричному баку
	    switch(Tank)
	        case TankId_Centr
	            TankSensId = ResSensId_centr_DT18;%Симетричного бака нет
	            
	        case TankId_RO_Left
	            TankSensId = ResSensId_Sec3_R_DHT2;
	            
	        case TankId_Section21_Left
	            TankSensId = ResSensId_Sec2_R_DT26;
	            
	        case TankId_Section31_Left
	            TankSensId = ResSensId_Sec3_R_DHT2;
	            
	        case TankId_RO_Right
	            TankSensId = ResSensId_Sec3_L_DHT1;
	            
	        case TankId_Section21_Right
	            TankSensId = ResSensId_Sec2_L_DT7;
	            
	        case TankId_Section31_Right
	            TankSensId = ResSensId_Sec3_L_DHT1;
	            
	    end

	    Result.InvalidData = true;

	    if(TempArr(TankSensId).NoData || TempArr(TankSensId).LineCut || TempArr(TankSensId).OutOfRange)
	
	        Result = AverageTemp;
                %Result = MinTemp;
	        Result.InvalidData = true;                        
	    else
	
	        Result.Value = TempArr(TankSensId).Val;
	    end
    else
	Result.Value = TempArr(TankSensId).Val;
    end
    %Result = MassDataStructDef;
    return;
end

%/ \brief Получить суммарную ёмкость в баке по заданному баку и группе
%/ \param(in) Tank Идентификатор топливного бака
%/ \param(in) Group - Идентификатор группы датчиков в баке
%/ \return значение суммы ёмкостей указанной группы в баке
function  [out] = GetSummCapForGroup( Tank, Group, CapacityArr, CapSensId, SensorsGroupEnumDef)

TankId_Centr = 0+1;            %/< Идентификатор центрального топливного бака
TankId_RO_Left = 1+1;          %/< Идентификатор расходного отсека левого борта
TankId_Section21_Left = 2+1;   %/< Идентификатор бака 2 левого борта
TankId_Section31_Left = 3+1;   %/< Идентификатор бака 3 левого борта
TankId_RO_Right = 4+1;         %/< Идентификатор расходного отсека правого борта
TankId_Section21_Right = 5+1;  %/< Идентификатор бака 2 правого борта
TankId_Section31_Right = 6+1;  %/< Идентификатор бака 3 правого борта
out = 'inf';
    switch(Tank)
    
        case TankId_Centr
            switch(Group)
        
                case SensorsGroupEnumDef.GrType_All 
                   out =  CapacityArr(CapSensId.CapSensId_centr_DT14).Val +...
			        CapacityArr(CapSensId.CapSensId_centr_DT15).Val +...
	    			CapacityArr(CapSensId.CapSensId_centr_DT16).Val +...
				    CapacityArr(CapSensId.CapSensId_centr_DT17).Val +...
		    		CapacityArr(CapSensId.CapSensId_centr_DT18).Val +...
				    CapacityArr(CapSensId.CapSensId_centr_DT19).Val;
                case SensorsGroupEnumDef.GrType_G1 
                    out =  CapacityArr(CapSensId.CapSensId_centr_DT14).Val +...
                    CapacityArr(CapSensId.CapSensId_centr_DT17).Val +...
                    CapacityArr(CapSensId.CapSensId_centr_DT18).Val;
                case SensorsGroupEnumDef.GrType_G2 
                    out =  CapacityArr(CapSensId.CapSensId_centr_DT19).Val +...
                    CapacityArr(CapSensId.CapSensId_centr_DT15).Val +...
                    CapacityArr(CapSensId.CapSensId_centr_DT16).Val;
            end
            

        case TankId_RO_Left 
        out =  CapacityArr(CapSensId.CapSensId_RO_L_DT13).Val;
        case TankId_RO_Right 
        out =  CapacityArr(CapSensId.CapSensId_RO_R_DT20).Val;
        case TankId_Section21_Left
        switch(Group)
            case SensorsGroupEnumDef.GrType_All
                out =  CapacityArr(CapSensId.CapSensId_Sec2_L_DT1).Val +...
				CapacityArr(CapSensId.CapSensId_Sec2_L_DT2).Val +...
	    			CapacityArr(CapSensId.CapSensId_Sec2_L_DT3).Val +...
				CapacityArr(CapSensId.CapSensId_Sec2_L_DT4).Val +...
		    		CapacityArr(CapSensId.CapSensId_Sec2_L_DT5).Val +...
				CapacityArr(CapSensId.CapSensId_Sec2_L_DT6).Val +...
				CapacityArr(CapSensId.CapSensId_Sec2_L_DT7).Val;
            case SensorsGroupEnumDef.GrType_G1
                out =  CapacityArr(CapSensId.CapSensId_Sec2_L_DT1).Val +...
                CapacityArr(CapSensId.CapSensId_Sec2_L_DT2).Val +...
                CapacityArr(CapSensId.CapSensId_Sec2_L_DT4).Val +...
                CapacityArr(CapSensId.CapSensId_Sec2_L_DT6).Val;
            case SensorsGroupEnumDef.GrType_G2
                out =  CapacityArr(CapSensId.CapSensId_Sec2_L_DT3).Val +...
                CapacityArr(CapSensId.CapSensId_Sec2_L_DT5).Val +...
                CapacityArr(CapSensId.CapSensId_Sec2_L_DT7).Val;     
        end
        

        case TankId_Section21_Right
        switch(Group)
        
        case SensorsGroupEnumDef.GrType_All 
            out =  CapacityArr(CapSensId.CapSensId_Sec2_R_DT26).Val +...
			CapacityArr(CapSensId.CapSensId_Sec2_R_DT27).Val +...
	    	CapacityArr(CapSensId.CapSensId_Sec2_R_DT28).Val +...
			CapacityArr(CapSensId.CapSensId_Sec2_R_DT29).Val +...
		    CapacityArr(CapSensId.CapSensId_Sec2_R_DT30).Val +...
			CapacityArr(CapSensId.CapSensId_Sec2_R_DT31).Val +...
			CapacityArr(CapSensId.CapSensId_Sec2_R_DT32).Val;
        case SensorsGroupEnumDef.GrType_G1
            out =  CapacityArr(CapSensId.CapSensId_Sec2_R_DT27).Val +...
            CapacityArr(CapSensId.CapSensId_Sec2_R_DT29).Val +...
            CapacityArr(CapSensId.CapSensId_Sec2_R_DT31).Val +...
            CapacityArr(CapSensId.CapSensId_Sec2_R_DT32).Val;
        case SensorsGroupEnumDef.GrType_G2
            out =  CapacityArr(CapSensId.CapSensId_Sec2_R_DT26).Val +...
            CapacityArr(CapSensId.CapSensId_Sec2_R_DT28).Val +...
            CapacityArr(CapSensId.CapSensId_Sec2_R_DT30).Val;
        end
        

        case TankId_Section31_Left
        switch(Group)
            case SensorsGroupEnumDef.GrType_All
                    out =  CapacityArr(CapSensId.CapSensId_Sec3_L_DT8).Val +...
				    CapacityArr(CapSensId.CapSensId_Sec3_L_DT9).Val +...
	    			CapacityArr(CapSensId.CapSensId_Sec3_L_DT10).Val +...
				    CapacityArr(CapSensId.CapSensId_Sec3_L_DT11).Val +...
		    		CapacityArr(CapSensId.CapSensId_Sec3_L_DT12).Val;
            case SensorsGroupEnumDef.GrType_G1
                    out =  CapacityArr(CapSensId.CapSensId_Sec3_L_DT8).Val +...
                    CapacityArr(CapSensId.CapSensId_Sec3_L_DT10).Val +...
                    CapacityArr(CapSensId.CapSensId_Sec3_L_DT12).Val;
            case SensorsGroupEnumDef.GrType_G2
                    out =  CapacityArr(CapSensId.CapSensId_Sec3_L_DT9).Val +...
                    CapacityArr(CapSensId.CapSensId_Sec3_L_DT11).Val;    
        end
        
        case TankId_Section31_Right
        switch(Group)
        case SensorsGroupEnumDef.GrType_All
            out =  CapacityArr(CapSensId.CapSensId_Sec3_R_DT21).Val +...
		    CapacityArr(CapSensId.CapSensId_Sec3_R_DT22).Val +...
	    	CapacityArr(CapSensId.CapSensId_Sec3_R_DT23).Val +...
			CapacityArr(CapSensId.CapSensId_Sec3_R_DT24).Val +...
		    CapacityArr(CapSensId.CapSensId_Sec3_R_DT25).Val;
        case SensorsGroupEnumDef.GrType_G1
            out =  CapacityArr(CapSensId.CapSensId_Sec3_R_DT21).Val +...
            CapacityArr(CapSensId.CapSensId_Sec3_R_DT23).Val +...
            CapacityArr(CapSensId.CapSensId_Sec3_R_DT25).Val;
        case SensorsGroupEnumDef.GrType_G2
            out =  CapacityArr(CapSensId.CapSensId_Sec3_R_DT22).Val +...
            CapacityArr(CapSensId.CapSensId_Sec3_R_DT24).Val;
        end
        
    end  
    %return 0;%Это ошибка. Сюда не должны попадать
end

%/ \brief Формирует массив суммарных ёмкостей датчиков в баке
%/ \return Возвращаемое значение отсутствует (CapacitySummArr матлабе работает)
function [CapacitySummArr] = MakeSummCap(TanksNum,CapSensId,SensorsGroupEnumDef,TankId_RO_Left,TankId_RO_Right,...
    TankId_Section31_Left,TankId_Section31_Right,TankId_Section21_Left,TankId_Section21_Right,CapacityArr)
    GrType_No = 1;
    TankId_Centr = 1;

    %Приведение выходных значений в состояния по умолчанию
    for t = 0+1:TanksNum
    
        TankSensorsWorkGroup(t) = GrType_No;
        CapacitySummArr(t).Val = 0;
        CapacitySummArr(t).NoData = true;
        CapacitySummArr(t).LineCut = false;
        CapacitySummArr(t).OutOfRange = false;
    end
    
    %Центральный бак
    if(CapacityArr(CapSensId.CapSensId_centr_DT14).NoData ||...
       CapacityArr(CapSensId.CapSensId_centr_DT15).NoData ||...
       CapacityArr(CapSensId.CapSensId_centr_DT16).NoData ||...
       CapacityArr(CapSensId.CapSensId_centr_DT17).NoData ||...
       CapacityArr(CapSensId.CapSensId_centr_DT18).NoData ||...
       CapacityArr(CapSensId.CapSensId_centr_DT19).NoData ||...
       CapacityArr(CapSensId.CapSensId_centr_DT14).LineCut ||...
       CapacityArr(CapSensId.CapSensId_centr_DT15).LineCut ||...
       CapacityArr(CapSensId.CapSensId_centr_DT16).LineCut ||...
       CapacityArr(CapSensId.CapSensId_centr_DT17).LineCut ||...
       CapacityArr(CapSensId.CapSensId_centr_DT18).LineCut ||...
       CapacityArr(CapSensId.CapSensId_centr_DT19).LineCut ||...
       CapacityArr(CapSensId.CapSensId_centr_DT14).OutOfRange ||...
       CapacityArr(CapSensId.CapSensId_centr_DT15).OutOfRange ||...
       CapacityArr(CapSensId.CapSensId_centr_DT16).OutOfRange ||...
       CapacityArr(CapSensId.CapSensId_centr_DT17).OutOfRange ||...
       CapacityArr(CapSensId.CapSensId_centr_DT18).OutOfRange ||...
       CapacityArr(CapSensId.CapSensId_centr_DT19).OutOfRange)
    
        %Выбираем по какой группе будем работать
        
        %Группа 1        
        if(CapacityArr(CapSensId.CapSensId_centr_DT14).NoData ||...
           CapacityArr(CapSensId.CapSensId_centr_DT17).NoData ||...
           CapacityArr(CapSensId.CapSensId_centr_DT18).NoData ||...
           CapacityArr(CapSensId.CapSensId_centr_DT14).LineCut ||...
           CapacityArr(CapSensId.CapSensId_centr_DT17).LineCut ||...
           CapacityArr(CapSensId.CapSensId_centr_DT18).LineCut ||  ...  
           CapacityArr(CapSensId.CapSensId_centr_DT14).OutOfRange ||...
           CapacityArr(CapSensId.CapSensId_centr_DT17).OutOfRange ||...
           CapacityArr(CapSensId.CapSensId_centr_DT18).OutOfRange)
        
            %Ничего не делаем
            %Возможно с другой группой повезёт больше
        else
        
            TankSensorsWorkGroup(TankId_Centr) = GrType_G1;
            CapacitySummArr(TankId_Centr).Val = GetSummCapForGroup(TankId_Centr, GrType_G1);
            CapacitySummArr(TankId_Centr).NoData = false;
            CapacitySummArr(TankId_Centr).LineCut = false;
            CapacitySummArr(TankId_Centr).OutOfRange = false; 
        end
                
        %Группа 2        
        if(CapacityArr(CapSensId.CapSensId_centr_DT19).NoData ||...
           CapacityArr(CapSensId.CapSensId_centr_DT15).NoData ||...
           CapacityArr(CapSensId.CapSensId_centr_DT16).NoData ||...
           CapacityArr(CapSensId.CapSensId_centr_DT19).LineCut ||...
           CapacityArr(CapSensId.CapSensId_centr_DT15).LineCut ||...
           CapacityArr(CapSensId.CapSensId_centr_DT16).LineCut ||...    
           CapacityArr(CapSensId.CapSensId_centr_DT19).OutOfRange ||...
           CapacityArr(CapSensId.CapSensId_centr_DT15).OutOfRange ||...
           CapacityArr(CapSensId.CapSensId_centr_DT16).OutOfRange)

           %Тут просто ничего не делаем
        else
        
            TankSensorsWorkGroup(TankId_Centr) = GrType_G2;
            CapacitySummArr(TankId_Centr).Val = GetSummCapForGroup(TankId_Centr, GrType_G2);
            CapacitySummArr(TankId_Centr).NoData = false;
            CapacitySummArr(TankId_Centr).LineCut = false;
            CapacitySummArr(TankId_Centr).OutOfRange = false; 
        end        
    else
    
        %Считаем по суммарной группе
        TankSensorsWorkGroup(TankId_Centr) = SensorsGroupEnumDef.GrType_All;
        GrType_All=SensorsGroupEnumDef.GrType_All;
        CapacitySummArr(TankId_Centr).Val = GetSummCapForGroup(TankId_Centr, GrType_All, CapacityArr, CapSensId,SensorsGroupEnumDef);
        CapacitySummArr(TankId_Centr).NoData = false;
        CapacitySummArr(TankId_Centr).LineCut = false;
        CapacitySummArr(TankId_Centr).OutOfRange = false;        
    end

    %РО левый
    TankSensorsWorkGroup(TankId_RO_Left) = SensorsGroupEnumDef.GrType_All;
    GrType_All=SensorsGroupEnumDef.GrType_All;
    CapacitySummArr(TankId_RO_Left).Val = GetSummCapForGroup(TankId_RO_Left, GrType_All, CapacityArr, CapSensId,SensorsGroupEnumDef);

    if(	CapacityArr(CapSensId.CapSensId_RO_L_DT13).NoData)
    
	CapacitySummArr(TankId_RO_Left).NoData = true;%Флаг отсутствия какого либо из данных
    TankSensorsWorkGroup(TankId_RO_Left) = GrType_No;
    else
	CapacitySummArr(TankId_RO_Left).NoData = false;
    end  

    if(	CapacityArr(CapSensId.CapSensId_RO_L_DT13).LineCut )
	CapacitySummArr(TankId_RO_Left).LineCut = true;%Флаг обрыва линии одно из датчиков
    else
	CapacitySummArr(TankId_RO_Left).LineCut = false;
    end

    if(	CapacityArr(CapSensId.CapSensId_RO_L_DT13).OutOfRange )
	CapacitySummArr(TankId_RO_Left).OutOfRange = true;%Флаг выхода одной из ёмкосте за допустимый диапазон
    else
	CapacitySummArr(TankId_RO_Left).OutOfRange = false;
    end

    %РО правый
    TankSensorsWorkGroup(TankId_RO_Right) = SensorsGroupEnumDef.GrType_All;
    GrType_All=SensorsGroupEnumDef.GrType_All;
    CapacitySummArr(TankId_RO_Right).Val = GetSummCapForGroup(TankId_RO_Right, GrType_All, CapacityArr, CapSensId,SensorsGroupEnumDef);

        if(	CapacityArr(CapSensId.CapSensId_RO_R_DT20).NoData )
	    CapacitySummArr(TankId_RO_Right).NoData = true;%Флаг отсутствия какого либо из данных
        TankSensorsWorkGroup(TankId_RO_Right) = GrType_No;
        else
	    CapacitySummArr(TankId_RO_Right).NoData = false;
        end

        if(	CapacityArr(CapSensId.CapSensId_RO_R_DT20).LineCut )
	    CapacitySummArr(TankId_RO_Right).LineCut = true;%Флаг обрыва линии одно из датчиков
        else
	    CapacitySummArr(TankId_RO_Right).LineCut = false;
        end

        if(	CapacityArr(CapSensId.CapSensId_RO_R_DT20).OutOfRange )
	    CapacitySummArr(TankId_RO_Right).OutOfRange = true;%Флаг выхода одной из ёмкосте за допустимый диапазон
        else
	    CapacitySummArr(TankId_RO_Right).OutOfRange = false;
        end

    %отсек 3 левый
    if(CapacityArr(CapSensId.CapSensId_Sec3_L_DT8).NoData ||...
       	    CapacityArr(CapSensId.CapSensId_Sec3_L_DT9).NoData ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT10).NoData ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT11).NoData ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT12).NoData ||...
            CapacityArr(CapSensId.CapSensId_Sec3_L_DT8).LineCut ||...
       	    CapacityArr(CapSensId.CapSensId_Sec3_L_DT9).LineCut ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT10).LineCut ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT11).LineCut ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT12).LineCut ||  ...  
            CapacityArr(CapSensId.CapSensId_Sec3_L_DT8).OutOfRange ||...
       	    CapacityArr(CapSensId.CapSensId_Sec3_L_DT9).OutOfRange ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT10).OutOfRange ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT11).OutOfRange ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT12).OutOfRange)
    
        %Выбираем по какой группе считать
        
        %Группа 1
        if(CapacityArr(CapSensId.CapSensId_Sec3_L_DT8).NoData ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT10).NoData ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT12).NoData ||...
            CapacityArr(CapSensId.CapSensId_Sec3_L_DT8).LineCut ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT10).LineCut ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT12).LineCut ||   ... 
            CapacityArr(CapSensId.CapSensId_Sec3_L_DT8).OutOfRange ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT10).OutOfRange ||...
	        CapacityArr(CapSensId.CapSensId_Sec3_L_DT12).OutOfRange)
        
            %Ничего не делаем
            %Возможно с другой группой повезёт больше
        else
        
            %Группа 1 исправна. Считаем по ней
            TankSensorsWorkGroup(TankId_Section31_Left) = GrType_G1;
            CapacitySummArr(TankId_Section31_Left).Val = GetSummCapForGroup(TankId_Section31_Left, GrType_G1);
            CapacitySummArr(TankId_Section31_Left).NoData = false;
            CapacitySummArr(TankId_Section31_Left).LineCut = false;
            CapacitySummArr(TankId_Section31_Left).OutOfRange = false;
        end
        
        %Группа 2
        if(CapacityArr(CapSensId.CapSensId_Sec3_L_DT9).NoData ||	...
	   CapacityArr(CapSensId.CapSensId_Sec3_L_DT11).NoData ||...
       	   CapacityArr(CapSensId.CapSensId_Sec3_L_DT9).LineCut ||...
	   CapacityArr(CapSensId.CapSensId_Sec3_L_DT11).LineCut ||    ...
       	   CapacityArr(CapSensId.CapSensId_Sec3_L_DT9).OutOfRange ||...
	   CapacityArr(CapSensId.CapSensId_Sec3_L_DT11).OutOfRange)
        
            %Ничего не делаем
            %Если и эта группа неисправна, то считать не по чему
        else
        
            %Группа 2 исправна. Считаем по ней
            TankSensorsWorkGroup(TankId_Section31_Left) = GrType_G2;
            CapacitySummArr(TankId_Section31_Left).Val = GetSummCapForGroup(TankId_Section31_Left, GrType_G2);
            CapacitySummArr(TankId_Section31_Left).NoData = false;
            CapacitySummArr(TankId_Section31_Left).LineCut = false;
            CapacitySummArr(TankId_Section31_Left).OutOfRange = false;
        end
    else
    
        %Считаем по суммарной группе
        TankSensorsWorkGroup(TankId_Section31_Left) = SensorsGroupEnumDef.GrType_All;
        GrType_All = SensorsGroupEnumDef.GrType_All;
        CapacitySummArr(TankId_Section31_Left).Val = GetSummCapForGroup(TankId_Section31_Left, GrType_All, CapacityArr, CapSensId,SensorsGroupEnumDef);
        CapacitySummArr(TankId_Section31_Left).NoData = false;
        CapacitySummArr(TankId_Section31_Left).LineCut = false;
        CapacitySummArr(TankId_Section31_Left).OutOfRange = false;
    end        

    %Отсек 3 правый
    if(CapacityArr(CapSensId.CapSensId_Sec3_R_DT21).NoData ||...
       	CapacityArr(CapSensId.CapSensId_Sec3_R_DT22).NoData ||...
	CapacityArr(CapSensId.CapSensId_Sec3_R_DT23).NoData ||...
	CapacityArr(CapSensId.CapSensId_Sec3_R_DT24).NoData ||...
	CapacityArr(CapSensId.CapSensId_Sec3_R_DT25).NoData ||...
        CapacityArr(CapSensId.CapSensId_Sec3_R_DT21).LineCut ||...
       	CapacityArr(CapSensId.CapSensId_Sec3_R_DT22).LineCut ||...
	CapacityArr(CapSensId.CapSensId_Sec3_R_DT23).LineCut ||...
	CapacityArr(CapSensId.CapSensId_Sec3_R_DT24).LineCut ||...
	CapacityArr(CapSensId.CapSensId_Sec3_R_DT25).LineCut ||...
        CapacityArr(CapSensId.CapSensId_Sec3_R_DT21).OutOfRange ||...
       	CapacityArr(CapSensId.CapSensId_Sec3_R_DT22).OutOfRange ||...
	CapacityArr(CapSensId.CapSensId_Sec3_R_DT23).OutOfRange ||...
	CapacityArr(CapSensId.CapSensId_Sec3_R_DT24).OutOfRange ||...
	CapacityArr(CapSensId.CapSensId_Sec3_R_DT25).OutOfRange)
    
        
        %Выбираем по какой группе считать
        
        %Группа 1
        if(CapacityArr(CapSensId.CapSensId_Sec3_R_DT21).NoData ||...
           CapacityArr(CapSensId.CapSensId_Sec3_R_DT23).NoData ||...
           CapacityArr(CapSensId.CapSensId_Sec3_R_DT25).NoData ||...
           CapacityArr(CapSensId.CapSensId_Sec3_R_DT21).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec3_R_DT23).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec3_R_DT25).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec3_R_DT21).OutOfRange ||...
           CapacityArr(CapSensId.CapSensId_Sec3_R_DT23).OutOfRange ||...
           CapacityArr(CapSensId.CapSensId_Sec3_R_DT25).OutOfRange)
        
            %Ничего не делаем
            %Возможно с другой группой повезёт больше
        else
        
            %Группа 1 исправна. Считаем по ней
            TankSensorsWorkGroup(TankId_Section31_Right) = GrType_G1;
            CapacitySummArr(TankId_Section31_Right).Val = GetSummCapForGroup(TankId_Section31_Right, GrType_G1);
            CapacitySummArr(TankId_Section31_Right).NoData = false;
            CapacitySummArr(TankId_Section31_Right).LineCut = false;
            CapacitySummArr(TankId_Section31_Right).OutOfRange = false;
        end
        
        %Группа 2
        if(CapacityArr(CapSensId.CapSensId_Sec3_R_DT22).NoData ||...
	CapacityArr(CapSensId.CapSensId_Sec3_R_DT24).NoData ||...
       	CapacityArr(CapSensId.CapSensId_Sec3_R_DT22).LineCut ||...
	CapacityArr(CapSensId.CapSensId_Sec3_R_DT24).LineCut ||...
       	CapacityArr(CapSensId.CapSensId_Sec3_R_DT22).OutOfRange ||...
	CapacityArr(CapSensId.CapSensId_Sec3_R_DT24).OutOfRange)
        
            %Ничего не делаем
            %Если и эта группа неисправна, то считать не по чем
        else
        
            %Группа 2 исправна. Считаем по ней
            TankSensorsWorkGroup(TankId_Section31_Right) = GrType_G2;
            CapacitySummArr(TankId_Section31_Right).Val = GetSummCapForGroup(TankId_Section31_Right, GrType_G2);
            CapacitySummArr(TankId_Section31_Right).NoData = false;
            CapacitySummArr(TankId_Section31_Right).LineCut = false;
            CapacitySummArr(TankId_Section31_Right).OutOfRange = false;
        end
    
    else
    
        %Считаем по суммарной группе
        TankSensorsWorkGroup(TankId_Section31_Right) = SensorsGroupEnumDef.GrType_All;
        GrType_All=SensorsGroupEnumDef.GrType_All;
        CapacitySummArr(TankId_Section31_Right).Val = GetSummCapForGroup(TankId_Section31_Right, GrType_All, CapacityArr, CapSensId,SensorsGroupEnumDef);
        CapacitySummArr(TankId_Section31_Right).NoData = false;
        CapacitySummArr(TankId_Section31_Right).LineCut = false;
        CapacitySummArr(TankId_Section31_Right).OutOfRange = false;
    end

    %Отсек 2 левый
    if(CapacityArr(CapSensId.CapSensId_Sec2_L_DT1).NoData ||...
        CapacityArr(CapSensId.CapSensId_Sec2_L_DT2).NoData ||...
        CapacityArr(CapSensId.CapSensId_Sec2_L_DT3).NoData ||...
    	CapacityArr(CapSensId.CapSensId_Sec2_L_DT4).NoData ||...
    	CapacityArr(CapSensId.CapSensId_Sec2_L_DT5).NoData ||...
    	CapacityArr(CapSensId.CapSensId_Sec2_L_DT6).NoData ||...
    	CapacityArr(CapSensId.CapSensId_Sec2_L_DT7).NoData ||...
        CapacityArr(CapSensId.CapSensId_Sec2_L_DT1).LineCut ||...
       	CapacityArr(CapSensId.CapSensId_Sec2_L_DT2).LineCut ||...
    	CapacityArr(CapSensId.CapSensId_Sec2_L_DT3).LineCut ||...
	    CapacityArr(CapSensId.CapSensId_Sec2_L_DT4).LineCut ||...
	    CapacityArr(CapSensId.CapSensId_Sec2_L_DT5).LineCut ||...
	    CapacityArr(CapSensId.CapSensId_Sec2_L_DT6).LineCut ||...
	    CapacityArr(CapSensId.CapSensId_Sec2_L_DT7).LineCut ||...
        CapacityArr(CapSensId.CapSensId_Sec2_L_DT1).OutOfRange ||...
       	CapacityArr(CapSensId.CapSensId_Sec2_L_DT2).OutOfRange ||...
	    CapacityArr(CapSensId.CapSensId_Sec2_L_DT3).OutOfRange ||...
	    CapacityArr(CapSensId.CapSensId_Sec2_L_DT4).OutOfRange ||...
	    CapacityArr(CapSensId.CapSensId_Sec2_L_DT5).OutOfRange ||...
	    CapacityArr(CapSensId.CapSensId_Sec2_L_DT6).OutOfRange ||...
	    CapacityArr(CapSensId.CapSensId_Sec2_L_DT7).OutOfRange)
    
        %Выбираем по какой группе считать
        
        %Группа 1
        if(CapacityArr(CapSensId.CapSensId_Sec2_L_DT1).NoData ||...
       	   CapacityArr(CapSensId.CapSensId_Sec2_L_DT2).NoData ||...
	   CapacityArr(CapSensId.CapSensId_Sec2_L_DT4).NoData ||...
	   CapacityArr(CapSensId.CapSensId_Sec2_L_DT6).NoData ||...
           CapacityArr(CapSensId.CapSensId_Sec2_L_DT1).LineCut ||...
       	   CapacityArr(CapSensId.CapSensId_Sec2_L_DT2).LineCut ||...
	   CapacityArr(CapSensId.CapSensId_Sec2_L_DT4).LineCut ||...
	   CapacityArr(CapSensId.CapSensId_Sec2_L_DT6).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec2_L_DT1).OutOfRange ||...
       	   CapacityArr(CapSensId.CapSensId_Sec2_L_DT2).OutOfRange ||...
	   CapacityArr(CapSensId.CapSensId_Sec2_L_DT4).OutOfRange ||...
	   CapacityArr(CapSensId.CapSensId_Sec2_L_DT6).OutOfRange)
        
            %Ничего не делаем
            %Возможно с другой группой повезёт больше
        else
        
            %Группа 1 исправна. Считаем по ней
            TankSensorsWorkGroup(TankId_Section21_Left) = GrType_G1;
            CapacitySummArr(TankId_Section21_Left).Val = GetSummCapForGroup(TankId_Section21_Left, GrType_G1);
            CapacitySummArr(TankId_Section21_Left).NoData = false;
            CapacitySummArr(TankId_Section21_Left).LineCut = false;
            CapacitySummArr(TankId_Section21_Left).OutOfRange = false;
        end
        
        %Группа 2
        if(CapacityArr(CapSensId.CapSensId_Sec2_L_DT3).NoData ||...
           CapacityArr(CapSensId.CapSensId_Sec2_L_DT5).NoData ||...
           CapacityArr(CapSensId.CapSensId_Sec2_L_DT7).NoData ||...
           CapacityArr(CapSensId.CapSensId_Sec2_L_DT3).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec2_L_DT5).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec2_L_DT7).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec2_L_DT3).OutOfRange ||...
           CapacityArr(CapSensId.CapSensId_Sec2_L_DT5).OutOfRange ||...
           CapacityArr(CapSensId.CapSensId_Sec2_L_DT7).OutOfRange)
        
            %Ничего не делаем
            %Если и эта группа неисправна, то считать не по чему
        else
        
            %Группа 2 исправна. Считаем по ней
            TankSensorsWorkGroup(TankId_Section21_Left) = GrType_G2;
            CapacitySummArr(TankId_Section21_Left).Val = GetSummCapForGroup(TankId_Section21_Left, GrType_G2);
            CapacitySummArr(TankId_Section21_Left).NoData = false;
            CapacitySummArr(TankId_Section21_Left).LineCut = false;
            CapacitySummArr(TankId_Section21_Left).OutOfRange = false;
        end
    else
    
        %Считаем по суммарной группе
        TankSensorsWorkGroup(TankId_Section21_Left) = SensorsGroupEnumDef.GrType_All;
        GrType_All=SensorsGroupEnumDef.GrType_All;
        CapacitySummArr(TankId_Section21_Left).Val = GetSummCapForGroup(TankId_Section21_Left, GrType_All, CapacityArr, CapSensId,SensorsGroupEnumDef);
        CapacitySummArr(TankId_Section21_Left).NoData = false;
        CapacitySummArr(TankId_Section21_Left).LineCut = false;
        CapacitySummArr(TankId_Section21_Left).OutOfRange = false;
    end
    
    %Отсек 2 правый
    if(CapacityArr(CapSensId.CapSensId_Sec2_R_DT26).NoData ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT27).NoData ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT28).NoData ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT29).NoData ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT30).NoData ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT31).NoData ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT32).NoData ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT26).LineCut ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT27).LineCut ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT28).LineCut ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT29).LineCut ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT30).LineCut ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT31).LineCut ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT32).LineCut ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT26).OutOfRange ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT27).OutOfRange ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT28).OutOfRange ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT29).OutOfRange ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT30).OutOfRange ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT31).OutOfRange ||...
       CapacityArr(CapSensId.CapSensId_Sec2_R_DT32).OutOfRange)
    
        %Выбираем по какой группе считать
        
        %Группа 1
        if(CapacityArr(CapSensId.CapSensId_Sec2_R_DT27).NoData ||...           
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT29).NoData ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT31).NoData ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT32).NoData ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT27).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT29).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT31).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT32).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT27).OutOfRange ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT29).OutOfRange ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT31).OutOfRange ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT32).OutOfRange)
        
            %Ничего не делаем
            %Возможно с другой группой повезёт больше
        else
        
            %Группа 1 исправна. Считаем по ней
            TankSensorsWorkGroup(TankId_Section21_Right) = GrType_G1;
            CapacitySummArr(TankId_Section21_Right).Val = GetSummCapForGroup(TankId_Section21_Right, GrType_G1);
            CapacitySummArr(TankId_Section21_Right).NoData = false;
            CapacitySummArr(TankId_Section21_Right).LineCut = false;
            CapacitySummArr(TankId_Section21_Right).OutOfRange = false;
        end
        
        %Группа 2
        if(CapacityArr(CapSensId.CapSensId_Sec2_R_DT26).NoData ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT28).NoData ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT30).NoData ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT26).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT28).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT30).LineCut ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT26).OutOfRange ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT28).OutOfRange ||...
           CapacityArr(CapSensId.CapSensId_Sec2_R_DT30).OutOfRange )
        
            %Ничего не делаем
            %Если и эта группа неисправна, то считать не по чему
        
        else
        
            %Группа 2 исправна. Считаем по ней
            TankSensorsWorkGroup(TankId_Section21_Right) = GrType_G2;
            CapacitySummArr(TankId_Section21_Right).Val = GetSummCapForGroup(TankId_Section21_Right, GrType_G2);
            CapacitySummArr(TankId_Section21_Right).NoData = false;
            CapacitySummArr(TankId_Section21_Right).LineCut = false;
            CapacitySummArr(TankId_Section21_Right).OutOfRange = false;
        end
    else
    
         %Считаем по суммарной группе
        TankSensorsWorkGroup(TankId_Section21_Right) = SensorsGroupEnumDef.GrType_All;
        GrType_All=SensorsGroupEnumDef.GrType_All;
        CapacitySummArr(TankId_Section21_Right).Val = GetSummCapForGroup(TankId_Section21_Right, GrType_All, CapacityArr, CapSensId,SensorsGroupEnumDef);
        CapacitySummArr(TankId_Section21_Right).NoData = false;
        CapacitySummArr(TankId_Section21_Right).LineCut = false;
        CapacitySummArr(TankId_Section21_Right).OutOfRange = false;
    end
end

%------------------------------------------------------------------------------
%Диэлектрические проницаемости топлива в баках с ДХТ
%MassDataStructDef.e_t_dht1;%/< Диэлектрическая проницаемость топлива посчитанная по ДХТ1
%MassDataStructDef.e_t_dht2;%/< Диэлектрическая проницаемость топлива посчитанная по ДХТ2

%/ \var GradTableRecordStructDef TablePoints
%/ \brief Массив используемый для расчёта искомой точки в таблице
%/ Данный массив используется для расчёта значения обёма по таблице. В массиве всего две точки.
%/ (0) - точка меньше заданной. (1) - точка больше заданной
%GradTableRecordStructDef.TablePoints(2);

%/ \brief Чтение данных градуировочной таблицы с указанной микросхемы
%/ \param(in) chip Идентификатор микросхемы памяти
%/ \param(in) vector Структура содержащая информацию о считываемой таблице
%/ \param(in) TankCapacity Ёмкость для которой в таблице ищется объём
%/ \param(out) Volume Объём полученый из таблицы по заданной ёмкости
%/ \return true - если объём успешно найден; false - если по каким-то причинам вычислить объём не удалось
function bool = MassCalc_ReadGradTable( chip, VectorTableRecordStructDef, BKD_Param_Stuct, MassDataStructDef)

    VectorTableRecordStructDef.vector;
     BKD_Param_Stuct.TankCapacity;
      MassDataStructDef.Volume;

    %/ <b>Последовательность работы: </b>
    
    %Если верхнее и нижне значения равны - либо попали точно в точку либо вышли за диапазон таблицы
    %нет смысла экстрополировать данные при выходе за диапазон. Это почти аварийная ситуация

    memset(TablePoints,0x00,sizeof(GradTableRecordStructDef)*2);
    
    FindMin = false;%Признак того что точка меньше заданного значения найдена
    FindMax = false;%Признак того что точка больше заданного значения найдена

    %/ - Контроль валидности входной ёмкости @p TankCapacity
    if(TankCapacity.NoData || TankCapacity.LineCut)%Если данные не поступают
    %{
 	Volume.Value = 0;
	Volume.NoData = true;
	Volume.InvalidData = true; 
    %}

    bool = false;
    end

     ChipCS = chip + 2;
    
    %Считать нужно всю таблицу для проверки сходимости CRC
    %Если контрольная сумма не сошлась забраковать микросхему и попробовать поискать на следующей
    BytesToRead = vector.RecordNum * Memory_GradTableRecordSize + 2;%2 - байты контрольной суммы
    TotalBytesReaded = 0;%Общее количество уже считанных
    LastBytesReaded = 0;%Количество байт считанное последней операцией чтения

    C_crc16 = 0xFFFF;%Посчитанное значение контрольной суммы

    while(BytesToRead ~= 0)
    
	    RecordsInPack;%Количество записей в считанном фрагменте

        %/ - Чтение набора данных с указанной микросхемы памяти        
	    if(BytesToRead > Memory_Com_Arr_Size)%Если количество байт ожидающих чтения больше размера буфера
	
	        Memory2_ReadArray(ChipCS, vector.Address + TotalBytesReaded, Memory_Com_Arr_Size, Memory_Com_Arr);
	        TotalBytesReaded = Memory_Com_Arr_Size + TotalBytesReaded;
	         LastBytesReaded = Memory_Com_Arr_Size;
	        BytesToRead =BytesToRead - Memory_Com_Arr_Size;

	        RecordsInPack = Memory_Com_Arr_Size/Memory_GradTableRecordSize;
	    else%Количество байт ожидающих чтения меньше размера буфера
	
	         Memory2_ReadArray(ChipCS, vector.Address + TotalBytesReaded, BytesToRead, Memory_Com_Arr);
	        TotalBytesReaded = TotalBytesReaded + BytesToRead;
	         LastBytesReaded = BytesToRead;	     

	        RecordsInPack = (BytesToRead - 2)/Memory_GradTableRecordSize;
             
             BytesToRead = BytesToRead - BytesToRead;% = 0
	    end

	%/ - Расчёт контрольной суммы
	if(BytesToRead ~= 0)%Ещё не дочитали до конца
	
            C_crc16 = Crc16(Memory_Com_Arr, LastBytesReaded, C_crc16);
	else%Считана последняя часть. Последни 2 байта - контрольная сумма
	
	    C_crc16 = Crc16(Memory_Com_Arr, LastBytesReaded - 2, C_crc16);

	    %Принятая контрольная сумма
	    R_crc16 = 1;%(Memory_Com_Arr(LastBytesReaded - 1) << 8) | Memory_Com_Arr(LastBytesReaded - 2);

	    if(R_crc16 ~= C_crc16)%Если контрольная сумма не сошлась
	    
		%Volume.Val = 0;
		%Volume.LineCut = TankCapacity.LineCut;
		%Volume.NoData = TankCapacity.NoData;
		%Volume.OutOfRange = TankCapacity.OutOfRange;
		bool = false;
	    end
	end

	%/ - Расшифоровка принятых данных и поиск точек с значениями ёмкости выше и ниже заданной ёмкасти
        for i = 0+1:RecordsInPack
            GradTableRecordStructDef.record;
            GradTableRecordStructDef.record.Capacity = BytesTo(Memory_Com_Arr + i * Memory_GradTableRecordSize);

            
	        if( GradTableRecordStructDef.record.Capacity <= TankCapacity.Val)
	    
		    FindMin = true;
            GradTableRecordStructDef.record.Volume = BytesTo(Memory_Com_Arr + i * Memory_GradTableRecordSize + 4);
		    TablePoints(0) =  GradTableRecordStructDef.record;
	        end
	        if(( GradTableRecordStructDef.record.Capacity >= TankCapacity.Val) && (FindMax == false))%Интересует только первая точка превысившая заданное значение
	    
		    FindMax = true;
            GradTableRecordStructDef.record.Volume = BytesTo(Memory_Com_Arr + i * Memory_GradTableRecordSize + 4);
		    TablePoints(1) =  GradTableRecordStructDef.record;
	        end 
	    end
    end

    %/ - Анализ найденных точек.
    if((FindMin == false) && (FindMax == false))
    
	%Какой-то косяк. Сюда прога не должна никогда попадать
	%Volume.Val = 0;
	%Volume.LineCut = TankCapacity.LineCut;
	%Volume.NoData = TankCapacity.NoData;
	%Volume.OutOfRange = TankCapacity.OutOfRange;
	bool =  false;
    end

    %/ - Если в таблице не было точек больше заданной, значит заданная точка за пределами верхнего диапазона.
    %/ В этом случае @p Volume присваивается максимальное значение объёма в таблице.
    if((FindMin == true)&&(FindMax == false))
    
	%Выход за предельное максимальное значение
	Volume.Value = TablePoints(0).Volume;%0 - точка минимума
    end

    %/ - Если в таблице не было точек меньше заданной, значит заданная точка за пределами нижнего диапазона.
    %/ В этом случае @p Volume присваивается минимально значение объёма в таблице.
    %/ Но теоретически сюда не должны никогда попадать.
    if((FindMin == false)&&(FindMax == true))
    
	%Выход за предельное минимальное значение
	Volume.Value = TablePoints(1).Volume;%1 - точка максимума
    end

    if((FindMin == true)&&(FindMax == true))
    	
        if(TablePoints(0).Capacity == TablePoints(1).Capacity)
	
	        %/ - Если значение одной из найденных точек в таблице совпадает с 
            %/ заданным значением ёмкости @p TankCapacity дальнейшие расчёты не нужны.
            %/ Попали точно в заданную точку. @p Volume присваивается значение соответствующее найденной точке
	        Volume.Value = TablePoints(0).Volume;
            
            %if(TablePoints(0).Volume ~= TablePoints(1).Volume)
            %    return false;
	    else
	
	        %/ - Линейная интерполяция объёма по двум точкам таблицы.
            %/ <b> Интерполяция выполняется по следующей формуле: </b> <br>
            %/ k = (V2 - V1)/(C2 - C1) <br>
            %/ b = V1 - k * C1 <br>
            %/ @p Volume = k * @p TankCapacity + b
	        kval;
	        bval;

	        kval = (TablePoints(1).Volume - TablePoints(0).Volume)/(TablePoints(1).Capacity - TablePoints(0).Capacity);
	        bval = TablePoints(0).Volume - kval * TablePoints(0).Capacity;

	        Volume.Value = kval * TankCapacity.Val + bval;
	    end
    end

    %Volume.LineCut = TankCapacity.LineCut;
    %Volume.NoData = TankCapacity.NoData;
    %Volume.OutOfRange = TankCapacity.OutOfRange;        
    
    bool = true;
end

%/ \brief Расчёт значения плотности в указанном баке <br>
%/ Формула по которой производится расчёт: <br>
%/ pi  = pдхт – kp(t)i*( ti  - tдхт), кг/м3 <br>
%/ где: <br>
%/ pдхт – текущая плотность топлива, измеренная датчиком ДХТ, кг/м3 <br>
%/ ti – текущая температура топлива в i-ом баке, оС <br>
%/ tдхт – текущая температура топлива, измеренная датчиком ДХТ, оС <br>
%/ kp(t)i – температурная поправка плотности топлива на 1 оС, кг/(м3 * оС).
%/ \param(in) Tank Идентификатор топливного бака
%/ \param(in) Temperature температура топлива в указанном баке
%/ \param(in) e_t_i Значение диэлектрической проницаемости топлива в баке
%/ \return Возвращает значение плотности в баке с учётом текущей температуры
function [pi] = MassCalc_DensityInTank( Tank, MassDataStructDef, e_t_i)

TankId_Centr = 0+1;            %/< Идентификатор центрального топливного бака
TankId_RO_Left = 1+1;          %/< Идентификатор расходного отсека левого борта
TankId_Section21_Left = 2+1;   %/< Идентификатор бака 2 левого борта
TankId_Section31_Left = 3+1;   %/< Идентификатор бака 3 левого борта
TankId_RO_Right = 4+1;         %/< Идентификатор расходного отсека правого борта
TankId_Section21_Right = 5+1;  %/< Идентификатор бака 2 правого борта
TankId_Section31_Right = 6+1;  %/< Идентификатор бака 3 правого борта
TankId_DHT1 = 7+1;             %/< Идентификатор ДХТ1
TankId_DHT2 = 8+1;             %/< Идентификатор ДХТ2

p_def =  788;
    %extern BKD_Param_Stuct WorkDensity_DHT1;%Плотность полученная от ДХТ1
    %extern BKD_Param_Stuct WorkDensity_DHT2;%Плотность полученная от ДХТ2
    
    %extern BKD_Param_Stuct WorkTemperature_DHT1;%Температура полученная от ДХТ1
    %extern BKD_Param_Stuct WorkTemperature_DHT2;%Температура полученная от ДХТ2
    pi = MassDataStructDef;
    
    %MassDataStructDef.pi;
    pi.NoData = false;
    pi.InvalidData = false;
    
    %ВНИМАНИЕ~~~~
    %НА ЭТАПЕ ПЕРЕСЧЁТА СОПРОТИВЛЕНИЙ В МАССЫ
    %ЗНАЧЕНИЕ ТЕМПЕРАТУРЫ ДХТ ЗАМЕНЯЕТСЯ НА
    %ТЕМПЕРАТУРЫ ИХ ВНЕШНИХ ТЕРМОДАТЧИКОВ
    %смотри функцию  TranslateResToTemp[]
    
    switch(Tank)
    
    case TankId_Centr %Считаем что центральный слева            
        case TankId_Section21_Left
            case TankId_RO_Left
                case TankId_Section31_Left  
                    if(Temperature.NoData)
        
                        %Если не знаём температуру берём значение по умолчанию
                        pi.Value = p_def;
                        pi.InvalidData = true;
                        
                    end
        
                if(WorkDensity_DHT1.NoData || WorkDensity_DHT1.LineCut || WorkDensity_DHT1.OutOfRange ||...
                    WorkTemperature_DHT1.NoData || WorkTemperature_DHT1.LineCut || WorkTemperature_DHT1.OutOfRange)
        
                    if(WorkDensity_DHT2.NoData || WorkDensity_DHT2.LineCut || WorkDensity_DHT2.OutOfRange ||...
                        WorkTemperature_DHT2.NoData || WorkTemperature_DHT2.LineCut || WorkTemperature_DHT2.OutOfRange)
            
                        %Если со вторым тоже что-то не так берём значение по умолчанию
                        pi.Value = p_def - kp_t_i * (Temperature.Value - 20);
                        pi.InvalidData = true;
                
                    else
            
                        pi.Value = WorkDensity_DHT2.Val - kp_t_i * (Temperature.Value - WorkTemperature_DHT2.Val);
                    end            
                else
                    %Данные ДХТ1 корректны
                    pi.Value = WorkDensity_DHT1.Val - kp_t_i * (Temperature.Value - WorkTemperature_DHT1.Val);
                end
   
        if(Temperature.InvalidData)
            pi.InvalidData = true;                
            
        end

    case TankId_Section21_Right
        case TankId_RO_Right
            case TankId_Section31_Right  
                if(Temperature.NoData)
        
                    %Если не знаём температуру тоже берём значение по умолчанию
                    pi.Value = p_def;
                    pi.InvalidData = true;
                    
                end
        
        if(WorkDensity_DHT2.NoData || WorkDensity_DHT2.LineCut || WorkDensity_DHT2.OutOfRange ||...
           WorkTemperature_DHT2.NoData || WorkTemperature_DHT2.LineCut || WorkTemperature_DHT2.OutOfRange)
            if(WorkDensity_DHT1.NoData || WorkDensity_DHT1.LineCut || WorkDensity_DHT1.OutOfRange ||...
               WorkTemperature_DHT1.NoData || WorkTemperature_DHT1.LineCut || WorkTemperature_DHT1.OutOfRange)
                %Если со вторым тоже что-то не так берём значение по умолчанию
                pi.Value = p_def - kp_t_i * (Temperature.Value - 20);
                pi.InvalidData = true;
            else
                pi.Value = WorkDensity_DHT1.Val - kp_t_i * (Temperature.Value - WorkTemperature_DHT1.Val);
            end            
        else
            %Данные ДХТ2 корректны
            pi.Value = WorkDensity_DHT2.Val - kp_t_i * (Temperature.Value - WorkTemperature_DHT2.Val);
        end
    
        if(Temperature.InvalidData)
            pi.InvalidData = true;
        
        end
    end
    
    %Установка значения по умолчанию если полученное значение неадекватно
    if((pi.Value < 600) || (pi.Value>1200))
        pi.Value = p_def;
        return;
    end
end

%/ \brief Расчёт диэлектрической проницаемости топлива в баке с ДХТ1 <br>
%/ Формула по которой производится расчёт: <br>
%/ εtдхт = (Cдхт - CдхтРег0) / Cдхт0 <br>
%/ где: <br>
%/ Cдхт – текущая ёмкость датчика ДХТ, пФ <br>
%/ CдхтРег0 - поправка к ёмкости датчика ДХТ в пустом баке для регулирования нулевого (сухого) значения ёмкости датчика, пФ <br>
%/ Cдхт0 - ёмкость датчика ДХТ в пустом баке, пФ (сухая ёмкость, по КД) 
%/ \return Возвращает значение диэлектрической проницаемости топлива вычисленное по датчику ДХТ1
function [Res] = MassCalc_DielPronCalcDHT1(Res,CapacityArr,CapSensId,SensorsGroupEnumDef)
    TankId_DHT1 = 7+1;             %/< Идентификатор ДХТ1
    TanksInfo_EmptyCap_DHT=49.0;
    %Res = MassDataStructDef;

    Res.NoData = CapacityArr( CapSensId.CapSensId_Sec3_L_DHT1 ).NoData ||...
        CapacityArr( CapSensId.CapSensId_Sec3_L_DHT1 ).LineCut;
    
    Res.Value = (CapacityArr( CapSensId.CapSensId_Sec3_L_DHT1 ).Val -...
        TanksInfo_GetZeroReg(TankId_DHT1, SensorsGroupEnumDef.GrType_All))/TanksInfo_EmptyCap_DHT;
    
    for i = 1:length(Res.Value)
        if((Res.Value(i) < 1.916) || (Res.Value(i) > 2.276) || Res.NoData(i))
    
            Res.Value(i) = 2.096;
            Res.InvalidData(i) = true;
        end
    end
    Res.InvalidData = CapacityArr( CapSensId.CapSensId_Sec3_L_DHT1 );
end

%/ \brief Расчёт диэлектрической проницаемости топлива в баке с ДХТ2 <br>
%/ Формула по которой производится расчёт: <br>
%/ εtдхт = (Cдхт - CдхтРег0) / Cдхт0 <br>
%/ где: <br>
%/ Cдхт – текущая ёмкость датчика ДХТ, пФ <br>
%/ CдхтРег0 - поправка к ёмкости датчика ДХТ в пустом баке для регулирования нулевого (сухого) значения ёмкости датчика, пФ <br>
%/ Cдхт0 - ёмкость датчика ДХТ в пустом баке, пФ (сухая ёмкость, по КД) 
%/ \return Возвращает значение диэлектрической проницаемости топлива вычисленное по датчику ДХТ2
function [Res] = MassCalc_DielPronCalcDHT2(Res,CapacityArr,CapSensId,SensorsGroupEnumDef)
TankId_DHT2 = 8+1;             %/< Идентификатор ДХТ2
TanksInfo_EmptyCap_DHT=49.0;

    Res.NoData = CapacityArr( CapSensId.CapSensId_Sec3_R_DHT2 ).NoData || ...
        CapacityArr( CapSensId.CapSensId_Sec3_R_DHT2 ).LineCut;
    
    Res.Value = (CapacityArr( CapSensId.CapSensId_Sec3_R_DHT2 ).Val - TanksInfo_GetZeroReg(TankId_DHT2, SensorsGroupEnumDef.GrType_All))/TanksInfo_EmptyCap_DHT;
    
    for i = 1:length(Res.Value)
        if((Res.Value(i) < 1.916) || (Res.Value(i) > 2.276) || Res.NoData(i))
    
            Res.Value(i) = 2.096;
            Res.InvalidData(i) = true;
        end
    end
    if (i==length(Res.Value))
        return;
    end
    
    Res.InvalidData = CapacityArr( CapSensId_Sec3_R_DHT2 ).OutOfRange;
    %return;
end

%/ \brief Пересчёт значения диэлектрической проницаемости топлива в указанном баке с учётом температуры топлива в баке<br>
%/ Считается по формуле: <br>
%/ e_t_i = e_t_dht - ke_t_i*(Температура в баке - Температура ДХТ)
%/ \param(in) Tank Идентификатор топливного бака
%/ \param(in) Temperature температура топлива в указанном баке
%/ \return Возвращает значение диэлектрической проницаемости топлива в указанном баке
function [MassDataStructDef] = MassCalc_DielPronCalc( MassDataStructDef, Tank, Temperature, ...
    e_t_dht1,e_t_dht2,WorkTemperature_DHT1,WorkTemperature_DHT2)

TankId_Centr = 0+1;            %/< Идентификатор центрального топливного бака
TankId_RO_Left = 1+1;          %/< Идентификатор расходного отсека левого борта
TankId_Section21_Left = 2+1;   %/< Идентификатор бака 2 левого борта
TankId_Section31_Left = 3+1;   %/< Идентификатор бака 3 левого борта
TankId_RO_Right = 4+1;         %/< Идентификатор расходного отсека правого борта
TankId_Section21_Right = 5+1;  %/< Идентификатор бака 2 правого борта
TankId_Section31_Right = 6+1;  %/< Идентификатор бака 3 правого борта
et_20_def = 2.096;

    e_t_i = MassDataStructDef ;       
    
    %extern BKD_Param_Stuct WorkTemperature_DHT1;%Температура полученная от ДХТ1
    %extern BKD_Param_Stuct WorkTemperature_DHT2;%Температура полученная от ДХТ2 
    
    e_t_i.NoData = false;
    e_t_i.InvalidData = false;

    switch(Tank)
    
        case TankId_Centr%Считается как левый борт
        case TankId_Section21_Left
            if(e_t_dht1.InvalidData || e_t_dht1.NoData || WorkTemperature_DHT1.NoData || WorkTemperature_DHT1.LineCut || WorkTemperature_DHT1.OutOfRange)
        
                %С левым ДХТ что-то не так. Пробуем взять данные правого
                if(e_t_dht2.InvalidData || e_t_dht2.NoData || WorkTemperature_DHT2.NoData || WorkTemperature_DHT2.LineCut || WorkTemperature_DHT2.OutOfRange)
            
                    %От второго ДХТ тоже нет данных. Берём значения по умолчанию
                    e_t_i.Value = et_20_def;
                    e_t_i.InvalidData = true;
                else
                        
                    e_t_i.Value = e_t_dht2.Value - ke_t_i * (Temperature.Value - WorkTemperature_DHT2.Val);
                end  
            else
                %Левый ДХТ исправен. Берём данные с него
                e_t_i.Value = e_t_dht1.Value - ke_t_i * (Temperature.Value - WorkTemperature_DHT1.Val);                         
            end
        
            if(Temperature.NoData)
        
                %Берём значение по умолчанию
                e_t_i.Value = et_20_def;
                e_t_i.InvalidData = true;
            end
            if(Temperature.InvalidData)
                e_t_i.InvalidData = true;
            
            end

        case TankId_Section31_Left

        case TankId_RO_Left
            if(e_t_dht1.NoData || e_t_dht1.InvalidData)
        
                %Берём данные ДХТ другого борта и корректируем их по температуре
                if(e_t_dht2.NoData || e_t_dht2.InvalidData || WorkTemperature_DHT2.NoData || WorkTemperature_DHT2.LineCut || WorkTemperature_DHT2.OutOfRange)
            
                    e_t_i.Value = et_20_def;
                    e_t_i.InvalidData = true;
                else
                    e_t_i.Value = e_t_dht2.Value - ke_t_i * (Temperature.Value - WorkTemperature_DHT2.Val);
                end
            end
            if(Temperature.NoData)
            
                %Если не знаем температуры берём значение по умолчанию
                e_t_i.Value = et_20_def;
                e_t_i.InvalidData = true;
            end
            
            if(Temperature.InvalidData)
                e_t_i.InvalidData = true;
            else        
                e_t_i = e_t_dht1;%Данные ДХТ бака пригодны для использования
            end

        case TankId_Section31_Right    

        case TankId_RO_Right
            if(e_t_dht2.NoData || e_t_dht2.InvalidData)
        
                %Берём данные ДХТ другого борта и корректируем их по температуре
                if(e_t_dht1.NoData || e_t_dht1.InvalidData || WorkTemperature_DHT1.NoData || WorkTemperature_DHT1.LineCut || WorkTemperature_DHT1.OutOfRange)
            
                    e_t_i.Value = et_20_def;
                    e_t_i.InvalidData = true;
                else
            
                    e_t_i.Value = e_t_dht1.Value - ke_t_i * (Temperature.Value - WorkTemperature_DHT1.Val);
                end
            
                if(Temperature.NoData)
            
                    %Если не знаем температуры берём значение по умолчанию
                    e_t_i.Value = et_20_def;
                    e_t_i.InvalidData = true;
                end
            
                if(Temperature.InvalidData)
                    e_t_i.InvalidData = true;
                else        
                    e_t_i = e_t_dht2;%Данные ДХТ бака пригодны для использования
                end
            end
     case TankId_Section21_Right
        if(e_t_dht2.InvalidData || e_t_dht2.NoData || WorkTemperature_DHT2.NoData || WorkTemperature_DHT2.LineCut || WorkTemperature_DHT2.OutOfRange)
        
            %С правым ДХТ что-то не так. Пробуем взять данные левого
            if(e_t_dht1.InvalidData || e_t_dht1.NoData || WorkTemperature_DHT1.NoData || WorkTemperature_DHT1.LineCut || WorkTemperature_DHT1.OutOfRange)
            
                %От второго ДХТ тоже нет данных. Берём значения по умолчанию
                e_t_i.Value = et_20_def;
                e_t_i.InvalidData = true;
            else
                        
                e_t_i.Value = e_t_dht1.Value - ke_t_i * (Temperature.Value - WorkTemperature_DHT1.Val);
            end  
        else
        
            %Левый ДХТ исправен. Берём данные с него
            e_t_i.Value = e_t_dht1.Value - ke_t_i * (Temperature.Value - WorkTemperature_DHT1.Val);                         
        end
        
        if(Temperature.NoData)
        
            %Берём значение по умолчанию
            e_t_i.Value = et_20_def;
            e_t_i.InvalidData = true;
        end
        if(Temperature.InvalidData)
            e_t_i.InvalidData = true;        
        %
        end
    end         
    return;
end

%/ \brief Вычисление объёма топлива в соответствующем баке
%/ \param(in) Tank Идентификатор топливного бака
%/ \param(in) Pitch Тангаж
%/ \param(in) Roll Крен
%/ \param(out) Density Значение плотности топлива пересчитанное к реальной температуре
%/ \param(out) TankTemperature Температура топлива в баке
%/ \return Возвращает значение диэлектрической проницаемости топлива в указанном баке
function [MassDataStructDef, Density] = MassCalc_FindVolume( Tank,  Pitch,  Roll, ...
    Density, TankTemperature, CapacitySummArr,BKD_Param_Stuct, MassDataStructDef, ...
    e_t_dht1,e_t_dht2,WorkTemperature_DHT1,WorkTemperature_DHT2)
TankId_Centr = 0+1;            %/< Идентификатор центрального топливного бака
TankId_RO_Left = 1+1;          %/< Идентификатор расходного отсека левого борта
TankId_Section21_Left = 2+1;   %/< Идентификатор бака 2 левого борта
TankId_Section31_Left = 3+1;   %/< Идентификатор бака 3 левого борта
TankId_RO_Right = 4+1;         %/< Идентификатор расходного отсека правого борта
TankId_Section21_Right = 5+1;  %/< Идентификатор бака 2 правого борта
TankId_Section31_Right = 6+1;  %/< Идентификатор бака 3 правого борта
TankId_DHT1 = 7+1;             %/< Идентификатор ДХТ1
TankId_DHT2 = 8+1;             %/< Идентификатор ДХТ2


    %/ <b>Последовательность работы </b> 
    
    %extern bool Memory2_ChipFaults(Memory2_ChipsNum);
    SimetrTank = false;
         
    %Volume = MassDataStructDef;%Значение объёма полученное из градуировочной таблицы
    Volume.Value = 0;
    Volume.NoData = false;
    Volume.InvalidData = false;

    %ChipsReadError = AllChipsFault;%Признак того что все микросхемы памяти неработоспособны

    %BKD_Param_Stuct WorkCapacity;%Рабочее значение ёмкости
    WorkCapacity.Val = 0;
    WorkCapacity.NoData = true;
    WorkCapacity.LineCut = false;
    WorkCapacity.OutOfRange = false;

    %/ - Извлечение из массива значения суммарной ёмкости датчиков в баке и определение группы датчиков по которой посчитана сумма
    %В случае обрыва или отсутствия данных пробуем взять данные симетричного бака
    if(CapacitySummArr(Tank).NoData || CapacitySummArr(Tank).LineCut ||  CapacitySummArr(Tank).OutOfRange)
    
	        Volume.InvalidData = true;%Информируем что параметр может быть недостоверным

             Volume.Value = 0;
	        Volume.NoData = true;
    else
    
	        %Если нет обрыва и данные поступают, работаем с той ёмкостью какая есть
	        WorkCapacity = CapacitySummArr(Tank);
    end
	%Если один из датчиков в баке информирует о выходе за допустимый диапазон
	%информируем что параметр может быть недостоверным
	if(CapacitySummArr(Tank).OutOfRange)
	    Volume.InvalidData = true;
        %Если считаем не по всем датчикам, а по группе информируем о проблеме
        if(TankSensorsWorkGroup(Tank) ~= GrType_All)
            Volume.InvalidData = true;
        end
    end

    %/ - Получение информации о температуре топлива в баке @ref MassCalc_GetTankTemperature
        TankTemperature = MassCalc_GetTankTemperature(Tank,BKD_Param_Stuct,MassDataStructDef);
        if(TankTemperature.InvalidData)
	        Volume.InvalidData = true;
        end
        if(TankTemperature.NoData)
	        Volume.NoData = true;
        end

    %/ - Расчёт диэлектрической проницаемости в выбранном баке @ref MassCalc_DielPronCalc
    MassDataStructDef= MassCalc_DielPronCalc(MassDataStructDef, Tank, TankTemperature, ...
        e_t_dht1,e_t_dht2,WorkTemperature_DHT1,WorkTemperature_DHT2);
    e_t_i = MassDataStructDef.e_t_i;
    %/ - Расчёт плотности топлива в баке @ref MassCalc_DensityInTank
    pi = TankTemperature;
    Density = MassCalc_DensityInTank( Tank, TankTemperature, e_t_i);

    if(Volume.NoData)%Если данных нет вообще дальнейшие расчёты бесполезны
	 fprintf("данных нет вообще дальнейшие расчёты бесполезны");
    end
    
    %/ - Применение регулировочного коэффициента нуля к рабочей ёмкости. Получение относительной ёмкости группы датчиков
    if(WorkCapacity.NoData ~= true)
    	WorkCapacity.Val = (WorkCapacity.Val - TanksInfo_GetEmptyTankCap(Tank, TankSensorsWorkGroup(Tank)) - TanksInfo_GetZeroReg(Tank, TankSensorsWorkGroup(Tank)))/(e_t_i.Value - e_v_i);%e_v_i
        if(WorkCapacity.Val < 0)
	    WorkCapacity.Val = 0;
        end
    end

    ChipsReadError = true; %Для проверки встроенных градуеровочных таблиц

    %Для баков правого борта необходимо инвертировать значение крена
    %чтобы правильно считалиcь таблицы
    if(~SimetrTank)
    
        %Работаем по данным выбранного бака
        if((Tank == TankId_RO_Right) ||...
           (Tank == TankId_Section21_Right) ||...
           (Tank == TankId_Section31_Right))
            Roll = Roll .* (-1);
        end
    else
    
        %Работаем по ёмкости симетричного бака
        if((Tank == TankId_RO_Left) || ...
           (Tank == TankId_Section21_Left) ||...
           (Tank == TankId_Section31_Left))
            Roll = Roll * (-1);
        end
    end
    
    if(ChipsReadError ~= true)
    
	VectorTableRecordStructDef.ChipsVectors(Memory2_ChipsNum);%массив векторов полученных с каждой микросхемы
	ResultsArr(Memory2_ChipsNum);%Массив результатов поиска таблиц

	if(Volume.NoData ~= true)%Если данных нет не имеет смысла тратить время на чтение таблиц
	
	    %/ - Поиск векторов градуировочных таблиц в микросхемах памяти                      
            
	    %Подбор ниаболее подходящей таблицы в каждой из микросхем
	    for Chip = 0+1:Memory2_ChipsNum
	    
		    if( Memory2_ChipFaults(Chip) ~= true )%Проверить что микросхема рабочая. Не в отказе
		        ResultsArr(Chip) = MassCalc_FindVector(Chip, Tank, TankSensorsWorkGroup(Tank), Pitch, Roll, ChipsVectors(Chip));
		    else
		        ResultsArr(Chip) = false;
            end
	    end

	    %/ - Выбор наиболее подходящего вектора из найденных
	    BestVectorChipNum;%номер микросхемы памяти где лежит лучший вектор
	    TableReadyForWork = false;%Признак того что данные таблицы были считаны вез проблем

	    while((TableReadyForWork ~= true) && (MassCalc_SelectVector(ChipsVectors, Pitch, Roll, ResultsArr, BestVectorChipNum) ~= false))
	    
		    %/ - Чтение градуировочной таблицы из памяти. Получение объёма по емкостям.
		    ResultsArr(BestVectorChipNum) = MassCalc_ReadGradTable(BestVectorChipNum, ChipsVectors(BestVectorChipNum), WorkCapacity, Volume);

		    if(ResultsArr(BestVectorChipNum))%Проверяем что таблица была считана и объём был получен
		        TableReadyForWork = true;
	        end

	        %Если ни одну таблицу не удалось считать
	        if(TableReadyForWork == false)
		        ChipsReadError = true;
            end
	    end
    end

        if(ChipsReadError)
	        %/ - Если все три микросхемы памяти в отказе
	        %/ ВЗЯТЬ СИЛЬНО УРЕЗАННЫЕ ГРАДУИРОВОЧНЫЕ ТАБЛИЦЫ ПО УМОЛЧАНИЮ(ЧТОБЫ ХОТЬ КАК-ТО ПОМЕРИТЬ МАССЫ)
        
	        %Сформировать признак того что значение может быть недостоверным

	        if(Volume.NoData ~= true)
	
	            Volume.InvalidData = true;
	            Volume.Value = TanksInfo_GetDefaultVolume(Tank, WorkCapacity.Val);
	        end
        end
        return;
    end
end
%/ \brief Пересчёт найденного значения объёма топлива в массу. <br>
%/ Пересчёт происходит по следующей формуле: <br>
%/ Масса = Объём * Плотность * Регулировочный коэффициент максимума
%/ \param(in) Tank Идентификатор топливного бака
%/ \param(in) Volume Значение объёма топлива в указанном баке
%/ \param(in) Density Значение плотности топлива в указанном топливном баке
%/ \return Возвращает значение массы топлива в указанном топливном баке
function [Result] = VolumeToMassCalc(Tank,Volume,Density)
    %extern  TanksInfo_MaxRegArr( TanksInfo_MaxRegArrSize );

    TanksInfo_MaxRegArrSize = ones(9,1);%всегда 1 Саша проинформировал 
    
    Result = struct();
    Result.Value =0;
    %memset(&Result, 0x00, sizeof(MassDataStructDef));
    Result.Value = Volume.Value * Density.Value * 1;%TanksInfo_MaxRegArr(Tank);

    if(Volume.NoData || Density.NoData)
	Result.NoData = true;
    end
    
    if(Volume.InvalidData || Density.InvalidData)
	Result.InvalidData = true;
    end

end




%======================================================================================================
%/// \brief Получение значения регулировочного коэфициента нуля указанного бака
%/// \note Реализует требование: RQ_BVKT_S_LL_244
%/// \param[in] Tank Идентификатор бака
%/// \param[in] Group Идентификатор группы датчиков в баке
%/// \return Возвращает значение регулировочного коэффициента нуля указанной группы в баке
% всегда 0
function [out] = TanksInfo_GetZeroReg(Tank, Group)
TankId_Centr = 0+1;            %/< Идентификатор центрального топливного бака
TankId_RO_Left = 1+1;          %/< Идентификатор расходного отсека левого борта
TankId_Section21_Left = 2+1;   %/< Идентификатор бака 2 левого борта
TankId_Section31_Left = 3+1;   %/< Идентификатор бака 3 левого борта
TankId_RO_Right = 4+1;         %/< Идентификатор расходного отсека правого борта
TankId_Section21_Right = 5+1;  %/< Идентификатор бака 2 правого борта
TankId_Section31_Right = 6+1;  %/< Идентификатор бака 3 правого борта
TankId_DHT1 = 7+1;             %/< Идентификатор ДХТ1
TankId_DHT2 = 8+1;             %/< Идентификатор ДХТ2

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

%/ Общее количество групп в баках (включая общие)
GroupsNumForTanks = 10;

%// Размер массива, хранящего регулировочные коэффициенты нуля
TanksInfo_ZeroRegArrSize = (GroupsNumForTanks * 2 - 3 + 2);    

TanksInfo_ZeroRegArr = ones(TanksInfo_ZeroRegArrSize,1);
 switch(Tank)

    case TankId_Centr
        switch(Group)

        case GrType_All 
            out = TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_All_Centr);
        case GrType_G1 
            out = TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_G1_Centr);
        case GrType_G2
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_G2_Centr);
        end
        %break;
    case TankId_RO_Left
        switch(Group)

        case GrType_All
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_All_RO_L);
        end
        %break;
    case TankId_Section21_Left
        switch(Group)

        case GrType_All
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_All_Section21_L);
        case GrType_G1
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_G1_Section21_L);
        case GrType_G2
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_G2_Section21_L);
        end
        %break;
    case TankId_Section31_Left
        switch(Group)

        case GrType_All
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_All_Section31_L);
        case GrType_G1
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_G1_Section31_L);
        case GrType_G2
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_G2_Section31_L);
        end
        %break;
    case TankId_RO_Right
        switch(Group)

        case GrType_All
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_All_RO_R);
        end
        %break;
    case TankId_Section21_Right
        switch(Group)

        case GrType_All
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_All_Section21_R);
        case GrType_G1
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_G1_Section21_R);
        case GrType_G2
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_G2_Section21_R);
        end
        %break;
    case TankId_Section31_Right
        switch(Group)

        case GrType_All
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_All_Section31_R);
        case GrType_G1
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_G1_Section31_R);
        case GrType_G2
            out =  TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_GrID_G2_Section31_R);
        end
        %break;
    case TankId_DHT1
        out = TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_DHT1);
        %break;
    case TankId_DHT2
        out = TanksInfo_ZeroRegArr(TanksInfo_ZeroReg_DHT2);
        %break;
 end
    %return 0;%//Ошибка. Не знаю как ещё её отработать
end

%add from Sascha 121024
%/// \brief Выполнение медианной фильтрации указанного массива. <br>
%/// В ходе фильтрации выполняется сортировка массива DataArr. <br>
%/// В качестве выходного значения выдаётся значение среднего элемента отсортированного массива. <br>
%/// Рекомендуется не использовать нечётные размерности мессива. <br>
%/// \note Реализует требование: RQ_BVKT_S_LL_81
%/// \param[in] DataArr Указатель на первый элемент фильтруемого массива
%/// \param[in] DataArrLength Количество записей в фильтруемом наборе данных
%/// \return Возвращает среднее значение фильтруемого набора данных
function [ValArr] = MedianFiltr_GetValue(DataArr, DataArrLength)

        DataMath_MaxMedianFilterSize = 18;

    if((DataArrLength < 1) || (DataArrLength > DataMath_MaxMedianFilterSize))
        ValArr = nan;
        return;
    end    
    ValArr = DataArr;    
    
    %//Сортировка вставками
    if (length(ValArr)~=1)
    for i = 1 : (DataArrLength - 1)
          MinIndex = i;
        for k = (i + 1):DataArrLength
            if(ValArr(k) < ValArr(MinIndex))
                MinIndex = k;
            end
        end
        
        if(MinIndex ~= i)
            %float TempVal;
            TempVal = ValArr(i);
            ValArr(i) = ValArr(MinIndex);
            ValArr(MinIndex) = TempVal;
        end
    end

    %//На выходе средняя точка отфильтрованного массива
    ValArr = ValArr( ((DataArrLength - 1) / 2)+1 );% мне кажется тут ошибка, проверка 1234456, без +1 выдает 3.
    end
        %ValArr=nan;
    return;
end