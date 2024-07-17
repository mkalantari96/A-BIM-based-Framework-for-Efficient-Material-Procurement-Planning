
clear all
clc

t1=datetime('now');
global  OptScenarioNum NumScenario MaxQMat MinQMat WESTask WEFTask WLSTask WLFTask possiblefirstDay TQM lastIndexX Predecessors NumTask ESPC LDT Duration D NumMaterial UQ MatPro ProfSurArea  DDPC MDDP StockLength StockWidth StockHeight StockCost IR TFR OFR DPC MatCost B WCOST WSPACE
conn= database('DataBase','admin','admin');

%%Specify the number of "Zones" [NumTask] and the list of Predecessors for each Zone [Predecessors] and the Duration of each Zone [D(n)] from "tblZoneDetails"
query='select * from tblZoneDetails';
Data=fetch(conn,query);
NumTask=numel(Data.ID);
D=[];
WESTask=[];
WEFTask=[];
WLSTask=[];
WLFTask=[];
for n = 1:NumTask
    D(Data.ID(n))=Data.Duration(n);
    WESTask(Data.ID(n))=Data.WES(n);
    WEFTask(Data.ID(n))=Data.WEF(n);
    WLSTask(Data.ID(n))=Data.WLS(n);
    WLFTask(Data.ID(n))=Data.WLF(n);
end

Predecessors=[];
for r =1:NumTask
    n = Data.ID(r);
    temp=table2array(Data.Predecessors(r));
    if numel(temp)==0
         Predecessors{n}{1}="Nothing";
    else
        temp_data=textscan(temp,'%s','Delimiter',',');
        for i =1:numel(temp_data{1})
            temp=char(temp_data{1}{i});
            len=numel(temp);
            PreDone=0;
            for ii =1:len
                if temp(ii)=="+"
                    TaskID=temp(1:ii-3);
                    rel=[temp(ii-2),temp(ii-1)];
                    lag=temp(ii+1:end);
                    Predecessors{n}{i}=[TaskID];
                    Predecessors{n}{i}=[Predecessors{n}{i}+","+ rel];
                    Predecessors{n}{i}=[Predecessors{n}{i}+","+ lag];
                    PreDone=1;
                    break
                end
            end
            if PreDone==0
                TaskID=temp(1:len-2);
                rel=[temp(len-1),temp(len)];
                lag=0;
                Predecessors{n}{i}=[TaskID];
                Predecessors{n}{i}=[Predecessors{n}{i}+","+ rel];
                Predecessors{n}{i}=[Predecessors{n}{i}+","+ lag];
            end
%         celldisp(Predecessors)    
        end
           
            
    end
end
%celldisp(Predecessors) 


%%Determine elements in each zone [ElementInZone] from "ElementInZone"
ElementInZone=[];
for i = 1:NumTask
    ElementInZone{i}=[];
end
query='select * from ElementInZone';
Data=fetch(conn,query);
tbElInZoneRow = numel(Data.IDZone);
for i = 1:tbElInZoneRow
    ElementInZone{Data.IDZone(i)}=[ElementInZone{Data.IDZone(i)} string(Data.LineNumber(i))];
end


%%Specify the Land Delivery, ES, Delivery date of project with and without penalty and etc from "tblProjectDetails"
query='select * from tblProjectDetails';
Data=fetch(conn,query);
LDT=datetime(Data.LandDeliveryTime);
ESPC=datetime(Data.EarliestStartofProjectConstruction);
DDPC=datetime(Data.DeliveryDateofProjectWithoutPenalty);
MDDP=datetime(Data.MaxDeliveryDateofProject);
temp_Duration = string(days(days(MDDP-LDT)+1));
temp=textscan(temp_Duration,'%f');
Duration = double(temp{1});
IR=double(string(Data.DailyInterestRate));
TFR=double(string(Data.DailyTransportationTnflationRate(1)));
OFR=double(string(Data.DailyOverallInflationRate));
DPC=double(string(Data.DelayedPenaltyCost));


%%Specify Material data [MatPro] from "tblMaterialData"
MatPro=[];
query='select * from tblMaterialData';
Data=fetch(conn,query);
NumMaterial=numel(Data.ID);
for n = 1:NumMaterial
    MatPro{Data.ID(n)}{1}=Data.ID(n);
    MatPro{Data.ID(n)}{2}=table2array(Data.MaterialName(n));
    MatPro{Data.ID(n)}{3}=Data.InitialInventory(n);
    MatPro{Data.ID(n)}{4}=Data.DeliveryPeriods(n);
    MatPro{Data.ID(n)}{5}=Data.InstallmentPeriod(n);
    MatPro{Data.ID(n)}{6}=Data.DailyInflationRate(n);
    MatPro{Data.ID(n)}{7}=Data.MaintenanceCost(n);
    MatPro{Data.ID(n)}{8}=table2array(Data.ProfileName(n));
    MatPro{Data.ID(n)}{9}=Data.SpecificWeight(n);
    MatPro{Data.ID(n)}{10}=Data.WidthOfOneUnit(n);
    MatPro{Data.ID(n)}{11}=Data.HeightOfOneUnit(n);
    MatPro{Data.ID(n)}{12}=Data.LengthOfOneUnit(n);
    
end

%%Specify data of buying cost, delivery cost and etc from "tblMaterialUnitCost"
MatCost=[];
query='select * from tblMaterialUnitCost';
Data=fetch(conn,query);
tbMAtCostRow = numel(Data.IDofMaterial);
MaxQMat=[];
for n = 1:NumMaterial
    i = 0;
    for row = 1:tbMAtCostRow
        if Data.IDofMaterial(row) == n
           i = i + 1;
           MatCost{n}{i}{1} = Data.MinOrderQuantity(row);
           MatCost{n}{i}{2} = Data.MaxOrderQuantity(row);
           MatCost{n}{i}{3} = Data.CostperUnitInCashPurchase(row);
           MatCost{n}{i}{4} = Data.CostperUnitInInstallmentPurchase(row);
           MatCost{n}{i}{5} = Data.PayRateT0(row);
           MatCost{n}{i}{6} = Data.PayRateT0plusDelta(row);
           MatCost{n}{i}{7} = Data.DeliveryCost(row);
        end
    end
    for ii = 1:i
        if ii==1
            MinQMat{n} =  MatCost{n}{ii}{1};
            MaxQMat{n} =  MatCost{n}{ii}{1};
        end
        if MatCost{n}{ii}{1} < MinQMat{n}
            MinQMat{n}=MatCost{n}{ii}{1};
        end
        if MatCost{n}{ii}{2}> MaxQMat{n}
             MaxQMat{n}=MatCost{n}{ii}{2};
        end
    end
            
end


%%Specify Daily Material requirments of each zone [] from "QTOforZones"
%fingilsh: etelat dar yek matrix ba radife barabar ba NumMaterial va sotone barabar ba NumTask
UQ=zeros(NumMaterial,NumTask);
query='select * from QTOforZones';
Data=fetch(conn,query);
RowQTO=numel(Data.IDZone);
for i = 1:RowQTO
    UQ(Data.IDMaterial(i),Data.IDZone(i))= Data.DailyVolumeConsumption(i);
end



%%Specify Financial data such az input value and the date of that from "tblInputCash"
query='select * from tblInputCash';
Data=fetch(conn,query);
RowInputCash=numel(Data.Number);
B=zeros(1,Duration);
for i = 1:RowInputCash
    if datetime(Data.Date(i)) == LDT
        temp_T=1;
    else
        Temp_Date = string(days(datetime(Data.Date(i)) - LDT));
        temp=textscan(Temp_Date,'%f');
        temp_T =  double(temp{1}); 
    end

    B(temp_T) =Data.InputCash(i);
