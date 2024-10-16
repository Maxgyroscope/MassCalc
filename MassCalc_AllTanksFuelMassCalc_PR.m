%/ \brief Вычисление масс топлива по бакам объекта
%/ \param[in] Pitch Тангаж
%/ \param[in] Roll Крен
%/ \return  Возвращаемое значение отсутствует
void MassCalc_AllTanksFuelMassCalc_PR(float Pitch, float Roll)
{
    %/ <b>Последовательность работы </b> 
    
    extern float TanksInfo_MaxRegArr[ TanksInfo_MaxRegArrSize ];
    
    %/ - Преобразование значения термосопротивлений в температуру @ref TranslateResToTemp
    TranslateResToTemp();

    %/ - Формирование суммарных значения емкостей ( помещаются в @ref CapacitySummArr ) @ref MakeSummCap
    MakeSummCap();

    %/ - Расчёт диэлектрической проницаемости топлива в баке (п.3.3) @ref MassCalc_DielPronCalcDHT1 , @ref MassCalc_DielPronCalcDHT2
    e_t_dht1 = MassCalc_DielPronCalcDHT1();
    e_t_dht2 = MassCalc_DielPronCalcDHT2();
    
    %/ - Перебор баков самолёта(цикл)
    for(uint8_t Tank = 0; Tank < TanksNum; Tank++)
    {
	MassDataStructDef WorkTemperature;%Текущее значение температуры топлива в баке
	MassDataStructDef WorkDensity;%Значение плотности расчитанное под текущую температуру

        %/ - (В цикле) Расчёт значения объёма топлива в баке по емкостям @ref MassCalc_FindVolume . 
        %/ Тут же происходит расчёт плотности топлива в баке и
        %/ температуры топлива в баке.
        MassDataStructDef Volume = MassCalc_FindVolume(Tank, Pitch, Roll, &WorkDensity, &WorkTemperature);
        
        %/ - (В цикле) Сохранение полученного объёма в @ref TankVolumeArr
        TankVolumeArr[Tank] = Volume;
        TankVolumeArr[Tank].Value *= TanksInfo_MaxRegArr[Tank];
        
        Volume.Value = Volume.Value * 0.001;%Перевод объёма в м3

        %/ - (В цикле) Сохранение полученной плотности в @ref TankDensityArr
        TankDensityArr[Tank] = WorkDensity;
        
	if(Volume.NoData)
	{
	    %Если данных по объёму нет считать массу бесполезно
	    TankMassArr[Tank].Value = 0;
	    TankMassArr[Tank].NoData = true;
	    TankMassArr[Tank].InvalidData = true;
	}
	else
	{
	    %/ - (В цикле) Пересчёт объёма и плотности в массу топлива в баке @ref VolumeToMassCalc
            TankMassArr[Tank] = VolumeToMassCalc(Tank, Volume, WorkDensity);
            LastMassArr[Tank][LastMassArrPointer] = TankMassArr[Tank].Value;
            TankMassArr[Tank].Value = MedianFiltr_GetValue(LastMassArr[Tank], LastMassArrSize);           
	}
    }

    LastMassArrPointer++;
    if(LastMassArrPointer >= LastMassArrSize)
        LastMassArrPointer = 0;
    
    %/ - Расчёт суммарной массы топлива
    SummFuelMass.Value = 0;
    SummFuelMass.NoData = false;
    SummFuelMass.InvalidData = false;

    for(uint8_t Tank = 0; Tank < TanksNum; Tank++)
    {
	SummFuelMass.Value += TankMassArr[Tank].Value;

	if((TankMassArr[Tank].InvalidData) || (TankMassArr[Tank].NoData))
	    SummFuelMass.InvalidData = true;
    }
}