end
%%specify Storage Dim for each scenario from "tblStorageDimension"
query='select * from tblStorageDimension';
Data=fetch(conn,query);
NumScenario=max(Data.Scenario);
RowStorageTbl=numel(Data.Scenario);
StockLength =[];
StockWidth =[];
StockHeight =[];
StockCost =[];
for i = 1:RowStorageTbl
    StockLength{Data.Scenario(i)}{Data.IDMaterial(i)}=Data.Length(i);
    StockWidth{Data.Scenario(i)}{Data.IDMaterial(i)}=Data.Width(i);
    StockHeight{Data.Scenario(i)}{Data.IDMaterial(i)}=Data.MaxHeight(i);
    StockCost{Data.Scenario(i)}{Data.IDMaterial(i)}=Data.SettingUpCost(i);
end

%%%Determine the Surface area of each profile from "totalQTO"
query='select * from totalQTO';
Data=fetch(conn,query);
RowTQTO=numel(Data.IDMaterial);
ProfSurArea=[];
for r = 1:RowTQTO
    if MatPro{r}{8}(1:2)=="PL"
        lenNamePro=numel(MatPro{r}{8});
        th=str2double(MatPro{r}{8}(3:lenNamePro));
        ProfSurArea(Data.IDMaterial(r))= th*MatPro{r}{10}/1000;
    else
        ProfSurArea(Data.IDMaterial(r))= Data.SurfaceArea(r);
    end
end

query='select * from QTOforZones';
Data=fetch(conn,query);
RowQTO=numel(Data.IDZone);
TQM=zeros(1,NumMaterial);
for i = 1:RowQTO
    TQM(Data.IDMaterial(i))= TQM(Data.IDMaterial(i))+ Data.TotalVolumeConsumption(i);
end

close(conn);


lastIndexX=NumTask + ((2*NumMaterial +2 - 2)*Duration);


nvars=lastIndexX;

LB = [];   % Lower bound
UB = [];   % Upper bound

temp_firstday = string(days(days(ESPC-LDT)+1));
temp=textscan(temp_firstday,'%f');
possiblefirstDay = double(temp{1});
LB = [LB possiblefirstDay];
UB = [UB 20];
for n = 2:NumTask
   LB=[LB possiblefirstDay];
   UB=[UB Duration-D(n)+1];
end


for m = 1:NumMaterial
    for p = 1:2
        for t = 1:Duration
            LB = [LB MinQMat{m}]; 
            UB = [UB min(MaxQMat{m},TQM(m)*MatPro{m}{9})];
        end
    end
end

%rayat sharte kharid ghesti
for m = 1:NumMaterial
    p=2;
    for t = Duration-MatPro{m}{5}+2:Duration
        UB(NumTask + (((2*m)+p-3)*(Duration))+t)=0;
        LB(NumTask + (((2*m)+p-3)*(Duration))+t)=0;
    end
    
end

IntegerX = [];
for i = 1:nvars
    IntegerX=[IntegerX i];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%


%options = optimoptions('ga','PlotFcn','gaplotbestf');
options = optimoptions('ga');
%options = optimoptions(options,'MaxStallGenerations',10000,'MaxGenerations',1000000,'PopulationSize',6700);

bestXScen=[];
BestCostScen=[];

%options = optimoptions(options,'InitialPopulation',InitialPop,'PopulationSize',5*InitialPopulationSize);

% for OptScenarioNum = 1:NumScenario
for iii = 1:2
    OptScenarioNum= iii;
    bestX=[];
    BestCost=[];
    initialPopulationJTT=[];
    initialPopulationJTT=[initialPopulationJTT; CreateInitialPop2(20,OptScenarioNum,200)];
    for repeat = 1:20
        X=[];
        X=initialPopulationJTT(repeat,:);
        CostPart1 = Function(X);

        if repeat == 1 
            BestCost=CostPart1;
            bestX=X;
            initial_set=1;
        end
        
        if BestCost > CostPart1
            BestCost=CostPart1;
            bestX=X;
        end
    end

    BestCostScen{OptScenarioNum}=BestCost
    bestXScen{OptScenarioNum}=bestX;

end


function [InitialPop]=CreateInitialPop2(iteration,OptScenarioNum,StepT)

global WESTask WEFTask WLSTask WLFTask possiblefirstDay Predecessors NumTask LDT Duration D NumMaterial UQ MatPro ProfSurArea DDPC StockLength StockWidth StockHeight IR TFR DPC MatCost B

InitialPop=[];
firstdayofconstruct=possiblefirstDay;

for i = 1:iteration
    
    randchoice = rand;
    if randchoice<0.3
        randparamet = 0;
    elseif (randchoice >= 0.3) && (randchoice<0.6)
        randparamet = randchoice;
    else
        randparamet = 1;
    end
    InitialPoint=[];
    
    tempBQ1=zeros(NumMaterial,Duration);
    tempBQ2=zeros(NumMaterial,Duration);
    InitialMRP = zeros(NumMaterial,Duration);
    tempdeliveryDay =[];
    for m = 1:NumMaterial
        tempdeliveryDay = [tempdeliveryDay ;MatPro{m}{4}];
    end
    AreaNeed=zeros(NumMaterial,3);
    priZoneNotFound=0;
    for n=1:NumTask
        if Predecessors{n}{1}=="Nothing"
            TempStart=[firstdayofconstruct,max(tempdeliveryDay)];
            if isnan(WESTask(n))==0
                TempStart = [TempStart ;WESTask(n)];
            end
            if isnan(WEFTask(n))==0
                TempStart=[TempStart ;WEFTask(n)-D(n)-1];
            end
                
            InitialPoint(n)=max(TempStart);
            if isnan(WLSTask(n))==0
                if InitialPoint(n)>WLSTask(n)
                    InitialPoint(n)= WLSTask(n);
                end
            end
            if isnan(WLFTask(n))==0
                if InitialPoint(n)>WLFTask(n)-D(n)-1
                    InitialPoint(n)= WLFTask(n)-D(n)-1;
                end
            end
                
            
            jobdone=0;
            pri_MRP=InitialMRP;
            if priZoneNotFound==1
                jobdone =1;
            end
            TryNumber = 0;
            while jobdone==0
                dayOk=0;
                if (InitialPoint(n)+D(n)-1<=Duration) && (TryNumber<=Duration)
                    for t = InitialPoint(n):InitialPoint(n)+D(n)-1
                        for m = 1:NumMaterial
                           InitialMRP(m,t) = pri_MRP(m,t) + UQ(m,n);
                        end
                    end
                    stockdone = 0;
                    for m = 1:NumMaterial
                        TotalLen=0;
                        SpaceNeed=0;
                        MaxNumRow=0;
                        h_space=0;
                        AreaNeedforMat=0;
                        MatUnitNum=0;
                        if max(InitialMRP(m,:))==0
                            AreaNeedforMat=0;
                            l_space=0;
                            w_space =0;
                        elseif MatPro{m}{8} == "NoProfile"
                            %%%baraye ajor o siman o kashi!
                            %%%%bayad kar beshe
                            SpaceNeed=max(InitialMRP(m,:));
                            MatUnitNum = ceil(SpaceNeed/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10}));
                            MaxNumRow=floor(StockHeight{OptScenarioNum}{m}/MatPro{m}{11});
                            if MatUnitNum*MatPro{m}{11}>StockHeight{OptScenarioNum}{m}
                                h_space=MaxNumRow*MatPro{m}{11};
                            else
                                h_space=MatUnitNum*MatPro{m}{11};
                            end
                            l_space = MatPro{m}{12};
                            WidthNeedforSpace =MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
                            if WidthNeedforSpace>StockWidth{OptScenarioNum}{m}
                                w_space = MatPro{m}{10}*floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{10});
                                UnitArrangeDone = (h_space * w_space * l_space)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                UnitNeedtArrange = MatUnitNum - UnitArrangeDone ;
                                SpaceNeedforRest = UnitNeedtArrange*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m})
                                    NumLenAvaInWidth =  floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{12});
                                else
                                    NumLenAvaInWidth =1;
                                end
                                if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                                    h_space_rest=MaxNumRow*MatPro{m}{11}; 
                                else
                                    h_space_rest=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                                end
                                AreaNeedforRest = SpaceNeedforRest/h_space_rest;
                                LengthNeedforRest = AreaNeedforRest/w_space;

                                if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest<=MatPro{m}{12})
                                    ExtraLengthNeed =MatPro{m}{10}*ceil(SpaceNeedforRest/(h_space_rest*w_space)/MatPro{m}{10});
                                    l_space = l_space + ExtraLengthNeed;

                                elseif (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                                    Extralen_1 =  MatPro{m}{12} * floor(LengthNeedforRest/MatPro{m}{12});
                                    UnitDoneinExtra1 = (h_space * w_space * Extralen_1)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                    RestUnit = UnitNeedtArrange - UnitDoneinExtra1;
                                    SpaceNeedRestUnit2 = RestUnit*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                    if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                                        h_space_rest2=MaxNumRow*MatPro{m}{11}; 
                                    else
                                        h_space_rest2=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                                    end

                                    Extralen_2 = MatPro{m}{10}*ceil(SpaceNeedRestUnit2/(h_space_rest2*w_space)/MatPro{m}{10});
                                    l_space = l_space +  Extralen_1 + Extralen_2  ;
                                elseif (MatPro{m}{12}> StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                                    ExtraLengthNeed = MatPro{m}{12}* ceil(LengthNeedforRest/MatPro{m}{12});
                                    l_space = l_space + ExtraLengthNeed;   
                                end

                            else
                                temp_w_space = MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
                                if temp_w_space + 2 > StockWidth{OptScenarioNum}{m}
                                    w_space = StockWidth{OptScenarioNum}{m};
                                else
                                    w_space = temp_w_space;
                                end
                                l_space = MatPro{m}{12};
                            end
                            AreaNeedforMat=l_space * w_space;


                        elseif MatPro{m}{8}(1:2) ~= "PL"
                            TotalLen=max(InitialMRP(m,:))/ProfSurArea(m);
                            MatUnitNum = ceil(TotalLen/MatPro{m}{12});
                            SpaceNeed= MatUnitNum*MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10};
                            MaxNumRow=floor(StockHeight{OptScenarioNum}{m}/MatPro{m}{11});
                            if MatUnitNum*MatPro{m}{11}>StockHeight{OptScenarioNum}{m}
                                h_space=MaxNumRow*MatPro{m}{11};
                            else
                                h_space=MatUnitNum*MatPro{m}{11};
                            end
                            l_space = MatPro{m}{12};
                            WidthNeedforSpace =MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
                            if WidthNeedforSpace>StockWidth{OptScenarioNum}{m}
                                w_space = MatPro{m}{10}*floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{10});
                                UnitArrangeDone = (h_space * w_space * l_space)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                UnitNeedtArrange = MatUnitNum - UnitArrangeDone ;
                                SpaceNeedforRest = UnitNeedtArrange*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m})
                                    NumLenAvaInWidth =  floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{12});
                                else
                                    NumLenAvaInWidth =1;
                                end
                                if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                                    h_space_rest=MaxNumRow*MatPro{m}{11}; 
                                else
                                    h_space_rest=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                                end
                                AreaNeedforRest = SpaceNeedforRest/h_space_rest;
                                LengthNeedforRest = AreaNeedforRest/w_space;

                                if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest<=MatPro{m}{12})
                                    ExtraLengthNeed =MatPro{m}{10}*ceil(SpaceNeedforRest/(h_space_rest*w_space)/MatPro{m}{10});
                                    l_space = l_space + ExtraLengthNeed ;

                                elseif (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                                    Extralen_1 =  MatPro{m}{12} * floor(LengthNeedforRest/MatPro{m}{12});
                                    UnitDoneinExtra1 = (h_space * w_space * Extralen_1)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                    RestUnit = UnitNeedtArrange - UnitDoneinExtra1;
                                    SpaceNeedRestUnit2 = RestUnit*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                    if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                                        h_space_rest2=MaxNumRow*MatPro{m}{11}; 
                                    else
                                        h_space_rest2=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                                    end

                                    Extralen_2 = MatPro{m}{10}*ceil(SpaceNeedRestUnit2/(h_space_rest2*w_space)/MatPro{m}{10});
                                    l_space = l_space +  Extralen_1 + Extralen_2 ;
                                elseif (MatPro{m}{12}> StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                                    ExtraLengthNeed = MatPro{m}{12}* ceil(LengthNeedforRest/MatPro{m}{12});
                                    l_space = l_space + ExtraLengthNeed ;   
                                end

                            else
                                temp_w_space = MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
                                if temp_w_space + 2 > StockWidth{OptScenarioNum}{m}
                                    w_space = StockWidth{OptScenarioNum}{m};
                                else
                                    w_space = temp_w_space;
                                end
                                l_space = MatPro{m}{12};
                            end
                            AreaNeedforMat=l_space * w_space;


                        elseif MatPro{m}{8}(1:2) == "PL"
                            SpaceNeed=max(InitialMRP(m,:));
                            MatUnitNum = ceil(SpaceNeed/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10}));
                            MaxNumRow=floor(StockHeight{OptScenarioNum}{m}/MatPro{m}{11});
                            if MatUnitNum*MatPro{m}{11}>StockHeight{OptScenarioNum}{m}
                                h_space=MaxNumRow*MatPro{m}{11};
                            else
                                h_space=MatUnitNum*MatPro{m}{11};
                            end
                            l_space = MatPro{m}{12};
                            WidthNeedforSpace =MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space * MatPro{m}{10}));
                            if WidthNeedforSpace>StockWidth{OptScenarioNum}{m}
                                w_space = MatPro{m}{10}*floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{10});
                                UnitArrangeDone = (h_space * w_space * l_space)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                UnitNeedtArrange = MatUnitNum - UnitArrangeDone ;
                                SpaceNeedforRest = UnitNeedtArrange*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m})
                                    NumLenAvaInWidth =  floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{12});
                                else
                                    NumLenAvaInWidth =1;
                                end
                                if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                                    h_space_rest=MaxNumRow*MatPro{m}{11}; 
                                else
                                    h_space_rest=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                                end
                                AreaNeedforRest = SpaceNeedforRest/h_space_rest;
                                LengthNeedforRest = AreaNeedforRest/w_space;

                                if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest<=MatPro{m}{12})
                                    ExtraLengthNeed =MatPro{m}{10}*ceil(SpaceNeedforRest/(h_space_rest*w_space)/MatPro{m}{10});
                                    l_space = l_space + ExtraLengthNeed;

                                elseif (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                                    Extralen_1 =  MatPro{m}{12} * floor(LengthNeedforRest/MatPro{m}{12});
                                    UnitDoneinExtra1 = (h_space * w_space * Extralen_1)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                    RestUnit = UnitNeedtArrange - UnitDoneinExtra1;
                                    SpaceNeedRestUnit2 = RestUnit*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                    if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                                        h_space_rest2=MaxNumRow*MatPro{m}{11}; 
                                    else
                                        h_space_rest2=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                                    end

                                    Extralen_2 = MatPro{m}{10}*ceil(SpaceNeedRestUnit2/(h_space_rest2*w_space)/MatPro{m}{10});
                                    l_space = l_space +  Extralen_1 + Extralen_2;
                                elseif (MatPro{m}{12}> StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                                    ExtraLengthNeed = MatPro{m}{12}* ceil(LengthNeedforRest/MatPro{m}{12});
                                    l_space = l_space + ExtraLengthNeed;   
                                end

                            else
                                temp_w_space = MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
                                if temp_w_space + 2 > StockWidth{OptScenarioNum}{m}
                                    w_space = StockWidth{OptScenarioNum}{m};
                                else
                                    w_space = temp_w_space;
                                end
                                l_space = MatPro{m}{12};

                            end
                            AreaNeedforMat=l_space * w_space;
                        end
                        AreaNeed(m,1) = l_space;
                        AreaNeed(m,2) = w_space;
                        AreaNeed(m,3) = AreaNeedforMat;
                        if (AreaNeed(m,1)<=StockLength{OptScenarioNum}{m}) && (AreaNeed(m,2)<=StockWidth{OptScenarioNum}{m})
                            stockdone=stockdone+1;
                        end
                    end
                    
                    
                    
                    if stockdone == NumMaterial 
                        dayOk=D(n);
                    else
                        InitialPoint(n)=InitialPoint(n)+1; 
                    end
                end
                
                if (dayOk ==D(n)) && (TryNumber<Duration)
                    
                    for m=1:NumMaterial
                        
                        for t=1:StepT:Duration
                            if t+MatPro{m}{4}<Duration
                                if t+MatPro{m}{4}+StepT-1<Duration
                                    if t+MatPro{m}{5}<Duration
                                        tempBQ1(m,t)= ceil(sum(InitialMRP(m,t+MatPro{m}{4}:t+MatPro{m}{4}+StepT-1))*MatPro{m}{9}*randparamet);
                                        tempBQ2(m,t)= ceil(sum(InitialMRP(m,t+MatPro{m}{4}:t+MatPro{m}{4}+StepT-1))*MatPro{m}{9}*(1-randparamet));
                                    else
                                        tempBQ1(m,t)=  ceil(sum(InitialMRP(m,t+MatPro{m}{4}:t+MatPro{m}{4}+StepT-1))*MatPro{m}{9});
                                        tempBQ2(m,t)= 0;
                                    end
                                else
                                    if t+MatPro{m}{5}<Duration
                                        tempBQ1(m,t)=  ceil(sum(InitialMRP(m,t+MatPro{m}{4}:Duration))*MatPro{m}{9}*randparamet);
                                        tempBQ2(m,t)=  ceil(sum(InitialMRP(m,t+MatPro{m}{4}:Duration))*MatPro{m}{9}*(1-randparamet));
                                    else
                                        tempBQ1(m,t)=  ceil(sum(InitialMRP(m,t+MatPro{m}{4}:Duration))*MatPro{m}{9});
                                        tempBQ2(m,t)= 0;
                                    end
                                    
                                end
                            else 
                                tempBQ1(m,t)= 0;
                                tempBQ2(m,t)=0;
                            end
                        end
                    end
                    
                    tempDQ=zeros(NumMaterial,Duration);
                    for t = 1:Duration
                        for m = 1:NumMaterial
                            if t-MatPro{m}{4}>=0
                                tempDQ(m,t)= tempDQ(m,t) + tempBQ1(m,t-MatPro{m}{4}+1)+tempBQ2(m,t-MatPro{m}{4}+1); 
                            end
                        end
                    end
                    tempOC=zeros(NumMaterial,Duration);
                    for t =1:Duration
                        for m = 1:NumMaterial
                            UnitPriceP1 = 0;
                            UnitPriceP21 = 0;
                            UnitPriceP22 = 0;
                            RateAtT0 = 0;
                            RateAtDelta = 0;
                            for i = 1:numel(MatCost{m})
                                if (MatCost{m}{i}{1} <= tempBQ1(m,t)) && (MatCost{m}{i}{2} >= tempBQ1(m,t))
                                    UnitPriceP1 = MatCost{m}{i}{3}; 
                                end
                                if (MatCost{m}{i}{1} <= tempBQ2(m,t)) && (MatCost{m}{i}{2} >= tempBQ2(m,t))
                                    UnitPriceP21 = MatCost{m}{i}{4}; 
                                    RateAtT0 = MatCost{m}{i}{5};
                                end
                                if ((t - MatPro{m}{5}) > 0) && (MatCost{m}{i}{1} <= tempBQ2(m,t- MatPro{m}{4})) && (MatCost{m}{i}{2} >= tempBQ2(m,t- MatPro{m}{5}))
                                    UnitPriceP22 = MatCost{m}{i}{4}; 
                                    RateAtDelta = MatCost{m}{i}{6};
                                end
                            end

                            if (t - MatPro{m}{5}) > 0
                                tempOC(m,t)=(tempBQ2(m,t)* UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(Duration-t))) + (tempBQ2(m,t- MatPro{m}{5})  * UnitPriceP22 * RateAtDelta * ((1+MatPro{m}{6})^(Duration-t+MatPro{m}{5}))) + (tempBQ1(m,t)  * UnitPriceP1 * ((1+MatPro{m}{6})^(Duration-t)));
                            else
                                tempOC(m,t)=(tempBQ2(m,t)* UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(Duration-t))) + (tempBQ1(m,t)  * UnitPriceP1 * ((1+MatPro{m}{6})^(Duration-t))); 
                            end

                        end
                    end

                    %part2:hazine haml

                    tempDC=zeros(NumMaterial,Duration);
                    for t =1:Duration
                        for m = 1:NumMaterial
                            if tempDQ(m,t) ~=0
                                DeliveryCost = 0;
                                for i = 1:numel( MatCost{m})
                                    if (MatCost{m}{i}{1} <= tempDQ(m,t)) && (MatCost{m}{i}{2} >= tempDQ(m,t))
                                        DeliveryCost = MatCost{m}{i}{7};  
                                    end
                                end
                                tempDC(m,t)= DeliveryCost * ((1+TFR)^(t));
                            end
                        end
                    end
                    %part3:hazine negahdari
                    tempSC=zeros(NumMaterial,Duration);
                    %part4:hazine takhir
                    if n == NumTask
                        if (InitialPoint(NumTask)+D(NumTask)) >(days(DDPC-LDT)+1)
                            temp_dif_T = string(InitialPoint(NumTask)+D(NumTask) - (days(DDPC-LDT)+1));
                            temp=textscan(temp_dif_T,'%f');
                            Diff = double(temp{1});
                            tempDFP = Diff * DPC;
                        else
                            tempDFP=0;
                        end
                    else
                        tempDFP=0;
                    end

                    tempFI=[];
                    for t =1:Duration
                        Temp_total_cost_t = 0;
                        for m = 1:NumMaterial
                            Temp_total_cost_t = Temp_total_cost_t + tempOC(m,t) + tempDC(m,t) + tempSC(m,t);
                        end
                        if t == 1
                            tempFI(t) = B(t) - Temp_total_cost_t;
                        elseif t == Duration
                            tempFI(t) = (tempFI(t-1)*(1+IR)) + B(t) - Temp_total_cost_t - tempDFP;
                        else
                            tempFI(t) = (tempFI(t-1)*(1+IR)) + B(t) - Temp_total_cost_t;
                        end
                    end


                    if (min(tempFI)<0) && (InitialPoint(n)+1<=Duration-D(n)+1)
                        if (isnan(WLSTask(n))==0) && (InitialPoint(n)<=WLSTask(n))
                            InitialPoint(n) = InitialPoint(n)+1;
                        elseif isnan(WLSTask(n))==1
                            InitialPoint(n) = InitialPoint(n)+1;
                        elseif (isnan(WLSTask(n))==0) && (InitialPoint(n)>WLSTask(n))
                            InitialPoint=[];
                            jobdone =1;

                        elseif (isnan(WLFTask(n))==0) && (InitialPoint(n)+D(n)-1<=WLFTask(n))
                            InitialPoint(n) = InitialPoint(n)+1;
                        elseif isnan(WLFTask(n))==1
                            InitialPoint(n) = InitialPoint(n)+1;
                        elseif (isnan(WLFTask(n))==0) && (InitialPoint(n)+D(n)-1>WLFTask(n))
                            InitialPoint=[];
                            jobdone =1;
                        end

                    elseif (min(tempFI)>=0) && (InitialPoint(n)<=Duration-D(n)+1)
                        if (isnan(WLSTask(n))==0) && (InitialPoint(n)<=WLSTask(n)) 
                            jobdone=1;
                        elseif isnan(WLSTask(n))==1
                            jobdone=1;
                        elseif (isnan(WLSTask(n))==0) && (InitialPoint(n)>WLSTask(n))
                            InitialPoint=[];
                            jobdone =1;
                        elseif (isnan(WLFTask(n))==0) && (InitialPoint(n)+D(n)-1<=WLFTask(n))
                            jobdone=1;    
                        elseif isnan(WLFTask(n))==1
                            jobdone=1; 
                        elseif (isnan(WLFTask(n))==0) && (InitialPoint(n)+D(n)-1>WLFTask(n))
                            InitialPoint=[];
                            jobdone =1;
                        end
                    else
                        InitialPoint=[];
                        priZoneNotFound=1;
                        jobdone =1;
                    end

                elseif TryNumber > Duration
                    InitialPoint=[];
                    priZoneNotFound=1;
                    jobdone =1;
                    
                else
                    TryNumber=TryNumber+1;
                end
            end

        else
            if priZoneNotFound==1
                jobdone =1;
            else
                TempStart=[firstdayofconstruct];
                if isnan(WESTask(n))==0
                    TempStart = [TempStart ;WESTask(n)];
                end
                if isnan(WEFTask(n))==0
                    TempStart=[TempStart ;WEFTask(n)-D(n)-1];
                end
                
                

                for p=1:numel(Predecessors{n})
                    temp=textscan(Predecessors{n}{p},'%s','Delimiter',',');
                    taskID=str2double((temp{1}{1}));
                    rel=temp{1}{2};
                    lag=str2double(temp{1}{3});
                    if rel=="FS"
                        TempStart = [TempStart ;InitialPoint(taskID)+D(taskID)-1+lag] ;
                    elseif rel=="SS"
                        TempStart = [TempStart ;InitialPoint(taskID)+lag] ;
                    elseif rel=="FF"
                        TempStart = [TempStart ;InitialPoint(taskID)+lag- D(n)+1] ;
                    elseif rel=="SF"
                        TempStart = [TempStart ;InitialPoint(taskID)- D(n)+1] ;    
                    end
                end
                InitialPoint(n)=max(TempStart);
                
                if isnan(WLSTask(n))==0
                    if InitialPoint(n)>WLSTask(n)
                        InitialPoint(n)= WLSTask(n);
                    end
                end
                if isnan(WLFTask(n))==0
                    if InitialPoint(n)>WLFTask(n)-D(n)-1
                        InitialPoint(n)= WLFTask(n)-D(n)-1;
                    end
                end
            
                jobdone=0; 
            end
           
            pri_MRP=InitialMRP;
            TryNumber=0;
            while jobdone==0
                dayOk=0;
                if (InitialPoint(n)+D(n)-1<=Duration) && (TryNumber<=Duration)
                   
                    for t = InitialPoint(n):InitialPoint(n)+D(n)-1
                        for m = 1:NumMaterial
                           InitialMRP(m,t) = pri_MRP(m,t) + UQ(m,n);
                        end
                    end
                    stockdone = 0 ;
                    for m = 1:NumMaterial
                        TotalLen=0;
                        SpaceNeed=0;
                        MaxNumRow=0;
                        h_space=0;
                        AreaNeedforMat=0;
                        MatUnitNum=0;
                        if max(InitialMRP(m,:))==0
                            AreaNeedforMat=0;
                            l_space=0;
                            w_space =0;
                        elseif MatPro{m}{8}== "NoProfile"
                            %%%baraye ajor o siman o kashi!
                            %%%%bayad kar beshe
                            SpaceNeed=max(InitialMRP(m,:));
                            MatUnitNum = ceil(SpaceNeed/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10}));
                            MaxNumRow=floor(StockHeight{OptScenarioNum}{m}/MatPro{m}{11});
                            if MatUnitNum*MatPro{m}{11}>StockHeight{OptScenarioNum}{m}
                                h_space=MaxNumRow*MatPro{m}{11};
                            else
                                h_space=MatUnitNum*MatPro{m}{11};
                            end
                            l_space = MatPro{m}{12};
                            WidthNeedforSpace =MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
                            if WidthNeedforSpace>StockWidth{OptScenarioNum}{m}
                                w_space = MatPro{m}{10}*floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{10});
                                UnitArrangeDone = (h_space * w_space * l_space)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                UnitNeedtArrange = MatUnitNum - UnitArrangeDone ;
                                SpaceNeedforRest = UnitNeedtArrange*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m})
                                    NumLenAvaInWidth =  floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{12});
                                else
                                    NumLenAvaInWidth =1;
                                end
                                if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                                    h_space_rest=MaxNumRow*MatPro{m}{11}; 
                                else
                                    h_space_rest=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                                end
                                AreaNeedforRest = SpaceNeedforRest/h_space_rest;
                                LengthNeedforRest = AreaNeedforRest/w_space;

                                if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest<=MatPro{m}{12})
                                    ExtraLengthNeed =MatPro{m}{10}*ceil(SpaceNeedforRest/(h_space_rest*w_space)/MatPro{m}{10});
                                    l_space = l_space + ExtraLengthNeed;

                                elseif (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                                    Extralen_1 =  MatPro{m}{12} * floor(LengthNeedforRest/MatPro{m}{12});
                                    UnitDoneinExtra1 = (h_space * w_space * Extralen_1)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                    RestUnit = UnitNeedtArrange - UnitDoneinExtra1;
                                    SpaceNeedRestUnit2 = RestUnit*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                    if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                                        h_space_rest2=MaxNumRow*MatPro{m}{11}; 
                                    else
                                        h_space_rest2=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                                    end

                                    Extralen_2 = MatPro{m}{10}*ceil(SpaceNeedRestUnit2/(h_space_rest2*w_space)/MatPro{m}{10});
                                    l_space = l_space +  Extralen_1 + Extralen_2  ;
                                elseif (MatPro{m}{12}> StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                                    ExtraLengthNeed = MatPro{m}{12}* ceil(LengthNeedforRest/MatPro{m}{12});
                                    l_space = l_space + ExtraLengthNeed;   
                                end

                            else
                                temp_w_space = MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
                                if temp_w_space + 2 > StockWidth{OptScenarioNum}{m}
                                    w_space = StockWidth{OptScenarioNum}{m};
                                else
                                    w_space = temp_w_space;
                                end
                                l_space = MatPro{m}{12};
                            end
                            AreaNeedforMat=l_space * w_space;


                        elseif MatPro{m}{8}(1:2) ~= "PL"
                            TotalLen=max(InitialMRP(m,:))/ProfSurArea(m);
                            MatUnitNum = ceil(TotalLen/MatPro{m}{12});
                            SpaceNeed= MatUnitNum*MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10};
                            MaxNumRow=floor(StockHeight{OptScenarioNum}{m}/MatPro{m}{11});
                            if MatUnitNum*MatPro{m}{11}>StockHeight{OptScenarioNum}{m}
                                h_space=MaxNumRow*MatPro{m}{11};
                            else
                                h_space=MatUnitNum*MatPro{m}{11};
                            end
                            l_space = MatPro{m}{12};
                            WidthNeedforSpace =MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
                            if WidthNeedforSpace>StockWidth{OptScenarioNum}{m}
                                w_space = MatPro{m}{10}*floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{10});
                                UnitArrangeDone = (h_space * w_space * l_space)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                UnitNeedtArrange = MatUnitNum - UnitArrangeDone ;
                                SpaceNeedforRest = UnitNeedtArrange*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m})
                                    NumLenAvaInWidth =  floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{12});
                                else
                                    NumLenAvaInWidth =1;
                                end
                                if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                                    h_space_rest=MaxNumRow*MatPro{m}{11}; 
                                else
                                    h_space_rest=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                                end
                                AreaNeedforRest = SpaceNeedforRest/h_space_rest;
                                LengthNeedforRest = AreaNeedforRest/w_space;

                                if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest<=MatPro{m}{12})
                                    ExtraLengthNeed =MatPro{m}{10}*ceil(SpaceNeedforRest/(h_space_rest*w_space)/MatPro{m}{10});
                                    l_space = l_space + ExtraLengthNeed ;

                                elseif (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                                    Extralen_1 =  MatPro{m}{12} * floor(LengthNeedforRest/MatPro{m}{12});
                                    UnitDoneinExtra1 = (h_space * w_space * Extralen_1)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                    RestUnit = UnitNeedtArrange - UnitDoneinExtra1;
                                    SpaceNeedRestUnit2 = RestUnit*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                    if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                                        h_space_rest2=MaxNumRow*MatPro{m}{11}; 
                                    else
                                        h_space_rest2=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                                    end

                                    Extralen_2 = MatPro{m}{10}*ceil(SpaceNeedRestUnit2/(h_space_rest2*w_space)/MatPro{m}{10});
                                    l_space = l_space +  Extralen_1 + Extralen_2 ;
                                elseif (MatPro{m}{12}> StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                                    ExtraLengthNeed = MatPro{m}{12}* ceil(LengthNeedforRest/MatPro{m}{12});
                                    l_space = l_space + ExtraLengthNeed ;   
                                end

                            else
                                temp_w_space = MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
                                if temp_w_space + 2 > StockWidth{OptScenarioNum}{m}
                                    w_space = StockWidth{OptScenarioNum}{m};
                                else
                                    w_space = temp_w_space;
                                end
                                l_space = MatPro{m}{12};
                            end
                            AreaNeedforMat=l_space * w_space;


                        elseif MatPro{m}{8}(1:2) == "PL"
                            SpaceNeed=max(InitialMRP(m,:));
                            MatUnitNum = ceil(SpaceNeed/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10}));
                            MaxNumRow=floor(StockHeight{OptScenarioNum}{m}/MatPro{m}{11});
                            if MatUnitNum*MatPro{m}{11}>StockHeight{OptScenarioNum}{m}
                                h_space=MaxNumRow*MatPro{m}{11};
                            else
                                h_space=MatUnitNum*MatPro{m}{11};
                            end
                            l_space = MatPro{m}{12};
                            WidthNeedforSpace =MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space * MatPro{m}{10}));
                            if WidthNeedforSpace>StockWidth{OptScenarioNum}{m}
                                w_space = MatPro{m}{10}*floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{10});
                                UnitArrangeDone = (h_space * w_space * l_space)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                UnitNeedtArrange = MatUnitNum - UnitArrangeDone ;
                                SpaceNeedforRest = UnitNeedtArrange*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m})
                                    NumLenAvaInWidth =  floor(StockWidth{OptScenarioNum}{m}/MatPro{m}{12});
                                else
                                    NumLenAvaInWidth =1;
                                end
                                if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                                    h_space_rest=MaxNumRow*MatPro{m}{11}; 
                                else
                                    h_space_rest=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                                end
                                AreaNeedforRest = SpaceNeedforRest/h_space_rest;
                                LengthNeedforRest = AreaNeedforRest/w_space;

                                if (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest<=MatPro{m}{12})
                                    ExtraLengthNeed =MatPro{m}{10}*ceil(SpaceNeedforRest/(h_space_rest*w_space)/MatPro{m}{10});
                                    l_space = l_space + ExtraLengthNeed;

                                elseif (MatPro{m}{12}<=StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                                    Extralen_1 =  MatPro{m}{12} * floor(LengthNeedforRest/MatPro{m}{12});
                                    UnitDoneinExtra1 = (h_space * w_space * Extralen_1)/(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                    RestUnit = UnitNeedtArrange - UnitDoneinExtra1;
                                    SpaceNeedRestUnit2 = RestUnit*(MatPro{m}{12}*MatPro{m}{11}*MatPro{m}{10});
                                    if UnitNeedtArrange*MatPro{m}{11}/NumLenAvaInWidth>StockHeight{OptScenarioNum}{m}
                                        h_space_rest2=MaxNumRow*MatPro{m}{11}; 
                                    else
                                        h_space_rest2=MatUnitNum*MatPro{m}{11}/NumLenAvaInWidth;
                                    end

                                    Extralen_2 = MatPro{m}{10}*ceil(SpaceNeedRestUnit2/(h_space_rest2*w_space)/MatPro{m}{10});
                                    l_space = l_space +  Extralen_1 + Extralen_2;
                                elseif (MatPro{m}{12}> StockWidth{OptScenarioNum}{m}) && (LengthNeedforRest>MatPro{m}{12})
                                    ExtraLengthNeed = MatPro{m}{12}* ceil(LengthNeedforRest/MatPro{m}{12});
                                    l_space = l_space + ExtraLengthNeed;   
                                end

                            else
                                temp_w_space = MatPro{m}{10}*ceil(SpaceNeed/(h_space*l_space)/MatPro{m}{10});
                                if temp_w_space + 2 > StockWidth{OptScenarioNum}{m}
                                    w_space = StockWidth{OptScenarioNum}{m};
                                else
                                    w_space = temp_w_space;
                                end
                                l_space = MatPro{m}{12};

                            end
                            AreaNeedforMat=l_space * w_space;
                        end
                        AreaNeed(m,1) = l_space;
                        AreaNeed(m,2) = w_space;
                        AreaNeed(m,3) = AreaNeedforMat;
                        if (AreaNeed(m,1)<=StockLength{OptScenarioNum}{m}) && (AreaNeed(m,2)<=StockWidth{OptScenarioNum}{m})
                            stockdone=stockdone+1;
                        end
                    end
                    if stockdone == NumMaterial 
                        dayOk=D(n);
                    else
                        InitialPoint(n)=InitialPoint(n)+1;
                    end
                end 
                
                if (dayOk ==D(n)) && (TryNumber<=Duration)
                    for m=1:NumMaterial
                        for t=1:StepT:Duration
                            if t+MatPro{m}{4}<Duration
                                if t+MatPro{m}{4}+StepT-1<Duration
                                    if t+MatPro{m}{5}<Duration
                                        tempBQ1(m,t)= ceil(sum(InitialMRP(m,t+MatPro{m}{4}:t+MatPro{m}{4}+StepT-1))*MatPro{m}{9}*randparamet);
                                        tempBQ2(m,t)= ceil(sum(InitialMRP(m,t+MatPro{m}{4}:t+MatPro{m}{4}+StepT-1))*MatPro{m}{9}*(1-randparamet));
                                    else
                                        tempBQ1(m,t)= ceil(sum(InitialMRP(m,t+MatPro{m}{4}:t+MatPro{m}{4}+StepT-1))*MatPro{m}{9});
                                        tempBQ2(m,t)= 0;
                                    end
                                else
                                    if t+MatPro{m}{5}<Duration
                                        tempBQ1(m,t)= ceil(sum(InitialMRP(m,t+MatPro{m}{4}:Duration))*MatPro{m}{9}*randparamet);
                                        tempBQ2(m,t)= ceil(sum(InitialMRP(m,t+MatPro{m}{4}:Duration))*MatPro{m}{9}*(1-randparamet));
                                    else
                                        tempBQ1(m,t)= ceil(sum(InitialMRP(m,t+MatPro{m}{4}:Duration))*MatPro{m}{9});
                                        tempBQ2(m,t)= 0;
                                    end
                                    
                                end
                            else 
                                tempBQ1(m,t)= 0;
                                tempBQ2(m,t)=0;
                            end
                        end
                    end
                    
                    tempDQ=zeros(NumMaterial,Duration);
                    for t = 1:Duration
                        for m = 1:NumMaterial
                            if t-MatPro{m}{4}>=0
                                tempDQ(m,t)= tempDQ(m,t) + tempBQ1(m,t-MatPro{m}{4}+1)+tempBQ2(m,t-MatPro{m}{4}+1); 
                            end
                        end
                    end
                    tempOC=zeros(NumMaterial,Duration);
                    for t =1:Duration
                        for m = 1:NumMaterial
                            UnitPriceP1 = 0;
                            UnitPriceP21 = 0;
                            UnitPriceP22 = 0;
                            RateAtT0 = 0;
                            RateAtDelta = 0;
                            for i = 1:numel(MatCost{m})
                                if (MatCost{m}{i}{1} <= tempBQ1(m,t)) && (MatCost{m}{i}{2} >= tempBQ1(m,t))
                                    UnitPriceP1 = MatCost{m}{i}{3}; 
                                    break
                                end
                                if (MatCost{m}{i}{1} <= tempBQ2(m,t)) && (MatCost{m}{i}{2} >= tempBQ2(m,t))
                                    UnitPriceP21 = MatCost{m}{i}{4}; 
                                    RateAtT0 = MatCost{m}{i}{5};
                                    break
                                end
                                if ((t - MatPro{m}{5}) > 0) && (MatCost{m}{i}{1} <= tempBQ2(m,t- MatPro{m}{4})) && (MatCost{m}{i}{2} >= tempBQ2(m,t- MatPro{m}{5}))
                                    UnitPriceP22 = MatCost{m}{i}{4}; 
                                    RateAtDelta = MatCost{m}{i}{6};
                                    break
                                end
                            end

                            if (t - MatPro{m}{5}) > 0
                                tempOC(m,t)=(tempBQ2(m,t)* UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(Duration-t))) + (tempBQ2(m,t- MatPro{m}{5})  * UnitPriceP22 * RateAtDelta * ((1+MatPro{m}{6})^(Duration-t+MatPro{m}{5}))) + (tempBQ1(m,t)  * UnitPriceP1 * ((1+MatPro{m}{6})^(Duration-t)));
                            else
                                tempOC(m,t)=(tempBQ2(m,t)* UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(Duration-t))) + (tempBQ1(m,t)  * UnitPriceP1 * ((1+MatPro{m}{6})^(Duration-t))); 
                            end

                        end
                    end

                    %part2:hazine haml

                    tempDC=zeros(NumMaterial,Duration);
                    for t =1:Duration
                        for m = 1:NumMaterial
                            DeliveryCost = 0;
                            if tempDQ(m,t)~=0
                                for i = 1:numel( MatCost{m})
                                    if (MatCost{m}{i}{1} <= tempDQ(m,t)) && (MatCost{m}{i}{2} >= tempDQ(m,t))
                                        DeliveryCost = MatCost{m}{i}{7};  
                                    end
                                end
                                tempDC(m,t)= DeliveryCost * ((1+TFR)^(t));
                            end
                        end
                    end
                    %part3:hazine negahdari
                    tempSC=zeros(NumMaterial,Duration);
                    %part4:hazine takhir
                    if n == NumTask
                        if (InitialPoint(NumTask)+D(NumTask)) >(days(DDPC-LDT)+1)
                            temp_dif_T = string(InitialPoint(NumTask)+D(NumTask) - (days(DDPC-LDT)+1));
                            temp=textscan(temp_dif_T,'%f');
                            Diff = double(temp{1});
                            tempDFP = Diff * DPC;
                        else
                            tempDFP=0;
                        end
                    else
                        tempDFP=0;
                    end

                    tempFI=[];
                    for t =1:Duration
                        Temp_total_cost_t = 0;
                        for m = 1:NumMaterial
                            Temp_total_cost_t = Temp_total_cost_t + tempOC(m,t) + tempDC(m,t) + tempSC(m,t);
                        end
                        if t == 1
                            tempFI(t) = B(t) - Temp_total_cost_t;
                        elseif t == Duration
                            tempFI(t) = (tempFI(t-1)*(1+IR)) + B(t) - Temp_total_cost_t - tempDFP;
                        else
                            tempFI(t) = (tempFI(t-1)*(1+IR)) + B(t) - Temp_total_cost_t;
                        end
                    end
                    if n ==22
                        a=1;
                    end
                    if (min(tempFI)<0) && (InitialPoint(n)+1<=Duration-D(n)+1)
                        if (isnan(WLSTask(n))==0) && (InitialPoint(n)<=WLSTask(n))
                            InitialPoint(n) = InitialPoint(n)+1;
                        elseif isnan(WLSTask(n))==1
                            InitialPoint(n) = InitialPoint(n)+1;
                        elseif (isnan(WLSTask(n))==0) && (InitialPoint(n)>WLSTask(n))
                            InitialPoint=[];
                            jobdone =1;
                        elseif (isnan(WLFTask(n))==0) && (InitialPoint(n)+D(n)-1<=WLFTask(n))
                            InitialPoint(n) = InitialPoint(n)+1;
                        elseif isnan(WLFTask(n))==1
                            InitialPoint(n) = InitialPoint(n)+1;
                        elseif (isnan(WLFTask(n))==0) && (InitialPoint(n)+D(n)-1>WLFTask(n))
                            InitialPoint=[];
                            jobdone =1;
                        end

                    elseif (min(tempFI)>=0) && (InitialPoint(n)<=Duration-D(n)+1)
                        if (isnan(WLSTask(n))==0) && (InitialPoint(n)<=WLSTask(n)) 
                            jobdone=1;
                        elseif isnan(WLSTask(n))==1
                            jobdone=1;
                        elseif (isnan(WLSTask(n))==0) && (InitialPoint(n)>WLSTask(n))
                            InitialPoint=[];
                            jobdone =1;
                        elseif (isnan(WLFTask(n))==0) && (InitialPoint(n)+D(n)-1<=WLFTask(n))
                            jobdone=1;    
                        elseif isnan(WLFTask(n))==1
                            jobdone=1; 
                        elseif (isnan(WLFTask(n))==0) && (InitialPoint(n)+D(n)-1>WLFTask(n))
                            InitialPoint=[];
                            jobdone =1;
                        end
                    else
                        InitialPoint=[];
                        priZoneNotFound=1;
                        jobdone =1;
                    end


                elseif  TryNumber > Duration
                    priZoneNotFound=1;
                    InitialPoint=[];
                    jobdone =1;
                else
                    TryNumber = TryNumber+1;
                end
            end
        end
    end
    if numel(InitialPoint)~=0
        for m = 1:NumMaterial
            for t = 1:Duration
                InitialPoint(NumTask + (((2*m)+1-3)*(Duration))+t) = tempBQ1(m,t);
                InitialPoint(NumTask + (((2*m)+2-3)*(Duration))+t) = tempBQ2(m,t);
            end
        end
        InitialPop = [InitialPop; InitialPoint];
        firstdayofconstruct = firstdayofconstruct +1;
    else
        if size(InitialPop)~=0
            InitialPop = [InitialPop; InitialPop(1,:)];
        end
        firstdayofconstruct = possiblefirstDay;
    end
end


end


function Cost = Function(x)

global NumTask LDT Duration D NumMaterial UQ MatPro DDPC IR TFR OFR DPC MatCost B

% %%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%
% %Method 1: dont use global paramet
% %%%%mohasebe mizane MRP(UQ) DQ BQ SQ
%part1:taine mizane mrp(m,t)
MRP = zeros(NumMaterial,Duration);
SQ = zeros(NumMaterial,Duration);
Q=[];
for t = 1:Duration
% dar har roz yek matrix q ba tedad satre barabar ba material va sotone
% barabar ba tedad failat ha ijad mikonim ta mizane morede niaz material
% moshakhas shavad
    Q{t}=zeros(NumMaterial,NumTask);
    for n = 1:NumTask
        if (x(n)<=t) && (t<=x(n)+D(n)-1)
            for m = 1:NumMaterial
                Q{t}(m,n) = Q{t}(m,n) + UQ(m,n)*MatPro{m}{9};
            end
        end 
    end
    for m = 1:NumMaterial
       for n = 1:NumTask
           MRP(m,t) = MRP(m,t) + Q{t}(m,n);
       end
    end
end
    
%part2:taine mizane material khridari shode(x ha) va mizane tahvil gerefte
%shode dar site DQ
DQ=zeros(NumMaterial,Duration);
BQ1=zeros(NumMaterial,Duration);
BQ2=zeros(NumMaterial,Duration);
for m = 1:NumMaterial
    %p=1 kharide naghdi
    %p=2 kharide ghesti
    for p =1:2
        for t = 1:Duration
            if p == 1
                BQ1(m,t) = x(NumTask + (((2*m)+p-3)*(Duration))+t);
            elseif p == 2
                BQ2(m,t) = x(NumTask + (((2*m)+p-3)*(Duration))+t);
            end
        end
    end
end


for m=1:NumMaterial
    for t= 1:Duration
        if t-MatPro{m}{4}>=0
            DQ(m,t)= DQ(m,t) + BQ1(m,t-MatPro{m}{4}+1) + BQ2(m,t-MatPro{m}{4}+1);
        end
    end
end

%part3:mohasebe mizane mojodie anbar
for m = 1:NumMaterial
    for t = 1:Duration
         if t==1
             SQ(m,t) = MatPro{m}{3} + (DQ(m,t)/MatPro{m}{9});
         else
             SQ(m,t) = SQ(m,t-1) + (DQ(m,t)/MatPro{m}{9}) - (MRP(m,t-1)/MatPro{m}{9});
         end     
    end
end
%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%part1:hazine kharide 
OC=zeros(NumMaterial,Duration);
for t =1:Duration
    for m = 1:NumMaterial
        UnitPriceP1 = 0;
        UnitPriceP21 = 0;
        UnitPriceP22 = 0;
        RateAtT0 = 0;
        RateAtDelta = 0;
        for i = 1:numel(MatCost{m})
            if (MatCost{m}{i}{1} <= BQ1(m,t)) && (MatCost{m}{i}{2} >= BQ1(m,t))
                UnitPriceP1 = MatCost{m}{i}{3}; 
            end
            if (MatCost{m}{i}{1} <= BQ2(m,t)) && (MatCost{m}{i}{2} >= BQ2(m,t))
                UnitPriceP21 = MatCost{m}{i}{4}; 
                RateAtT0 = MatCost{m}{i}{5};
            end
            if ((t - MatPro{m}{5}) > 0) && (MatCost{m}{i}{1} <= BQ2(m,t- MatPro{m}{4})) && (MatCost{m}{i}{2} >= BQ2(m,t- MatPro{m}{5}))
                UnitPriceP22 = MatCost{m}{i}{4}; 
                RateAtDelta = MatCost{m}{i}{6};
            end
        end
        
        if (t - MatPro{m}{5}) > 0
            OC(m,t)=(BQ2(m,t) * UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(Duration-t))) + (BQ2(m,t- MatPro{m}{5}) *  UnitPriceP22 * RateAtDelta * ((1+MatPro{m}{6})^(Duration-t+MatPro{m}{5}))) + (BQ1(m,t)  * UnitPriceP1 * ((1+MatPro{m}{6})^(Duration-t)));
        else
            OC(m,t)=(BQ2(m,t) * UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(Duration-t))) + (BQ1(m,t) * UnitPriceP1 * ((1+MatPro{m}{6})^(Duration-t))); 
        end
        
    end
end
% part2:hazine haml
DC=zeros(NumMaterial,Duration);
for t =1:Duration
    for m = 1:NumMaterial
        DeliveryCost = 0;
        for i = 1:numel( MatCost{m})
            if (MatCost{m}{i}{1} <= DQ(m,t)) && (MatCost{m}{i}{2} >= DQ(m,t))
                DeliveryCost = MatCost{m}{i}{7};  
            end
        end
        if DQ(m,t)==0
            DC(m,t)=0;
        else
            DC(m,t)= DeliveryCost * ((1+TFR)^(t));
        end
    end
end
%part3:hazine negahdari
SC=zeros(NumMaterial,Duration);
for t =1:Duration
    for m = 1:NumMaterial
        if SQ(m,t)>0
            SC(m,t) = SQ(m,t) * MatPro{m}{7};
        end
    end
end
%part4:hazine takhir
if (x(NumTask)+D(NumTask)) >(days(DDPC-LDT)+1)
    temp_dif_T = string(x(NumTask)+D(NumTask) - (days(DDPC-LDT)+1));
    temp=textscan(temp_dif_T,'%f');
    Diff = double(temp{1});
    DFP = Diff * DPC;
else
    DFP=0;
end
%part5:hazine tamin malie
%part5-1: mohasebe average cost kharid material (AOCm)

%Method2: use global paramet
AOC = [];
for m = 1:NumMaterial
    Sum_OC = 0;
    Sum_DQ = 0;
    for t = 1:Duration
        Sum_OC = Sum_OC + OC(m,t);
        Sum_DQ = Sum_DQ + DQ(m,t);
    end
    AOC(m) = Sum_OC / Sum_DQ;
end
%part5-2: mhazine tamin malie(cc)
CC=zeros(1,Duration);
for t = 1:Duration
    for m = 1:NumMaterial
        CC(t)=CC(t) + AOC(m) * IR;
    end
end

%%%%%%%%%%%%%%%%%%%

% % Method 1 function: use Capital Cost
% % mohasebe arzeshe hazine ha dar zaman MaxDeliveryDateofProject(part1 tabe
% % hadaf)
total_oc=0;
total_dc=0;
total_sc=0;
cost = 0;
for t = 1:Duration
    Temp_total_cost_t =0;
    for m = 1:NumMaterial
        Temp_total_cost_t = Temp_total_cost_t + OC(m,t)+ DC(m,t) + SC(m,t) ;
        total_oc=total_oc+OC(m,t);
        total_dc=total_dc+DC(m,t);
        total_sc=total_sc+SC(m,t);

    end
    FPI = (1+OFR)^(Duration-t);
    cost = cost + ((Temp_total_cost_t) * FPI);
end
CostPart1 =(cost + DFP);


% % % Method 2 function: use cash flow and FI
% 
% FI=[];
% for t =1:Duration
%     Temp_total_cost_t = 0;
%     for m = 1:NumMaterial
%         Temp_total_cost_t = Temp_total_cost_t + OC(m,t) + DC(m,t) + SC(m,t) ;
%     end
%     if t == 1
%         FI(t) = B(t) - Temp_total_cost_t;
%     elseif t == Duration
%         FI(t) = (FI(t-1)*(1+IR)) + B(t) - Temp_total_cost_t - DFP;
%     else
%         FI(t) = (FI(t-1)*(1+IR)) + B(t) - Temp_total_cost_t;
%     end
% end
% 
% cost = 0;
% for t = 1:Duration
%     FPI = (1+OFR)^(Duration-t);
%     cost = cost + (FI(t) * FPI);
% end
% CostPart1 = -(cost);

%%%%%%%%%%%%%%%%%%%%%%%
%mohasebe navasane hajme mavad mojod dar anbar(part1 tabe hadaf)

% VolumeFlac=0;
% if WSPACE ~=0
%     for m = 1:NumMaterial
%         DifVolMat=0;
%         for t = 2:Duration
%             DifVolMat = DifVolMat +(SQ(m,t)-SQ(m,t-1))^2;
%         end
%         VolumeFlac = VolumeFlac + MatPro{m}{14}*DifVolMat;
%     end
%     CostPart2 = WSPACE*(AreaFlac);
% else 
%     CostPart2=0;
% end
% 
% Cost=CostPart1+CostPart2;
Cost=CostPart1;
end
