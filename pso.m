
clc;
clear;
close all;

format short
digits(4);

t1=datetime('now');
global TF OptScenarioNum NumScenario MaxQMat MinQMat WESTask WEFTask WLSTask WLFTask possiblefirstDay TQM lastIndexX Predecessors NumTask ESPC LDT Duration D NumMaterial UQ MatPro ProfSurArea  DDPC MDDP StockLength StockWidth StockHeight StockCost IR TFR OFR DPC MatCost B WCOST WSPACE
conn= database('DataBase','admin','admin');

%%Specify the number of "Zones" [NumTask] and the list of Predecessors for each Zone [Predecessors] and the Duration of each Zone [D(n)] from "tblZoneDetails"
query='select * from tblZoneDetails';
Data=fetch(conn,query);
NumTask=numel(Data.ID);
D=[];
TF=[];
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
    TF(Data.ID(n))=Data.TF(n);
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

temp_firstday = string(days(days(ESPC-LDT)+1));
temp=textscan(temp_firstday,'%f');
possiblefirstDay = double(temp{1});
ES=zeros(NumTask,1);
%%%calculate ES of tasks
for n = 1:NumTask
    tempList=[];
    if isnan(WESTask(n))==0
        tempList = [tempList;WESTask(n)];
    end

    if isnan(WEFTask(n))==0
        tempList = [tempList;WEFTask(n)-D(n)+1];
    end
    if Predecessors{n}{1}=="Nothing"
        %x(n)>= ESPC;
        %x(n)+D(n) <= MDDP;
        tempList = [tempList;possiblefirstDay];
        
    else
        for p=1:numel(Predecessors{n})
            temp=textscan(Predecessors{n}{p},'%s','Delimiter',',');
            taskID=str2double((temp{1}{1}));
            rel=temp{1}{2};
            lag=str2double(temp{1}{3});
            if rel=="FS"
                %x(n) >= x(taskID) + D(taskID) + lag;
                %x(n)+D(n) <= MDDP;
                %x(n)>= ESPC;
                tempList=[tempList;ES(taskID) + D(taskID)];
            elseif rel=="SS"
                %x(n) >= x(taskID) + lag;
                %x(n)+D(n) <= MDDP;
                %x(n)>= ESPC;
                tempList=[tempList;ES(taskID) + lag];
            elseif rel=="FF"
                %x(n) >= x(taskID) + D(taskID) + lag - D(n);
                %x(n)+D(n) <= MDDP;
                %x(n)>= ESPC;
                tempList=[tempList;ES(taskID) + D(taskID) + lag - D(n)];
            elseif rel=="SF"
                %x(n) >= x(taskID) + lag - D(n);
                %x(n)+D(n) <= MDDP;
                %x(n)>= ESPC;
                tempList=[tempList;ES(taskID) + lag - D(n)+1];
            end
        end
    end

    ES(n)=max(tempList);
    
end
%%%




nvars=NumTask;

%UB AND LB OF ZONE START
LB = [];   % Lower bound
UB = [];   % Upper bound



for n = 1:NumTask
   LB=[LB ES(n)];
   UB=[UB ES(n)+TF(n)];
end



%%%%%%%%%%%%%%%%%%%%%%%%%%








%% Problem Definition



nVar = nvars;            % Number of Decision Variables

VarSize = [1 nVar];   % Size of Decision Variables Matrix

VarMin = LB;         % Lower Bound of Variables
VarMax = UB;         % Upper Bound of Variables


%% PSO Parameters

MaxIt = 2;      % Maximum Number of Iterations

nPop = 3;        % Population Size (Swarm Size)

% PSO Parameters
w = 1;            % Inertia Weight
wdamp = 0.99;     % Inertia Weight Damping Ratio
c1 = 1.5;         % Personal Learning Coefficient
c2 = 2.0;         % Global Learning Coefficient

% If you would like to use Constriction Coefficients for PSO, 
% uncomment the following block and comment the above set of parameters.

% % Constriction Coefficients
% phi1 = 2.05;
% phi2 = 2.05;
% phi = phi1+phi2;
% chi = 2/(phi-2+sqrt(phi^2-4*phi));
% w = chi;          % Inertia Weight
% wdamp = 1;        % Inertia Weight Damping Ratio
% c1 = chi*phi1;    % Personal Learning Coefficient
% c2 = chi*phi2;    % Global Learning Coefficient

% Velocity Limits
VelMax = 0.1*(VarMax-VarMin);
VelMin = -VelMax;
% 
%% Initialization

empty_particle.Position = [];
empty_particle.BuyQ = [];
empty_particle.Cost = [];
empty_particle.Velocity = [];
empty_particle.Best.Position = [];
empty_particle.Best.Cost = [];
empty_particle.Best.BuyQ = [];

particle = repmat(empty_particle, nPop, 1);

GlobalBest.Cost = inf;
 for OptScenarioNum = 1:1
    CostFunction = @(x) CostTime(x,MaxQMat,NumTask,LDT,Duration,D,NumMaterial,UQ,MatPro,DDPC,TFR,OFR,DPC,MatCost,OptScenarioNum, WESTask ,WEFTask ,WLSTask ,WLFTask ,TQM ,Predecessors,StockLength ,StockWidth ,StockHeight,B,ProfSurArea);     % Cost Function
    
    for i = 1:nPop
        %Initialize Position
        for n = 1:nVar
            if n==1
                particle(i).Position(n)=randi([LB(n),(UB(n))]);
            else
                tempList=[];
                if isnan(WESTask(n))==0
                    tempList = [tempList;WESTask(n)];
                end

                if isnan(WEFTask(n))==0
                    tempList = [tempList;WEFTask(n)-D(n)+1];
                end
                if Predecessors{n}{1}=="Nothing"
                    %x(n)>= ESPC;
                    %x(n)+D(n) <= MDDP;
                    tempList = [tempList;possiblefirstDay];

                else
                    for p=1:numel(Predecessors{n})
                        temp=textscan(Predecessors{n}{p},'%s','Delimiter',',');
                        taskID=str2double((temp{1}{1}));
                        rel=temp{1}{2};
                        lag=str2double(temp{1}{3});
                        if rel=="FS"
                            %x(n) >= x(taskID) + D(taskID) + lag;
                            %x(n)+D(n) <= MDDP;
                            %x(n)>= ESPC;
                            tempList=[tempList;particle(i).Position(taskID) + D(taskID)];
                        elseif rel=="SS"
                            %x(n) >= x(taskID) + lag;
                            %x(n)+D(n) <= MDDP;
                            %x(n)>= ESPC;
                            tempList=[tempList;particle(i).Position(taskID) + lag];
                        elseif rel=="FF"
                            %x(n) >= x(taskID) + D(taskID) + lag - D(n);
                            %x(n)+D(n) <= MDDP;
                            %x(n)>= ESPC;
                            tempList=[tempList;particle(i).Position(taskID) + D(taskID) + lag - D(n)];
                        elseif rel=="SF"
                            %x(n) >= x(taskID) + lag - D(n);
                            %x(n)+D(n) <= MDDP;
                            %x(n)>= ESPC;
                            tempList=[tempList;particle(i).Position(taskID) + lag - D(n)+1];
                        end
                    end
                end

                ES=max(tempList);
                particle(i).Position(n)=randi([ES,(UB(n))]);
            end
        end
        %Initialize Velocity
        particle(i).Velocity = zeros(VarSize);
        % Evaluation
        CostWithBuy=CostFunction(particle(i).Position);
        particle(i).Cost = cell2mat(CostWithBuy(1));
        particle(i).BuyQ = CostWithBuy(2);

        % Update Personal Best
        particle(i).Best.Position = particle(i).Position;
        particle(i).Best.Cost = particle(i).Cost;
        particle(i).Best.BuyQ = particle(i).BuyQ;


        % Update Global Best
        if particle(i).Best.Cost<GlobalBest.Cost

            GlobalBest = particle(i).Best;

        end

    end

    BestCost = zeros(MaxIt, 1);

% 
%     %% PSO Main Loop

    for it = 1:MaxIt

        for i = 1:nPop

            % Update Velocity
            particle(i).Velocity = round(w*particle(i).Velocity ...
                +c1*rand(VarSize).*(particle(i).Best.Position-particle(i).Position) ...
                +c2*rand(VarSize).*(GlobalBest.Position-particle(i).Position));

            % Apply Velocity Limits
            particle(i).Velocity = max(particle(i).Velocity, VelMin);
            particle(i).Velocity = min(particle(i).Velocity, VelMax);

            % Update Position
            particle(i).Position = round(particle(i).Position + particle(i).Velocity);

            % Velocity Mirror Effect
            IsOutside = (particle(i).Position<VarMin | particle(i).Position>VarMax);
            particle(i).Velocity(IsOutside) = -particle(i).Velocity(IsOutside);

            % Apply Position Limits
            for n= 1:nVar
                if n==1
                    particle(i).Position(n) = max(particle(i).Position(n), VarMin(n));
                    particle(i).Position(n) = min(particle(i).Position(n), VarMax(n));
                else
                    tempList=[];
                    if isnan(WESTask(n))==0
                        tempList = [tempList;WESTask(n)];
                    end

                    if isnan(WEFTask(n))==0
                        tempList = [tempList;WEFTask(n)-D(n)+1];
                    end
                    if Predecessors{n}{1}=="Nothing"
                        %x(n)>= ESPC;
                        %x(n)+D(n) <= MDDP;
                        tempList = [tempList;possiblefirstDay];

                    else
                        for p=1:numel(Predecessors{n})
                            temp=textscan(Predecessors{n}{p},'%s','Delimiter',',');
                            taskID=str2double((temp{1}{1}));
                            rel=temp{1}{2};
                            lag=str2double(temp{1}{3});
                            if rel=="FS"
                                %x(n) >= x(taskID) + D(taskID) + lag;
                                %x(n)+D(n) <= MDDP;
                                %x(n)>= ESPC;
                                tempList=[tempList;particle(i).Position(taskID) + D(taskID)];
                            elseif rel=="SS"
                                %x(n) >= x(taskID) + lag;
                                %x(n)+D(n) <= MDDP;
                                %x(n)>= ESPC;
                                tempList=[tempList;particle(i).Position(taskID) + lag];
                            elseif rel=="FF"
                                %x(n) >= x(taskID) + D(taskID) + lag - D(n);
                                %x(n)+D(n) <= MDDP;
                                %x(n)>= ESPC;
                                tempList=[tempList;particle(i).Position(taskID) + D(taskID) + lag - D(n)];
                            elseif rel=="SF"
                                %x(n) >= x(taskID) + lag - D(n);
                                %x(n)+D(n) <= MDDP;
                                %x(n)>= ESPC;
                                tempList=[tempList;particle(i).Position(taskID) + lag - D(n)+1];
                            end
                        end
                    end
                    ES=max(tempList);
                    particle(i).Position(n) = max(particle(i).Position(n), ES);
                    particle(i).Position(n) = min(particle(i).Position(n), VarMax(n));


                end
            end
                % Evaluation
            
            CostWithBuy=CostFunction(particle(i).Position);
            particle(i).Cost = cell2mat(CostWithBuy(1));
            particle(i).BuyQ = CostWithBuy(2);

            % Update Personal Best
            if particle(i).Cost<particle(i).Best.Cost

                particle(i).Best.Position = particle(i).Position;
                particle(i).Best.Cost = particle(i).Cost;
                particle(i).Best.BuyQ = particle(i).BuyQ;

                % Update Global Best
                if particle(i).Best.Cost<GlobalBest.Cost

                    GlobalBest = particle(i).Best;

                end

            end

        end

        BestCost(it) = GlobalBest.Cost;

        disp(['IterationTime ' num2str(it) ': Best Cost = ' num2str(BestCost(it))]);

        w = w*wdamp;

      end

    BestSol = GlobalBest;


    % Results

    figure;
    %plot(BestCost, 'LineWidth', 2);
    semilogy(BestCost, 'LineWidth', 2);
    xlabel('Iteration');
    ylabel('Best Cost');
    grid on;
    
%     %bestX=[BestSol.Position,BestSol.BuyQ];
    bestXTime=GlobalBest.Position;
    bestXBuy=GlobalBest.BuyQ{1};
    BestCost=GlobalBest.Cost;
%     bestXTime=[16,32,32,40,40,40,45,51,68,69,77,77,77,82,90,109,109,119,119,120,127,132,143,144,150,149,151,154,161,169,171,176,177,176,180,188,196,196,201,202,201,205];
%     bestXBuy=[32.966,75.567,62.572,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.87,0.92,1,0.89,0.6,0.91,0.71,1,0.71,0.82,0.4,0.8,0.87,0.8,0.64,0.75,0.66,0.76,0.78,0.66,0.68,0.91,0.81,0.45,0.66,0.59,0.6,0.55,0.89,0.87,0.81,0.84,1,0.74,0.7,0.71,0.66,0.49,0.96,0.83,0.63,0.56,0.79,0.48,0.45,0.93,0.44,0.82,0.91,0.84,0.79,0.54,0.48,0.91,0.85,0.83,0.75,0.59,0.89,0.97,0.78,0.8,0.97,0.58,0.55,0.95,0.85,0.6,0.74,0.53,0.98,0.64,0.8,0.82,0.52,0.74,0.47,0.39,0.85,0.44,0.77,0.64,0.91,0.82,0.61,0.7,0.92,0.93,0.96,0.79,0.91,0.66,0.46,0.69,0.73,0.72,0.91,0.87,0.56,0.62,0.54,0.55,0.55,0.64,0.86,0.8,0.83,0.68,0.74,0.7,0.68,0.59,0.85,0.55,0.77,0.35,0.89,0.62,0.89,0.58,0.74,0.62,0.6,0.61,0.93,0.64,0.92,0.37,0.61,0.66,0.86,0.54,0.89,0.82,0.59,0.74,0.53,0.69,0.64,0.88,0.87,0.53,0.57,0.54,0.9,0.8,0.43,0.9,0.4,0.73,0.83,0.64,0.6,0.61,0.61,0.42,0.78,0.55,0.77,0.85,0.73,0.99,0.49,0.81,0.95,0.77,0.34,0.44,0.65,0.67,0.8,0.93,0.65,0.57,0.8,0.65,1,0.53,0.94,0.48,0.4,0.89,0.89,0.64,0.89,0.82,0.78,0.56,0.7,0.88,0.63,0.9,0.61,0.9,0.49,0.56,0.85,0.47,0.88,0.82,0.55,0.84,0.63,0.57,0.41,0.72,0.827,3.85,0.457,0,0.58,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1.523,1.54,0.631,0.645,1.275,1.166,0.715,0.625,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.631,0.722,0,1.62,0.55,0.565,0.625,0.793,0.759,0.04,0.04,0.04,0,0.043,0.043,0.045,0.043,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.872,1.152,0.719,1.635,0.991,0.927,0.711,1.69,1.481,0.529,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.009,0.005,0.006,0.006,0,0,0,0,0,0,0,0,0,0,0,0,0,0.247,0.247,0,0,1.797,0.904,0,0.626,1.344,0,0.405,0.472,0.87,0,0,0,0.681,1.843,0.853,1.346,2.265,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.62,0.68,0.8,0.74,0.88,0.99,0.7,0.83,0.79,0.68,0.8,0.78,0.81,0.65,0.89,0.74,0.61,0.87,0.79,0.51,0.87,0.84,0.55,0.69,0.63,0.6,0.67,0.56,0.65,0.8,0.91,0.81,0.8,0.97,0.8,0.66,0.76,0.53,0.9,0.43,0.66,0.56,0.82,0.52,0.77,0.67,0.91,0.81,0.58,0.9,0.8,0.83,0.97,0.71,0.35,0.75,0.85,0.62,0.73,0.55,0.53,0.82,0.88,0.47,0.97,0.7,0.79,0.78,0.76,0.61,0.95,0.9,0.76,0.66,0.86,0.86,0.99,0.93,0.49,0.87,0.9,0.7,0.94,0.82,0.74,0.89,0.58,0.45,0.58,0.45,0.76,0.99,0.38,0.65,0.6,0.89,0.47,0.82,0.57,0.81,0.31,0.61,0.79,0.56,0.91,0.86,0.84,0.67,1,0.9,0.91,0.85,0.48,0.81,0.69,0.79,0.61,0.48,0.61,0.62,0.97,0.69,0.65,0.91,0.67,0.92,0.84,0.75,0.76,0.81,0.53,0.72,0.83,0.34,0.9,0.73,0.64,0.91,0.57,0.68,0.53,0.48,0.64,0.88,0.82,0.72,0.72,0.68,0.67,0.57,0.64,0.7,0.66,0.74,0.56,0.78,0.94,0.71,0.6,0.75,0.85,0.72,0.9,0.66,0.5,0.55,0.79,0.64,0.51,0.41,0.92,0.72,0.5,0.64,0.61,0.71,0.67,0.64,0.98,0.87,0.84,0.86,0.92,0.52,0.77,0.71,0.46,0.51,0.52,0.98,0.76,0.64,0.64,0.46,0.52,0.45,0.54,0.31,0.68,0.88,0.63,0.8,0.56,0.54,0.53,0.62,0.611,23.08,24.835,20.834,10.513,3.382,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.82,0.82,0.61,0.93,0.7,0.96,0.34,0.45,0.66,0.73,0.22,0.77,0.42,0.91,0.87,0.52,0.44,0.75,0.8,0.98,0.62,0.66,0.3,0.91,0.65,0.65,0.25,0.8,0.79,0.92,0.68,0.72,0.82,0.39,0.89,0.72,0.89,0.62,0.79,0.82,0.82,0.55,0.72,0.63,1,0.55,0.66,0.4,0.43,0.98,0.96,0.92,0.67,0.82,0.82,0.53,0.69,0.68,0.82,0.87,0.6,0.98,0.68,0.6,0.37,0.69,0.77,0.28,0.78,0.92,0.76,0.28,0.96,0.49,0.72,0.64,0.79,0.73,0.97,0.86,0.58,0.58,0.57,0.76,0.95,0.82,0.88,0.43,0.8,0.39,0.42,0.92,0.73,0.66,0.85,0.82,0.66,0.58,0.91,0.38,0.95,0.85,0.78,0.78,0.89,0.74,0.31,0.76,0.91,0.86,0.51,0.85,0.98,0.69,0.77,0.42,0.7,0.91,0.98,0.52,0.85,0.71,0.67,0.74,0.65,0.83,0.86,0.85,0.77,0.6,0.8,0.77,0.57,0.74,0.8,0.88,0.55,0.55,0.37,0.82,0.99,0.74,0.76,0.83,0.5,0.55,0.42,1,0.88,0.57,0.71,0.72,0.96,0.81,0.87,0.83,0.71,0.83,0.71,0.67,0.77,0.4,0.79,0.6,0.83,0.84,0.57,0.54,0.85,0.95,0.59,0.88,0.68,0.63,0.79,0.64,0.69,0.89,0.86,0.69,0.6,0.96,0.75,0.43,0.66,0.74,0.68,0.69,0.69,0.53,0.66,0.84,0.72,0.79,0.58,0.65,0.86,0.99,0.78,0.58,0.67,0.94,0.78,0.61,0.84,0.83,0.897,47.001,32.072,4.203,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.82,0.88,0.54,0.64,0.76,0.83,0.87,0.77,0.95,0.59,0.69,0.92,0.83,0.6,0.85,0.88,0.85,0.52,0.96,0.69,0.44,0.82,0.78,0.6,0.86,0.95,0.55,0.63,0.92,0.41,1,0.82,0.69,0.67,0.85,0.79,0.98,0.81,0.86,0.29,0.23,0.8,0.56,0.7,0.75,0.54,0.84,0.79,0.81,0.89,0.74,0.4,0.79,0.59,0.79,0.78,0.71,0.81,0.64,0.73,0.83,0.68,0.68,0.7,0.54,0.6,0.95,0.96,0.53,0.69,0.9,0.42,0.58,0.78,0.8,0.87,0.78,0.63,0.6,0.45,0.45,0.78,0.55,0.67,0.81,0.69,0.91,0.87,0.73,0.51,0.89,0.95,0.9,0.57,0.82,0.75,0.84,0.62,0.59,0.66,0.96,0.94,0.72,0.92,0.61,0.55,0.64,0.72,0.93,0.88,0.82,0.98,0.72,0.78,0.82,0.89,0.59,0.59,0.95,0.46,0.69,0.5,0.89,0.52,0.55,0.51,0.73,0.97,0.72,0.64,0.78,1,0.74,0.74,0.83,0.96,0.67,0.56,0.46,0.55,0.89,0.88,0.84,0.81,0.98,1,0.8,0.63,0.74,0.43,0.69,0.97,0.53,0.84,0.68,0.89,0.29,0.81,0.78,0.58,0.55,0.69,0.78,0.48,0.87,0.84,0.73,0.7,0.75,0.84,0.76,0.74,0.77,0.68,0.85,0.65,0.48,0.97,0.58,0.87,0.76,0.76,0.95,0.62,0.54,0.66,0.86,0.87,0.29,0.84,0.83,0.78,0.97,0.88,0.81,0.92,0.7,0.58,0.89,0.83,0.75,0.8,0.77,0.72,0.57,0.95,0.488,34.184,33.146,23.481,3.761,0,0,0,0,0,0,0,5.879,3.939,0.345,0.511,0.354,0.379,0.377,0.459,0.377,0.387,0,0.373,0,0,0,0,1.397,2.892,6.376,1.151,1.124,4.075,6.354,1.216,2.66,0.08,0,0.328,0.247,0,0,0,0,0,0,0.382,0.382,0.382,0.382,0.382,0.382,0.382,0.382,0.382,0.382,0.382,0.384,0,0,0,0,0,0,5.391,6.074,11.138,2.615,11.579,5.433,8.767,6.514,14.179,6.083,0.436,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.84,0.72,0.99,0.99,0.47,0.82,0.63,0.93,0.87,0.85,0.86,0.52,0.73,0.9,0.79,0.7,0.49,0.53,0.92,0.58,0.84,0.94,0.77,0.69,0.67,0.76,0.87,0.69,0.94,0.95,0.77,0.86,0.73,0.84,0.89,0.9,0.43,0.61,0.81,0.96,0.88,0.72,0.54,0.93,0.76,0.78,0.35,0.35,0.7,0.49,0.85,0.57,0.64,0.85,0.74,0.91,0.82,0.81,0.56,0.8,0.65,0.69,0.7,0.74,0.97,0.75,0.75,0.73,0.78,0.71,0.77,0.41,0.62,0.61,0.58,0.88,0.76,0.68,0.82,0.69,0.74,0.83,0.75,0.91,0.77,0.75,0.41,0.48,0.97,1,0.8,0.6,0.58,0.82,0.6,0.75,0.7,0.75,0.73,0.78,0.72,0.74,0.58,0.37,0.92,0.76,0.83,0.78,0.83,0.5,0.64,0.67,0.78,0.92,0.9,0.54,0.59,0.64,0.71,0.69,0.7,0.79,0.6,0.67,0.83,0.86,0.6,0.85,0.71,0.63,0.85,0.45,0.98,0.72,0.91,0.95,0.78,0.8,0.46,0.69,0.64,0.89,0.81,0.81,0.87,0.85,0.81,0.6,1,0.71,0.74,0.85,0.94,0.84,0.82,0.59,0.7,0.53,0.58,0.3,0.81,0.89,0.56,0.58,0.75,0.87,0.71,0.48,0.58,0.81,0.78,0.82,0.46,0.81,0.65,1,0.85,0.69,0.77,0.67,0.75,0.85,0.54,0.9,0.45,0.88,0.95,0.38,0.57,0.99,1,0.89,0.61,0.71,0.49,0.68,0.87,0.62,0.57,0.74,0.88,0.89,0.56,0.48,1,0.47,0.809,44.961,55.577,41.08,42.991,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.73,0.49,0.8,0.83,0.55,0.67,0.57,0.76,0.89,0.8,0.95,0.57,0.96,0.61,0.5,0.64,0.77,0.79,0.77,0.8,0.92,0.44,0.55,0.71,0.6,0.83,0.63,1,0.42,0.62,0.8,0.72,0.82,0.78,0.86,0.87,0.92,0.91,0.59,0.83,0.62,0.64,0.98,0.3,0.83,0.58,0.82,0.48,0.93,0.3,0.71,0.95,0.82,0.41,0.69,0.94,0.54,0.63,0.55,0.73,0.86,0.75,0.72,0.93,0.67,0.41,0.57,0.92,0.4,0.83,0.74,0.97,0.76,0.91,0.75,0.44,0.87,1,0.8,0.74,0.91,0.25,0.52,0.72,1,0.6,0.82,0.55,0.54,0.73,0.75,0.72,0.56,0.92,0.29,0.78,0.64,0.64,0.83,0.56,0.49,0.74,0.73,0.72,0.53,0.59,0.69,0.87,0.54,0.66,0.75,0.74,0.39,0.75,0.81,0.53,0.83,0.65,0.61,0.41,0.64,0.73,0.49,0.65,0.39,0.49,0.42,0.53,0.79,0.81,0.65,0.72,0.63,0.52,0.54,0.93,0.71,0.59,0.45,0.62,0.8,0.47,0.89,0.9,0.61,0.82,0.64,0.93,0.91,0.72,0.65,0.59,0.71,0.52,0.84,0.85,0.62,0.58,0.56,0.47,0.68,0.56,0.37,0.62,0.71,0.99,0.35,0.71,0.69,0.86,0.87,0.67,0.94,0.63,0.85,0.9,0.53,0.24,0.78,0.58,0.5,0.98,0.99,0.53,0.83,0.8,0.47,0.74,0.91,0.74,0.98,0.75,0.98,0.86,0.85,0.54,0.46,0.71,0.86,0.93,0.8,0.36,0.65,0.61,0.58,0.62,0.628,23.993,10.735,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.67,0.82,0.78,0.66,0.93,0.34,0.57,0.75,0.75,0.81,0.65,0.86,0.73,0.75,0.79,0.88,0.49,0.42,0.56,0.55,0.55,0.95,0.8,0.82,0.75,0.66,0.71,0.84,0.76,0.94,0.56,0.74,0.97,0.54,0.67,0.79,0.44,0.53,0.81,0.53,0.56,0.6,0.79,0.84,0.51,0.47,0.52,0.78,0.84,0.71,0.47,0.77,0.76,0.74,0.73,0.81,0.77,0.95,0.94,0.37,0.74,0.68,0.8,0.77,0.84,0.52,0.83,0.87,0.79,0.65,0.77,0.87,0.59,0.41,0.91,0.48,0.85,0.67,0.77,0.79,0.76,0.72,0.67,0.73,0.49,0.64,0.99,0.68,0.69,0.53,0.5,0.6,0.51,0.69,0.7,0.77,0.69,0.52,0.65,0.84,0.65,0.59,0.88,0.83,0.62,0.55,0.88,0.62,0.93,0.64,0.76,0.77,0.71,0.97,0.9,0.36,0.86,0.17,0.58,0.83,0.89,0.78,0.78,0.52,0.65,0.58,0.7,0.31,0.93,0.97,0.77,0.88,0.58,0.85,0.71,0.77,0.83,0.47,0.62,0.75,0.63,0.81,0.62,0.83,0.5,0.71,0.71,0.48,0.77,0.94,0.88,0.78,0.57,0.43,0.42,0.52,0.41,0.59,0.71,0.34,0.84,0.82,0.84,0.95,0.94,0.84,0.64,0.38,0.71,0.56,0.66,0.71,0.8,0.61,0.88,0.86,0.74,0.98,1,0.79,0.84,0.78,0.9,0.8,0.89,0.4,0.44,0.72,0.94,0.76,0.76,0.83,0.68,0.97,0.4,0.74,0.65,0.59,0.7,0.66,0.79,0.5,0.7,0.39,0.44,0.94,0.771,34.692,31.463,25.639,3.029,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.97,0.59,0.83,0.81,0.51,0.76,0.45,0.88,0.83,0.87,0.78,0.96,0.74,0.83,0.66,0.74,0.68,0.67,0.78,0.64,0.45,0.52,0.68,0.51,0.85,0.97,0.6,0.69,0.99,0.98,1,0.72,0.68,0.71,0.69,0.41,0.45,0.74,1,0.4,0.55,0.9,0.82,0.93,0.98,0.78,0.88,0.69,0.72,0.75,0.61,0.88,0.8,0.44,0.79,0.44,0.62,0.78,0.87,0.89,0.56,0.87,0.69,0.81,0.76,0.75,0.75,0.83,0.66,0.43,0.75,0.77,0.89,0.64,0.78,0.72,0.67,0.61,0.73,0.64,0.91,1,0.82,0.82,0.81,0.58,0.62,0.81,0.52,0.87,0.86,0.8,0.96,0.86,0.74,0.67,0.68,0.9,0.94,0.74,0.62,0.82,0.89,0.55,0.75,0.6,0.92,0.75,0.78,0.69,0.53,0.82,0.54,0.95,0.54,0.68,0.41,0.79,0.82,0.64,0.72,0.96,0.9,0.84,0.89,0.66,0.73,0.54,0.86,0.73,0.8,0.67,0.63,0.77,0.86,0.54,0.38,0.89,0.92,0.5,0.39,0.62,0.88,0.87,0.76,0.51,0.77,0.81,0.84,0.83,0.71,0.48,0.78,0.63,0.71,0.63,0.99,0.68,0.39,0.58,0.94,0.87,0.49,0.83,0.66,0.76,0.51,0.71,0.49,0.67,0.7,0.79,0.94,0.61,0.76,0.37,0.8,0.83,0.56,0.73,0.88,1,0.66,0.88,0.74,0.92,0.7,0.69,0.78,0.79,0.41,0.6,0.73,0.73,0.92,0.77,0.7,0.54,0.4,1,0.51,0.5,0.94,0.59,0.87,0.81,0.866];
%     BestCost=24239363221.0283;
    bestXTimeScen{OptScenarioNum}=bestXTime
    bestXBuyScen{OptScenarioNum}=bestXBuy
    BestCostScen{OptScenarioNum}=BestCost
    ZoneStartDate=[];
    a=1;
    for n = 1:NumTask
        datestart = LDT+round(bestXTime(n));
        ZoneStartDate=[ZoneStartDate datestart];
    end



    %%%%create ifc file
    [MainIFCFile,path]=uigetfile('*.ifc');
    address =string(path)+ string(MainIFCFile);
    ifcmain = fopen(address,'rt');
    lineofmainIFC = textscan(ifcmain, '%s', 'delimiter', '\n');
    fclose(ifcmain);
    last_line  = textscan(lineofmainIFC{1}{end-3},'%s', 'delimiter', '=');
    LastHashtagNumb=str2double(last_line{1}{1}(2:end));
    IFCwithTimeLine = fopen("IFCwithTimeDataScenario"+OptScenarioNum+".ifc",'w');
    for l = 1:numel(lineofmainIFC{1})-3
        fprintf(IFCwithTimeLine,'%s\n',lineofmainIFC{1}{l});
    end

    templastlineNum= LastHashtagNumb;
    TaskLineNumber=[];
    for n= 1:NumTask
        startdd=day(ZoneStartDate(n));
        startmm=month(ZoneStartDate(n));
        startyy=year(ZoneStartDate(n));
        enddd=day(ZoneStartDate(n)+D(n)-1);
        endmm=month(ZoneStartDate(n)+D(n)-1);
        endyy=year(ZoneStartDate(n)+D(n)-1);
        %start date
        fprintf(IFCwithTimeLine,'#%d= IFCCALENDARDATE(%d,%d,%d);\n',templastlineNum+1,startdd,startmm,startyy);
        fprintf(IFCwithTimeLine,'#%d= IFCLOCALTIME(8,0,$,$,$);\n',templastlineNum+2);
        fprintf(IFCwithTimeLine,'#%d= IFCDATEANDTIME(#%d,#%d);\n',templastlineNum+3,templastlineNum+1,templastlineNum+2);
        %end date
        fprintf(IFCwithTimeLine,'#%d= IFCCALENDARDATE(%d,%d,%d);\n',templastlineNum+4,enddd,endmm,endyy);
        fprintf(IFCwithTimeLine,'#%d= IFCLOCALTIME(17,0,$,$,$);\n',templastlineNum+5);
        fprintf(IFCwithTimeLine,'#%d= IFCDATEANDTIME(#%d,#%d);\n',templastlineNum+6,templastlineNum+4,templastlineNum+5);
        %define task
        txtTask="'Construct Zone "+n+"'";
        fprintf(IFCwithTimeLine,'#%d= IFCTASK($,$,%s,$,$,%s,$,$,.F.,$);\n',templastlineNum+7,txtTask,"'"+n+"'");
        TaskLineNumber(n)=templastlineNum+7;
        fprintf(IFCwithTimeLine,'#%d= IFCSCHEDULETIMECONTROL($,$,$,$,$,$,$,$,#%d,$,$,$,#%d,$,$,$,$,$,$,$,$,$,$);\n',templastlineNum+8,templastlineNum+3,templastlineNum+6);

        if Predecessors{n}{1}=="Nothing"
            lenPred=0;
        else
            lenPred=numel(Predecessors{n});
            for p=1:numel(Predecessors{n})
                temp=textscan(Predecessors{n}{p},'%s','Delimiter',',');
                taskID=str2num((temp{1}{1}));
                rel=temp{1}{2};
                lag=str2num(temp{1}{3});
                if rel=="FS"
                    fprintf(IFCwithTimeLine,'#%d= IFCRELSEQUENCE($,$,$,$,#%d,#%d,%d,.FINISH_START.);\n',templastlineNum+8+p,TaskLineNumber(taskID),TaskLineNumber(n),lag*24*60*60);
                elseif rel=="SS"
                    fprintf(IFCwithTimeLine,'#%d= IFCRELSEQUENCE($,$,$,$,#%d,#%d,%d,.START_START.);\n',templastlineNum+8+p,TaskLineNumber(taskID),TaskLineNumber(n),lag*24*60*60);
                elseif rel=="FF"
                    fprintf(IFCwithTimeLine,'#%d= IFCRELSEQUENCE($,$,$,$,#%d,#%d,%d,.FINISH_FINISH.);\n',templastlineNum+8+p,TaskLineNumber(taskID),TaskLineNumber(n),lag*24*60*60);
                elseif rel=="SF"
                    fprintf(IFCwithTimeLine,'#%d= IFCRELSEQUENCE($,$,$,$,#%d,#%d,%d,.START_FINISH.);\n',templastlineNum+8+p,TaskLineNumber(taskID),TaskLineNumber(n),lag*24*60*60);
                end
            end
        end

        fprintf(IFCwithTimeLine,'#%d= IFCRELASSIGNSTASKS($,$,$,$,(#%d),$,$,#%d);\n',templastlineNum+lenPred+9,TaskLineNumber(n),templastlineNum+8);
        %define object to task
        objectInZone="";
        for i = 1:numel(ElementInZone{n})
            if i == 1
                objectInZone=ElementInZone{n}{i};
            else
                objectInZone=objectInZone+","+ElementInZone{n}{i};
            end
        end
        fprintf(IFCwithTimeLine,'#%d= IFCRELASSIGNSTOPROCESS($,$,$,$,(%s),$,#%d,$);\n',templastlineNum+lenPred+10,objectInZone,TaskLineNumber(n));
        templastlineNum = templastlineNum+lenPred+10;
    end
    for l = numel(lineofmainIFC{1})-2:numel(lineofmainIFC{1})
        fprintf(IFCwithTimeLine,'%s\n',lineofmainIFC{1}{l});
    end
    fclose(IFCwithTimeLine);

    %%%%%%%%%%%%%%%%%%%%
    
    
    %Mizane Kharid Mat m dar roze t 
    DQ=zeros(NumMaterial,Duration);
    BQ1=zeros(NumMaterial,Duration);
    BQ2=zeros(NumMaterial,Duration);
    for m = 1:NumMaterial
        for t = 1:Duration
            BQ1(m,t) = bestXBuy((((2*m)+1-3)*(Duration))+t)*1000*(bestXBuy((((2*m)+2-3)*(Duration))+t));
            BQ2(m,t) = bestXBuy((((2*m)+1-3)*(Duration))+t)*1000*(1-bestXBuy((((2*m)+2-3)*(Duration))+t));
        end   
    end
    
    for m=1:NumMaterial
        for t= 1:Duration
            if t-MatPro{m}{4}>=0
                DQ(m,t)= DQ(m,t) + BQ1(m,t-MatPro{m}{4}+1) + BQ2(m,t-MatPro{m}{4}+1);
            end
        end
    end

    MRP = zeros(NumMaterial,Duration);
    Q=[];
    for t = 1:Duration
    % dar har roz yek matrix q ba tedad satre barabar ba material va sotone
    % barabar ba tedad failat ha ijad mikonim ta mizane morede niaz material
    % moshakhas shavad
        Q{t}=zeros(NumMaterial,NumTask);
        for n = 1:NumTask
            if (bestXTime(n)<=t) && (t<=bestXTime(n)+D(n)-1)
                for m = 1:NumMaterial
                    Q{t}(m,n) = Q{t}(m,n) + UQ(m,n)* MatPro{m}{9};
                end
            end 
        end
        for m = 1:NumMaterial
           for n = 1:NumTask
               MRP(m,t) = MRP(m,t) + Q{t}(m,n);
           end
        end
    end
    SQ=zeros(NumMaterial,Duration);
    
    for m = 1:NumMaterial
        for t = 1:Duration
             if t==1
                 SQ(m,t) = MatPro{m}{3} + (DQ(m,t)/ MatPro{m}{9});
             else
                 SQ(m,t) = SQ(m,t-1) + (DQ(m,t)/MatPro{m}{9}) - (MRP(m,t-1)/MatPro{m}{9});
             end     
        end
    end

   
    OC=zeros(NumMaterial,Duration);
    
    for t =1:Duration
        for m = 1:NumMaterial
            UnitPriceP1 = 0;
            UnitPriceP1Find = 0;
            UnitPriceP21 = 0;
            UnitPriceP21Find = 0;
            UnitPriceP22 = 0;
            UnitPriceP22Find = 0;
            RateAtT0 = 0;
            RateAtDelta = 0;

            for i = 1:numel(MatCost{m})
                if (UnitPriceP1Find == 0)&&(MatCost{m}{i}{1} <= BQ1(m,t)) && (MatCost{m}{i}{2} >= BQ1(m,t))&& (BQ1(m,t)>0)
                    UnitPriceP1 = MatCost{m}{i}{3}; 
                    UnitPriceP1Find = 1;
                end
                if (UnitPriceP21Find == 0)&&(MatCost{m}{i}{1} <= BQ2(m,t)) && (MatCost{m}{i}{2} >= BQ2(m,t))&&(BQ2(m,t)>0)
                    UnitPriceP21 = MatCost{m}{i}{4}; 
                    RateAtT0 = MatCost{m}{i}{5};
                    UnitPriceP21Find = 1;
                end
           
                if (UnitPriceP22Find == 0)&&((t - MatPro{m}{5}) > 0) && (MatCost{m}{i}{1} <= BQ2(m,t- MatPro{m}{5})) && (MatCost{m}{i}{2} >= BQ2(m,t- MatPro{m}{5}))&&(BQ2(m,t- MatPro{m}{5})>0)
                    UnitPriceP22 = MatCost{m}{i}{4};
                    RateAtDelta = MatCost{m}{i}{6};
                    UnitPriceP22Find = 1;
                end
                
            end
            if (t - MatPro{m}{5}) > 0
                OC(m,t)=(BQ2(m,t) * UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(t-1))) + (BQ2(m,t- MatPro{m}{5}) *  UnitPriceP22 * RateAtDelta * ((1+MatPro{m}{6})^(t-MatPro{m}{5}-1))) + (BQ1(m,t)  * UnitPriceP1 * ((1+MatPro{m}{6})^(t-1)));
            else
                OC(m,t)=(BQ2(m,t) * UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(t-1))) + (BQ1(m,t) * UnitPriceP1 * ((1+MatPro{m}{6})^(t-1))); 
            end

        end
    end
    DC=zeros(NumMaterial,Duration);
    for t =1:Duration
        for m = 1:NumMaterial
            if DQ(m,t) ~=0
                DeliveryCost = 0;
                for i = 1:numel( MatCost{m})
                    if (MatCost{m}{i}{1} <= DQ(m,t)) && (MatCost{m}{i}{2} >= DQ(m,t))
                        DeliveryCost = MatCost{m}{i}{7};  
                    end
                end
                DC(m,t)= DeliveryCost * ((1+TFR)^(t));
            end
        end
    end

    SC=zeros(NumMaterial,Duration);
    for t =1:Duration
        for m = 1:NumMaterial
            if SQ(m,t)>0
                SC(m,t) = SQ(m,t) * MatPro{m}{7};
            end
        end
    end
    
    if (bestXTime(NumTask)+D(NumTask)) >(days(DDPC-LDT)+1)
        temp_dif_T = string(bestXTime(NumTask)+D(NumTask) - (days(DDPC-LDT)+1));
        temp=textscan(temp_dif_T,'%f');
        Diff = double(temp{1});
        DFP = Diff * DPC;
    else
        DFP=0;
    end

    %part5:mojidi mali
    FI=[];
    for t =1:Duration
        Temp_total_cost_t = 0;
        for m = 1:NumMaterial
            Temp_total_cost_t = Temp_total_cost_t + OC(m,t) + DC(m,t) + SC(m,t) ;
        end
        if t == 1
            FI(t) = B(t) - Temp_total_cost_t;
        elseif t == Duration
            FI(t) = (FI(t-1)*(1)) + B(t) - Temp_total_cost_t - DFP;
        else
            FI(t) = (FI(t-1)*(1)) + B(t) - Temp_total_cost_t;
        end
    end
    
    
    conn= database('DataBase','admin','admin');
    [r c]=size(BQ1);
    for row = 1:r
        for col = 1:c
            if BQ1(row,col)~=0
                data = table([row],[datetime(LDT+days(col))],[BQ1(row,col)],["KG"],'VariableNames',{'IDMaterial','BuyDate','Quantity','Unit'});  
                coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
                sqlwrite(conn,"__BQ1_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);

            end
        end
    end

    
    [r c]=size(BQ2);
    for row = 1:r
        for col = 1:c
            if BQ2(row,col)~=0
                data = table([row],[datetime(LDT+days(col))],[BQ2(row,col)],["KG"],'VariableNames',{'IDMaterial','BuyDate','Quantity','Unit'});  
                coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
                sqlwrite(conn,"__BQ2_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);

            end
        end
    end
    
    
    for n = 1:NumTask
        data = table([n],[ZoneStartDate(n)],'VariableNames',{'IDZone','StartDate'});  
        coltypes = ["INTEGER" "DATE"];
        sqlwrite(conn,"__StartDateZones_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);
    end


    [r c]=size(DQ);
    for row = 1:r
        for col = 1:c
            if DQ(row,col)~=0
                data = table([row],[datetime(LDT+days(col))],[DQ(row,col)],["KG"],'VariableNames',{'IDMaterial','DeliveryDate','Quantity','Unit'});  
                coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
                sqlwrite(conn,"__DQ_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);

            end
        end
    end

    [r c]=size(OC);
    for row = 1:r
        for col = 1:c
            if OC(row,col)~=0
                data = table([row],[datetime(LDT+days(col))],[OC(row,col)],["Toman"],'VariableNames',{'IDMaterial','PaymentDate','Quantity','Unit'});  
                coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
                sqlwrite(conn,"__OC_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);

            end
        end
    end

    [r c]=size(DC);
    for row = 1:r
        for col = 1:c
            if DC(row,col)~=0
                data = table([row],[datetime(LDT+days(col))],[DC(row,col)],["Toman"],'VariableNames',{'IDMaterial','PaymentDate','Quantity','Unit'});  
                coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
                sqlwrite(conn,"__DC_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);

            end
        end
    end

    [r c]=size(SC);
    for row = 1:r
        for col = 1:c
            if SC(row,col)~=0
                data = table([row],[datetime(LDT+days(col))],[SC(row,col)],["Toman"],'VariableNames',{'IDMaterial','PaymentDate','Quantity','Unit'});  
                coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
                sqlwrite(conn,"__SC_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);

            end
        end
    end
    
    [r c]=size(SQ);
    for row = 1:r
        for col = 1:c
                data = table([row],[datetime(LDT+days(col)-1)],[SQ(row,col)],["Cubic_Metre"],'VariableNames',{'IDMaterial','DayDate','Quantity','Unit'});  
                coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
                sqlwrite(conn,"__SQ_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);

           
        end
    end
    
    [r c]=size(MRP);
    for row = 1:r
        for col = 1:c
                data = table([row],[datetime(LDT+days(col)-1)],[MRP(row,col)],["KG"],'VariableNames',{'IDMaterial','DayDate','Quantity','Unit'});  
                coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
                sqlwrite(conn,"__MRP_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);

           
        end
    end
    
    
    for t =1:Duration
        data = table([t],[datetime(LDT+days(t)-1)],[FI(t)],["TOMAN"],'VariableNames',{'ID','DayDate','FinancialBalance','Unit'});  
        coltypes = ["INTEGER" "DATE" "DOUBLE" "LONGTEXT" ];
        sqlwrite(conn,"__FI_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);
    end
    

    close(conn)


end








% 
% %%%Validation
% 
% clc;
% clear;
% close all;
% 
% format short
% digits(4);
% 
% t1=datetime('now');
% global TF OptScenarioNum NumScenario MaxQMat MinQMat WESTask WEFTask WLSTask WLFTask possiblefirstDay TQM lastIndexX Predecessors NumTask ESPC LDT Duration D NumMaterial UQ MatPro ProfSurArea  DDPC MDDP StockLength StockWidth StockHeight StockCost IR TFR OFR DPC MatCost B WCOST WSPACE
% conn= database('DataBase','admin','admin');
% 
% %%Specify the number of "Zones" [NumTask] and the list of Predecessors for each Zone [Predecessors] and the Duration of each Zone [D(n)] from "tblZoneDetails"
% query='select * from tblZoneDetails';
% Data=fetch(conn,query);
% NumTask=numel(Data.ID);
% D=[];
% TF=[];
% WESTask=[];
% WEFTask=[];
% WLSTask=[];
% WLFTask=[];
% for n = 1:NumTask
%     D(Data.ID(n))=Data.Duration(n);
%     WESTask(Data.ID(n))=Data.WES(n);
%     WEFTask(Data.ID(n))=Data.WEF(n);
%     WLSTask(Data.ID(n))=Data.WLS(n);
%     WLFTask(Data.ID(n))=Data.WLF(n);
%     TF(Data.ID(n))=Data.TF(n);
% end
% 
% Predecessors=[];
% for r =1:NumTask
%     n = Data.ID(r);
%     temp=table2array(Data.Predecessors(r));
%     if numel(temp)==0
%          Predecessors{n}{1}="Nothing";
%     else
%         temp_data=textscan(temp,'%s','Delimiter',',');
%         for i =1:numel(temp_data{1})
%             temp=char(temp_data{1}{i});
%             len=numel(temp);
%             PreDone=0;
%             for ii =1:len
%                 if temp(ii)=="+"
%                     TaskID=temp(1:ii-3);
%                     rel=[temp(ii-2),temp(ii-1)];
%                     lag=temp(ii+1:end);
%                     Predecessors{n}{i}=[TaskID];
%                     Predecessors{n}{i}=[Predecessors{n}{i}+","+ rel];
%                     Predecessors{n}{i}=[Predecessors{n}{i}+","+ lag];
%                     PreDone=1;
%                     break
%                 end
%             end
%             if PreDone==0
%                 TaskID=temp(1:len-2);
%                 rel=[temp(len-1),temp(len)];
%                 lag=0;
%                 Predecessors{n}{i}=[TaskID];
%                 Predecessors{n}{i}=[Predecessors{n}{i}+","+ rel];
%                 Predecessors{n}{i}=[Predecessors{n}{i}+","+ lag];
%             end
% %         celldisp(Predecessors)    
%         end
%            
%             
%     end
% end
% %celldisp(Predecessors) 
% 
% 
% %%Determine elements in each zone [ElementInZone] from "ElementInZone"
% ElementInZone=[];
% for i = 1:NumTask
%     ElementInZone{i}=[];
% end
% query='select * from ElementInZone';
% Data=fetch(conn,query);
% tbElInZoneRow = numel(Data.IDZone);
% for i = 1:tbElInZoneRow
%     ElementInZone{Data.IDZone(i)}=[ElementInZone{Data.IDZone(i)} string(Data.LineNumber(i))];
% end
% 
% 
% %%Specify the Land Delivery, ES, Delivery date of project with and without penalty and etc from "tblProjectDetails"
% query='select * from tblProjectDetails';
% Data=fetch(conn,query);
% LDT=datetime(Data.LandDeliveryTime);
% ESPC=datetime(Data.EarliestStartofProjectConstruction);
% DDPC=datetime(Data.DeliveryDateofProjectWithoutPenalty);
% MDDP=datetime(Data.MaxDeliveryDateofProject);
% temp_Duration = string(days(days(MDDP-LDT)+1));
% temp=textscan(temp_Duration,'%f');
% Duration = double(temp{1});
% IR=double(string(Data.DailyInterestRate));
% TFR=double(string(Data.DailyTransportationTnflationRate(1)));
% OFR=double(string(Data.DailyOverallInflationRate));
% DPC=double(string(Data.DelayedPenaltyCost));
% 
% 
% %%Specify Material data [MatPro] from "tblMaterialData"
% MatPro=[];
% query='select * from tblMaterialData';
% Data=fetch(conn,query);
% NumMaterial=numel(Data.ID);
% for n = 1:NumMaterial
%     MatPro{Data.ID(n)}{1}=Data.ID(n);
%     MatPro{Data.ID(n)}{2}=table2array(Data.MaterialName(n));
%     MatPro{Data.ID(n)}{3}=Data.InitialInventory(n);
%     MatPro{Data.ID(n)}{4}=Data.DeliveryPeriods(n);
%     MatPro{Data.ID(n)}{5}=Data.InstallmentPeriod(n);
%     MatPro{Data.ID(n)}{6}=Data.DailyInflationRate(n);
%     MatPro{Data.ID(n)}{7}=Data.MaintenanceCost(n);
%     MatPro{Data.ID(n)}{8}=table2array(Data.ProfileName(n));
%     MatPro{Data.ID(n)}{9}=Data.SpecificWeight(n);
%     MatPro{Data.ID(n)}{10}=Data.WidthOfOneUnit(n);
%     MatPro{Data.ID(n)}{11}=Data.HeightOfOneUnit(n);
%     MatPro{Data.ID(n)}{12}=Data.LengthOfOneUnit(n);
%     
% end
% 
% %%Specify data of buying cost, delivery cost and etc from "tblMaterialUnitCost"
% MatCost=[];
% query='select * from tblMaterialUnitCost';
% Data=fetch(conn,query);
% tbMAtCostRow = numel(Data.IDofMaterial);
% MaxQMat=[];
% for n = 1:NumMaterial
%     i = 0;
%     for row = 1:tbMAtCostRow
%         if Data.IDofMaterial(row) == n
%            i = i + 1;
%            MatCost{n}{i}{1} = Data.MinOrderQuantity(row);
%            MatCost{n}{i}{2} = Data.MaxOrderQuantity(row);
%            MatCost{n}{i}{3} = Data.CostperUnitInCashPurchase(row);
%            MatCost{n}{i}{4} = Data.CostperUnitInInstallmentPurchase(row);
%            MatCost{n}{i}{5} = Data.PayRateT0(row);
%            MatCost{n}{i}{6} = Data.PayRateT0plusDelta(row);
%            MatCost{n}{i}{7} = Data.DeliveryCost(row);
%         end
%     end
%     for ii = 1:i
%         if ii==1
%             MinQMat{n} =  MatCost{n}{ii}{1};
%             MaxQMat{n} =  MatCost{n}{ii}{1};
%         end
%         if MatCost{n}{ii}{1} < MinQMat{n}
%             MinQMat{n}=MatCost{n}{ii}{1};
%         end
%         if MatCost{n}{ii}{2}> MaxQMat{n}
%              MaxQMat{n}=MatCost{n}{ii}{2};
%         end
%     end
%             
% end
% 
% 
% %%Specify Daily Material requirments of each zone [] from "QTOforZones"
% %fingilsh: etelat dar yek matrix ba radife barabar ba NumMaterial va sotone barabar ba NumTask
% UQ=zeros(NumMaterial,NumTask);
% query='select * from QTOforZones';
% Data=fetch(conn,query);
% RowQTO=numel(Data.IDZone);
% for i = 1:RowQTO
%     UQ(Data.IDMaterial(i),Data.IDZone(i))= Data.DailyVolumeConsumption(i);
% end
% 
% 
% 
% %%Specify Financial data such az input value and the date of that from "tblInputCash"
% query='select * from tblInputCash';
% Data=fetch(conn,query);
% RowInputCash=numel(Data.Number);
% B=zeros(1,Duration);
% for i = 1:RowInputCash
%     if datetime(Data.Date(i)) == LDT
%         temp_T=1;
%     else
%         Temp_Date = string(days(datetime(Data.Date(i)) - LDT));
%         temp=textscan(Temp_Date,'%f');
%         temp_T =  double(temp{1}); 
%     end
% 
%     B(temp_T) =Data.InputCash(i);
% end
% %%specify Storage Dim for each scenario from "tblStorageDimension"
% query='select * from tblStorageDimension';
% Data=fetch(conn,query);
% NumScenario=max(Data.Scenario);
% RowStorageTbl=numel(Data.Scenario);
% StockLength =[];
% StockWidth =[];
% StockHeight =[];
% StockCost =[];
% for i = 1:RowStorageTbl
%     StockLength{Data.Scenario(i)}{Data.IDMaterial(i)}=Data.Length(i);
%     StockWidth{Data.Scenario(i)}{Data.IDMaterial(i)}=Data.Width(i);
%     StockHeight{Data.Scenario(i)}{Data.IDMaterial(i)}=Data.MaxHeight(i);
%     StockCost{Data.Scenario(i)}{Data.IDMaterial(i)}=Data.SettingUpCost(i);
% end
% 
% %%%Determine the Surface area of each profile from "totalQTO"
% query='select * from totalQTO';
% Data=fetch(conn,query);
% RowTQTO=numel(Data.IDMaterial);
% ProfSurArea=[];
% for r = 1:RowTQTO
%     if MatPro{r}{8}(1:2)=="PL"
%         lenNamePro=numel(MatPro{r}{8});
%         th=str2double(MatPro{r}{8}(3:lenNamePro));
%         ProfSurArea(Data.IDMaterial(r))= th*MatPro{r}{10}/1000;
%     else
%         ProfSurArea(Data.IDMaterial(r))= Data.SurfaceArea(r);
%     end
% end
% 
% query='select * from QTOforZones';
% Data=fetch(conn,query);
% RowQTO=numel(Data.IDZone);
% TQM=zeros(1,NumMaterial);
% for i = 1:RowQTO
%     TQM(Data.IDMaterial(i))= TQM(Data.IDMaterial(i))+ Data.TotalVolumeConsumption(i);
% end
% 
% close(conn);
% 
% temp_firstday = string(days(days(ESPC-LDT)+1));
% temp=textscan(temp_firstday,'%f');
% possiblefirstDay = double(temp{1});
% ES=zeros(NumTask,1);
% %%%calculate ES of tasks
% for n = 1:NumTask
%     tempList=[];
%     if isnan(WESTask(n))==0
%         tempList = [tempList;WESTask(n)];
%     end
% 
%     if isnan(WEFTask(n))==0
%         tempList = [tempList;WEFTask(n)-D(n)+1];
%     end
%     if Predecessors{n}{1}=="Nothing"
%         %x(n)>= ESPC;
%         %x(n)+D(n) <= MDDP;
%         tempList = [tempList;possiblefirstDay];
%         
%     else
%         for p=1:numel(Predecessors{n})
%             temp=textscan(Predecessors{n}{p},'%s','Delimiter',',');
%             taskID=str2double((temp{1}{1}));
%             rel=temp{1}{2};
%             lag=str2double(temp{1}{3});
%             if rel=="FS"
%                 %x(n) >= x(taskID) + D(taskID) + lag;
%                 %x(n)+D(n) <= MDDP;
%                 %x(n)>= ESPC;
%                 tempList=[tempList;ES(taskID) + D(taskID)];
%             elseif rel=="SS"
%                 %x(n) >= x(taskID) + lag;
%                 %x(n)+D(n) <= MDDP;
%                 %x(n)>= ESPC;
%                 tempList=[tempList;ES(taskID) + lag];
%             elseif rel=="FF"
%                 %x(n) >= x(taskID) + D(taskID) + lag - D(n);
%                 %x(n)+D(n) <= MDDP;
%                 %x(n)>= ESPC;
%                 tempList=[tempList;ES(taskID) + D(taskID) + lag - D(n)];
%             elseif rel=="SF"
%                 %x(n) >= x(taskID) + lag - D(n);
%                 %x(n)+D(n) <= MDDP;
%                 %x(n)>= ESPC;
%                 tempList=[tempList;ES(taskID) + lag - D(n)+1];
%             end
%         end
%     end
% 
%     ES(n)=max(tempList);
%     
% end
% %%%
% 
% 
% 
% 
% nvars=NumTask;
% 
% %UB AND LB OF ZONE START
% LB = [];   % Lower bound
% UB = [];   % Upper bound
% 
% 
% 
% for n = 1:NumTask
%    LB=[LB ES(n)];
%    UB=[UB ES(n)+TF(n)];
% end
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% 
% 
% 
% 
% 
% 
% %% Problem Definition
% 
% 
% 
% nVar = nvars;            % Number of Decision Variables
% 
% VarSize = [1 nVar];   % Size of Decision Variables Matrix
% 
% VarMin = LB;         % Lower Bound of Variables
% VarMax = UB;         % Upper Bound of Variables
% 
% 
% %% PSO Parameters
% 
% MaxIt = 1;      % Maximum Number of Iterations
% 
% nPop = 1;        % Population Size (Swarm Size)
% 
% % PSO Parameters
% w = 1;            % Inertia Weight
% wdamp = 0.99;     % Inertia Weight Damping Ratio
% c1 = 1.5;         % Personal Learning Coefficient
% c2 = 2.0;         % Global Learning Coefficient
% 
% % If you would like to use Constriction Coefficients for PSO, 
% % uncomment the following block and comment the above set of parameters.
% 
% % % Constriction Coefficients
% % phi1 = 2.05;
% % phi2 = 2.05;
% % phi = phi1+phi2;
% % chi = 2/(phi-2+sqrt(phi^2-4*phi));
% % w = chi;          % Inertia Weight
% % wdamp = 1;        % Inertia Weight Damping Ratio
% % c1 = chi*phi1;    % Personal Learning Coefficient
% % c2 = chi*phi2;    % Global Learning Coefficient
% 
% % Velocity Limits
% % VelMax = 0.1*(VarMax-VarMin);
% % VelMin = -VelMax;
% % 
% %% Initialization
% 
% empty_particle.Position = [];
% empty_particle.BuyQ = [];
% empty_particle.Cost = [];
% empty_particle.Velocity = [];
% empty_particle.Best.Position = [];
% empty_particle.Best.Cost = [];
% empty_particle.Best.BuyQ = [];
% 
% particle = repmat(empty_particle, nPop, 1);
% 
% GlobalBest.Cost = inf;
%  for OptScenarioNum = 1:1
%     CostFunction = @(x) CostTime(x,MaxQMat,NumTask,LDT,Duration,D,NumMaterial,UQ,MatPro,DDPC,TFR,OFR,DPC,MatCost,OptScenarioNum, WESTask ,WEFTask ,WLSTask ,WLFTask ,TQM ,Predecessors,StockLength ,StockWidth ,StockHeight,B,ProfSurArea);     % Cost Function
% %     
% %     for i = 1:nPop
% %         % Initialize Position
% % %         for n = 1:nVar
% % %             if n==1
% % %                 particle(i).Position(n)=randi([LB(n),(UB(n))]);
% % %             else
% % %                 tempList=[];
% % %                 if isnan(WESTask(n))==0
% % %                     tempList = [tempList;WESTask(n)];
% % %                 end
% % % 
% % %                 if isnan(WEFTask(n))==0
% % %                     tempList = [tempList;WEFTask(n)-D(n)+1];
% % %                 end
% % %                 if Predecessors{n}{1}=="Nothing"
% % %                     %x(n)>= ESPC;
% % %                     %x(n)+D(n) <= MDDP;
% % %                     tempList = [tempList;possiblefirstDay];
% % % 
% % %                 else
% % %                     for p=1:numel(Predecessors{n})
% % %                         temp=textscan(Predecessors{n}{p},'%s','Delimiter',',');
% % %                         taskID=str2double((temp{1}{1}));
% % %                         rel=temp{1}{2};
% % %                         lag=str2double(temp{1}{3});
% % %                         if rel=="FS"
% % %                             %x(n) >= x(taskID) + D(taskID) + lag;
% % %                             %x(n)+D(n) <= MDDP;
% % %                             %x(n)>= ESPC;
% % %                             tempList=[tempList;particle(i).Position(taskID) + D(taskID)];
% % %                         elseif rel=="SS"
% % %                             %x(n) >= x(taskID) + lag;
% % %                             %x(n)+D(n) <= MDDP;
% % %                             %x(n)>= ESPC;
% % %                             tempList=[tempList;particle(i).Position(taskID) + lag];
% % %                         elseif rel=="FF"
% % %                             %x(n) >= x(taskID) + D(taskID) + lag - D(n);
% % %                             %x(n)+D(n) <= MDDP;
% % %                             %x(n)>= ESPC;
% % %                             tempList=[tempList;particle(i).Position(taskID) + D(taskID) + lag - D(n)];
% % %                         elseif rel=="SF"
% % %                             %x(n) >= x(taskID) + lag - D(n);
% % %                             %x(n)+D(n) <= MDDP;
% % %                             %x(n)>= ESPC;
% % %                             tempList=[tempList;particle(i).Position(taskID) + lag - D(n)+1];
% % %                         end
% % %                     end
% % %                 end
% % % 
% % %                 ES=max(tempList);
% % %                 particle(i).Position(n)=randi([ES,(UB(n))]);
% % %             end
% % %         end
% %         % Initialize Velocity
%         particle(i).Position = [12,24,24,32,32,32,37,41,53,53,61,61,61,66,80,95,95,105,105,105,113,130,138,138,143,143,143,147,150,158,158,163,163,163,167,175,183,183,188,188,188,192];
%         particle(i).Velocity = zeros(VarSize);
%         % Evaluation
%         CostWithBuy=CostFunction(particle(i).Position);
%         particle(i).Cost = cell2mat(CostWithBuy(1));
%         particle(i).BuyQ = CostWithBuy(2);
% 
%         % Update Personal Best
%         particle(i).Best.Position = particle(i).Position;
%         particle(i).Best.Cost = particle(i).Cost;
%         particle(i).Best.BuyQ = particle(i).BuyQ;
% 
% 
%         % Update Global Best
%         if particle(i).Best.Cost<GlobalBest.Cost
% 
%             GlobalBest = particle(i).Best;
% 
%         end
% 
%     %end
% 
% %     BestCost = zeros(MaxIt, 1);
% % 
% % 
% %     %% PSO Main Loop
% % 
% % %     for it = 1:MaxIt
% % % 
% % %         for i = 1:nPop
% % % 
% % %             % Update Velocity
% % %             particle(i).Velocity = round(w*particle(i).Velocity ...
% % %                 +c1*rand(VarSize).*(particle(i).Best.Position-particle(i).Position) ...
% % %                 +c2*rand(VarSize).*(GlobalBest.Position-particle(i).Position));
% % % 
% % %             % Apply Velocity Limits
% % %             particle(i).Velocity = max(particle(i).Velocity, VelMin);
% % %             particle(i).Velocity = min(particle(i).Velocity, VelMax);
% % % 
% % %             % Update Position
% % %             particle(i).Position = round(particle(i).Position + particle(i).Velocity);
% % % 
% % %             % Velocity Mirror Effect
% % %             IsOutside = (particle(i).Position<VarMin | particle(i).Position>VarMax);
% % %             particle(i).Velocity(IsOutside) = -particle(i).Velocity(IsOutside);
% % % 
% % %             % Apply Position Limits
% % %             for n= 1:nVar
% % %                 if n==1
% % %                     particle(i).Position(n) = max(particle(i).Position(n), VarMin(n));
% % %                     particle(i).Position(n) = min(particle(i).Position(n), VarMax(n));
% % %                 else
% % %                     tempList=[];
% % %                     if isnan(WESTask(n))==0
% % %                         tempList = [tempList;WESTask(n)];
% % %                     end
% % % 
% % %                     if isnan(WEFTask(n))==0
% % %                         tempList = [tempList;WEFTask(n)-D(n)+1];
% % %                     end
% % %                     if Predecessors{n}{1}=="Nothing"
% % %                         %x(n)>= ESPC;
% % %                         %x(n)+D(n) <= MDDP;
% % %                         tempList = [tempList;possiblefirstDay];
% % % 
% % %                     else
% % %                         for p=1:numel(Predecessors{n})
% % %                             temp=textscan(Predecessors{n}{p},'%s','Delimiter',',');
% % %                             taskID=str2double((temp{1}{1}));
% % %                             rel=temp{1}{2};
% % %                             lag=str2double(temp{1}{3});
% % %                             if rel=="FS"
% % %                                 %x(n) >= x(taskID) + D(taskID) + lag;
% % %                                 %x(n)+D(n) <= MDDP;
% % %                                 %x(n)>= ESPC;
% % %                                 tempList=[tempList;particle(i).Position(taskID) + D(taskID)];
% % %                             elseif rel=="SS"
% % %                                 %x(n) >= x(taskID) + lag;
% % %                                 %x(n)+D(n) <= MDDP;
% % %                                 %x(n)>= ESPC;
% % %                                 tempList=[tempList;particle(i).Position(taskID) + lag];
% % %                             elseif rel=="FF"
% % %                                 %x(n) >= x(taskID) + D(taskID) + lag - D(n);
% % %                                 %x(n)+D(n) <= MDDP;
% % %                                 %x(n)>= ESPC;
% % %                                 tempList=[tempList;particle(i).Position(taskID) + D(taskID) + lag - D(n)];
% % %                             elseif rel=="SF"
% % %                                 %x(n) >= x(taskID) + lag - D(n);
% % %                                 %x(n)+D(n) <= MDDP;
% % %                                 %x(n)>= ESPC;
% % %                                 tempList=[tempList;particle(i).Position(taskID) + lag - D(n)+1];
% % %                             end
% % %                         end
% % %                     end
% % %                     ES=max(tempList);
% % %                     particle(i).Position(n) = max(particle(i).Position(n), ES);
% % %                     particle(i).Position(n) = min(particle(i).Position(n), VarMax(n));
% % % 
% % % 
% % %                 end
% % %             end
% % %                 % Evaluation
% % %             
% % %             CostWithBuy=CostFunction(particle(i).Position);
% % %             particle(i).Cost = cell2mat(CostWithBuy(1));
% % %             particle(i).BuyQ = CostWithBuy(2);
% % % 
% % %             % Update Personal Best
% % %             if particle(i).Cost<particle(i).Best.Cost
% % % 
% % %                 particle(i).Best.Position = particle(i).Position;
% % %                 particle(i).Best.Cost = particle(i).Cost;
% % %                 particle(i).Best.BuyQ = particle(i).BuyQ;
% % % 
% % %                 % Update Global Best
% % %                 if particle(i).Best.Cost<GlobalBest.Cost
% % % 
% % %                     GlobalBest = particle(i).Best;
% % % 
% % %                 end
% % % 
% % %             end
% % % 
% %  %        end
% % 
% %         BestCost(it) = GlobalBest.Cost;
% % 
% %         disp(['IterationTime ' num2str(it) ': Best Cost = ' num2str(BestCost(it))]);
% % 
% %         w = w*wdamp;
% % 
% %       end
% % 
% %     BestSol = GlobalBest;
% % 
% % 
% %     %% Results
% % 
% % %     figure;
% % %     %plot(BestCost, 'LineWidth', 2);
% % %     semilogy(BestCost, 'LineWidth', 2);
% % %     xlabel('Iteration');
% % %     ylabel('Best Cost');
% % %     grid on;
% %     
% %     %bestX=[BestSol.Position,BestSol.BuyQ];
%     bestXTime=GlobalBest.Position;
%     bestXBuy=GlobalBest.BuyQ{1};
%     BestCost=GlobalBest.Cost;
% %     bestXTime=[16,32,32,40,40,40,45,51,68,69,77,77,77,82,90,109,109,119,119,120,127,132,143,144,150,149,151,154,161,169,171,176,177,176,180,188,196,196,201,202,201,205];
% %     bestXBuy=[32.966,75.567,62.572,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.87,0.92,1,0.89,0.6,0.91,0.71,1,0.71,0.82,0.4,0.8,0.87,0.8,0.64,0.75,0.66,0.76,0.78,0.66,0.68,0.91,0.81,0.45,0.66,0.59,0.6,0.55,0.89,0.87,0.81,0.84,1,0.74,0.7,0.71,0.66,0.49,0.96,0.83,0.63,0.56,0.79,0.48,0.45,0.93,0.44,0.82,0.91,0.84,0.79,0.54,0.48,0.91,0.85,0.83,0.75,0.59,0.89,0.97,0.78,0.8,0.97,0.58,0.55,0.95,0.85,0.6,0.74,0.53,0.98,0.64,0.8,0.82,0.52,0.74,0.47,0.39,0.85,0.44,0.77,0.64,0.91,0.82,0.61,0.7,0.92,0.93,0.96,0.79,0.91,0.66,0.46,0.69,0.73,0.72,0.91,0.87,0.56,0.62,0.54,0.55,0.55,0.64,0.86,0.8,0.83,0.68,0.74,0.7,0.68,0.59,0.85,0.55,0.77,0.35,0.89,0.62,0.89,0.58,0.74,0.62,0.6,0.61,0.93,0.64,0.92,0.37,0.61,0.66,0.86,0.54,0.89,0.82,0.59,0.74,0.53,0.69,0.64,0.88,0.87,0.53,0.57,0.54,0.9,0.8,0.43,0.9,0.4,0.73,0.83,0.64,0.6,0.61,0.61,0.42,0.78,0.55,0.77,0.85,0.73,0.99,0.49,0.81,0.95,0.77,0.34,0.44,0.65,0.67,0.8,0.93,0.65,0.57,0.8,0.65,1,0.53,0.94,0.48,0.4,0.89,0.89,0.64,0.89,0.82,0.78,0.56,0.7,0.88,0.63,0.9,0.61,0.9,0.49,0.56,0.85,0.47,0.88,0.82,0.55,0.84,0.63,0.57,0.41,0.72,0.827,3.85,0.457,0,0.58,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1.523,1.54,0.631,0.645,1.275,1.166,0.715,0.625,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.631,0.722,0,1.62,0.55,0.565,0.625,0.793,0.759,0.04,0.04,0.04,0,0.043,0.043,0.045,0.043,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.872,1.152,0.719,1.635,0.991,0.927,0.711,1.69,1.481,0.529,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.009,0.005,0.006,0.006,0,0,0,0,0,0,0,0,0,0,0,0,0,0.247,0.247,0,0,1.797,0.904,0,0.626,1.344,0,0.405,0.472,0.87,0,0,0,0.681,1.843,0.853,1.346,2.265,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.62,0.68,0.8,0.74,0.88,0.99,0.7,0.83,0.79,0.68,0.8,0.78,0.81,0.65,0.89,0.74,0.61,0.87,0.79,0.51,0.87,0.84,0.55,0.69,0.63,0.6,0.67,0.56,0.65,0.8,0.91,0.81,0.8,0.97,0.8,0.66,0.76,0.53,0.9,0.43,0.66,0.56,0.82,0.52,0.77,0.67,0.91,0.81,0.58,0.9,0.8,0.83,0.97,0.71,0.35,0.75,0.85,0.62,0.73,0.55,0.53,0.82,0.88,0.47,0.97,0.7,0.79,0.78,0.76,0.61,0.95,0.9,0.76,0.66,0.86,0.86,0.99,0.93,0.49,0.87,0.9,0.7,0.94,0.82,0.74,0.89,0.58,0.45,0.58,0.45,0.76,0.99,0.38,0.65,0.6,0.89,0.47,0.82,0.57,0.81,0.31,0.61,0.79,0.56,0.91,0.86,0.84,0.67,1,0.9,0.91,0.85,0.48,0.81,0.69,0.79,0.61,0.48,0.61,0.62,0.97,0.69,0.65,0.91,0.67,0.92,0.84,0.75,0.76,0.81,0.53,0.72,0.83,0.34,0.9,0.73,0.64,0.91,0.57,0.68,0.53,0.48,0.64,0.88,0.82,0.72,0.72,0.68,0.67,0.57,0.64,0.7,0.66,0.74,0.56,0.78,0.94,0.71,0.6,0.75,0.85,0.72,0.9,0.66,0.5,0.55,0.79,0.64,0.51,0.41,0.92,0.72,0.5,0.64,0.61,0.71,0.67,0.64,0.98,0.87,0.84,0.86,0.92,0.52,0.77,0.71,0.46,0.51,0.52,0.98,0.76,0.64,0.64,0.46,0.52,0.45,0.54,0.31,0.68,0.88,0.63,0.8,0.56,0.54,0.53,0.62,0.611,23.08,24.835,20.834,10.513,3.382,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.82,0.82,0.61,0.93,0.7,0.96,0.34,0.45,0.66,0.73,0.22,0.77,0.42,0.91,0.87,0.52,0.44,0.75,0.8,0.98,0.62,0.66,0.3,0.91,0.65,0.65,0.25,0.8,0.79,0.92,0.68,0.72,0.82,0.39,0.89,0.72,0.89,0.62,0.79,0.82,0.82,0.55,0.72,0.63,1,0.55,0.66,0.4,0.43,0.98,0.96,0.92,0.67,0.82,0.82,0.53,0.69,0.68,0.82,0.87,0.6,0.98,0.68,0.6,0.37,0.69,0.77,0.28,0.78,0.92,0.76,0.28,0.96,0.49,0.72,0.64,0.79,0.73,0.97,0.86,0.58,0.58,0.57,0.76,0.95,0.82,0.88,0.43,0.8,0.39,0.42,0.92,0.73,0.66,0.85,0.82,0.66,0.58,0.91,0.38,0.95,0.85,0.78,0.78,0.89,0.74,0.31,0.76,0.91,0.86,0.51,0.85,0.98,0.69,0.77,0.42,0.7,0.91,0.98,0.52,0.85,0.71,0.67,0.74,0.65,0.83,0.86,0.85,0.77,0.6,0.8,0.77,0.57,0.74,0.8,0.88,0.55,0.55,0.37,0.82,0.99,0.74,0.76,0.83,0.5,0.55,0.42,1,0.88,0.57,0.71,0.72,0.96,0.81,0.87,0.83,0.71,0.83,0.71,0.67,0.77,0.4,0.79,0.6,0.83,0.84,0.57,0.54,0.85,0.95,0.59,0.88,0.68,0.63,0.79,0.64,0.69,0.89,0.86,0.69,0.6,0.96,0.75,0.43,0.66,0.74,0.68,0.69,0.69,0.53,0.66,0.84,0.72,0.79,0.58,0.65,0.86,0.99,0.78,0.58,0.67,0.94,0.78,0.61,0.84,0.83,0.897,47.001,32.072,4.203,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.82,0.88,0.54,0.64,0.76,0.83,0.87,0.77,0.95,0.59,0.69,0.92,0.83,0.6,0.85,0.88,0.85,0.52,0.96,0.69,0.44,0.82,0.78,0.6,0.86,0.95,0.55,0.63,0.92,0.41,1,0.82,0.69,0.67,0.85,0.79,0.98,0.81,0.86,0.29,0.23,0.8,0.56,0.7,0.75,0.54,0.84,0.79,0.81,0.89,0.74,0.4,0.79,0.59,0.79,0.78,0.71,0.81,0.64,0.73,0.83,0.68,0.68,0.7,0.54,0.6,0.95,0.96,0.53,0.69,0.9,0.42,0.58,0.78,0.8,0.87,0.78,0.63,0.6,0.45,0.45,0.78,0.55,0.67,0.81,0.69,0.91,0.87,0.73,0.51,0.89,0.95,0.9,0.57,0.82,0.75,0.84,0.62,0.59,0.66,0.96,0.94,0.72,0.92,0.61,0.55,0.64,0.72,0.93,0.88,0.82,0.98,0.72,0.78,0.82,0.89,0.59,0.59,0.95,0.46,0.69,0.5,0.89,0.52,0.55,0.51,0.73,0.97,0.72,0.64,0.78,1,0.74,0.74,0.83,0.96,0.67,0.56,0.46,0.55,0.89,0.88,0.84,0.81,0.98,1,0.8,0.63,0.74,0.43,0.69,0.97,0.53,0.84,0.68,0.89,0.29,0.81,0.78,0.58,0.55,0.69,0.78,0.48,0.87,0.84,0.73,0.7,0.75,0.84,0.76,0.74,0.77,0.68,0.85,0.65,0.48,0.97,0.58,0.87,0.76,0.76,0.95,0.62,0.54,0.66,0.86,0.87,0.29,0.84,0.83,0.78,0.97,0.88,0.81,0.92,0.7,0.58,0.89,0.83,0.75,0.8,0.77,0.72,0.57,0.95,0.488,34.184,33.146,23.481,3.761,0,0,0,0,0,0,0,5.879,3.939,0.345,0.511,0.354,0.379,0.377,0.459,0.377,0.387,0,0.373,0,0,0,0,1.397,2.892,6.376,1.151,1.124,4.075,6.354,1.216,2.66,0.08,0,0.328,0.247,0,0,0,0,0,0,0.382,0.382,0.382,0.382,0.382,0.382,0.382,0.382,0.382,0.382,0.382,0.384,0,0,0,0,0,0,5.391,6.074,11.138,2.615,11.579,5.433,8.767,6.514,14.179,6.083,0.436,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.84,0.72,0.99,0.99,0.47,0.82,0.63,0.93,0.87,0.85,0.86,0.52,0.73,0.9,0.79,0.7,0.49,0.53,0.92,0.58,0.84,0.94,0.77,0.69,0.67,0.76,0.87,0.69,0.94,0.95,0.77,0.86,0.73,0.84,0.89,0.9,0.43,0.61,0.81,0.96,0.88,0.72,0.54,0.93,0.76,0.78,0.35,0.35,0.7,0.49,0.85,0.57,0.64,0.85,0.74,0.91,0.82,0.81,0.56,0.8,0.65,0.69,0.7,0.74,0.97,0.75,0.75,0.73,0.78,0.71,0.77,0.41,0.62,0.61,0.58,0.88,0.76,0.68,0.82,0.69,0.74,0.83,0.75,0.91,0.77,0.75,0.41,0.48,0.97,1,0.8,0.6,0.58,0.82,0.6,0.75,0.7,0.75,0.73,0.78,0.72,0.74,0.58,0.37,0.92,0.76,0.83,0.78,0.83,0.5,0.64,0.67,0.78,0.92,0.9,0.54,0.59,0.64,0.71,0.69,0.7,0.79,0.6,0.67,0.83,0.86,0.6,0.85,0.71,0.63,0.85,0.45,0.98,0.72,0.91,0.95,0.78,0.8,0.46,0.69,0.64,0.89,0.81,0.81,0.87,0.85,0.81,0.6,1,0.71,0.74,0.85,0.94,0.84,0.82,0.59,0.7,0.53,0.58,0.3,0.81,0.89,0.56,0.58,0.75,0.87,0.71,0.48,0.58,0.81,0.78,0.82,0.46,0.81,0.65,1,0.85,0.69,0.77,0.67,0.75,0.85,0.54,0.9,0.45,0.88,0.95,0.38,0.57,0.99,1,0.89,0.61,0.71,0.49,0.68,0.87,0.62,0.57,0.74,0.88,0.89,0.56,0.48,1,0.47,0.809,44.961,55.577,41.08,42.991,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.73,0.49,0.8,0.83,0.55,0.67,0.57,0.76,0.89,0.8,0.95,0.57,0.96,0.61,0.5,0.64,0.77,0.79,0.77,0.8,0.92,0.44,0.55,0.71,0.6,0.83,0.63,1,0.42,0.62,0.8,0.72,0.82,0.78,0.86,0.87,0.92,0.91,0.59,0.83,0.62,0.64,0.98,0.3,0.83,0.58,0.82,0.48,0.93,0.3,0.71,0.95,0.82,0.41,0.69,0.94,0.54,0.63,0.55,0.73,0.86,0.75,0.72,0.93,0.67,0.41,0.57,0.92,0.4,0.83,0.74,0.97,0.76,0.91,0.75,0.44,0.87,1,0.8,0.74,0.91,0.25,0.52,0.72,1,0.6,0.82,0.55,0.54,0.73,0.75,0.72,0.56,0.92,0.29,0.78,0.64,0.64,0.83,0.56,0.49,0.74,0.73,0.72,0.53,0.59,0.69,0.87,0.54,0.66,0.75,0.74,0.39,0.75,0.81,0.53,0.83,0.65,0.61,0.41,0.64,0.73,0.49,0.65,0.39,0.49,0.42,0.53,0.79,0.81,0.65,0.72,0.63,0.52,0.54,0.93,0.71,0.59,0.45,0.62,0.8,0.47,0.89,0.9,0.61,0.82,0.64,0.93,0.91,0.72,0.65,0.59,0.71,0.52,0.84,0.85,0.62,0.58,0.56,0.47,0.68,0.56,0.37,0.62,0.71,0.99,0.35,0.71,0.69,0.86,0.87,0.67,0.94,0.63,0.85,0.9,0.53,0.24,0.78,0.58,0.5,0.98,0.99,0.53,0.83,0.8,0.47,0.74,0.91,0.74,0.98,0.75,0.98,0.86,0.85,0.54,0.46,0.71,0.86,0.93,0.8,0.36,0.65,0.61,0.58,0.62,0.628,23.993,10.735,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.67,0.82,0.78,0.66,0.93,0.34,0.57,0.75,0.75,0.81,0.65,0.86,0.73,0.75,0.79,0.88,0.49,0.42,0.56,0.55,0.55,0.95,0.8,0.82,0.75,0.66,0.71,0.84,0.76,0.94,0.56,0.74,0.97,0.54,0.67,0.79,0.44,0.53,0.81,0.53,0.56,0.6,0.79,0.84,0.51,0.47,0.52,0.78,0.84,0.71,0.47,0.77,0.76,0.74,0.73,0.81,0.77,0.95,0.94,0.37,0.74,0.68,0.8,0.77,0.84,0.52,0.83,0.87,0.79,0.65,0.77,0.87,0.59,0.41,0.91,0.48,0.85,0.67,0.77,0.79,0.76,0.72,0.67,0.73,0.49,0.64,0.99,0.68,0.69,0.53,0.5,0.6,0.51,0.69,0.7,0.77,0.69,0.52,0.65,0.84,0.65,0.59,0.88,0.83,0.62,0.55,0.88,0.62,0.93,0.64,0.76,0.77,0.71,0.97,0.9,0.36,0.86,0.17,0.58,0.83,0.89,0.78,0.78,0.52,0.65,0.58,0.7,0.31,0.93,0.97,0.77,0.88,0.58,0.85,0.71,0.77,0.83,0.47,0.62,0.75,0.63,0.81,0.62,0.83,0.5,0.71,0.71,0.48,0.77,0.94,0.88,0.78,0.57,0.43,0.42,0.52,0.41,0.59,0.71,0.34,0.84,0.82,0.84,0.95,0.94,0.84,0.64,0.38,0.71,0.56,0.66,0.71,0.8,0.61,0.88,0.86,0.74,0.98,1,0.79,0.84,0.78,0.9,0.8,0.89,0.4,0.44,0.72,0.94,0.76,0.76,0.83,0.68,0.97,0.4,0.74,0.65,0.59,0.7,0.66,0.79,0.5,0.7,0.39,0.44,0.94,0.771,34.692,31.463,25.639,3.029,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.97,0.59,0.83,0.81,0.51,0.76,0.45,0.88,0.83,0.87,0.78,0.96,0.74,0.83,0.66,0.74,0.68,0.67,0.78,0.64,0.45,0.52,0.68,0.51,0.85,0.97,0.6,0.69,0.99,0.98,1,0.72,0.68,0.71,0.69,0.41,0.45,0.74,1,0.4,0.55,0.9,0.82,0.93,0.98,0.78,0.88,0.69,0.72,0.75,0.61,0.88,0.8,0.44,0.79,0.44,0.62,0.78,0.87,0.89,0.56,0.87,0.69,0.81,0.76,0.75,0.75,0.83,0.66,0.43,0.75,0.77,0.89,0.64,0.78,0.72,0.67,0.61,0.73,0.64,0.91,1,0.82,0.82,0.81,0.58,0.62,0.81,0.52,0.87,0.86,0.8,0.96,0.86,0.74,0.67,0.68,0.9,0.94,0.74,0.62,0.82,0.89,0.55,0.75,0.6,0.92,0.75,0.78,0.69,0.53,0.82,0.54,0.95,0.54,0.68,0.41,0.79,0.82,0.64,0.72,0.96,0.9,0.84,0.89,0.66,0.73,0.54,0.86,0.73,0.8,0.67,0.63,0.77,0.86,0.54,0.38,0.89,0.92,0.5,0.39,0.62,0.88,0.87,0.76,0.51,0.77,0.81,0.84,0.83,0.71,0.48,0.78,0.63,0.71,0.63,0.99,0.68,0.39,0.58,0.94,0.87,0.49,0.83,0.66,0.76,0.51,0.71,0.49,0.67,0.7,0.79,0.94,0.61,0.76,0.37,0.8,0.83,0.56,0.73,0.88,1,0.66,0.88,0.74,0.92,0.7,0.69,0.78,0.79,0.41,0.6,0.73,0.73,0.92,0.77,0.7,0.54,0.4,1,0.51,0.5,0.94,0.59,0.87,0.81,0.866];
% %     BestCost=24239363221.0283;
%     bestXTimeScen{OptScenarioNum}=bestXTime
%     bestXBuyScen{OptScenarioNum}=bestXBuy
%     BestCostScen{OptScenarioNum}=BestCost
%     ZoneStartDate=[];
%     a=1;
%     for n = 1:NumTask
%         datestart = LDT+round(bestXTime(n));
%         ZoneStartDate=[ZoneStartDate datestart];
%     end
% 
% 
% 
%     %%%%create ifc file
%     [MainIFCFile,path]=uigetfile('*.ifc');
%     address =string(path)+ string(MainIFCFile);
%     ifcmain = fopen(address,'rt');
%     lineofmainIFC = textscan(ifcmain, '%s', 'delimiter', '\n');
%     fclose(ifcmain);
%     last_line  = textscan(lineofmainIFC{1}{end-3},'%s', 'delimiter', '=');
%     LastHashtagNumb=str2double(last_line{1}{1}(2:end));
%     IFCwithTimeLine = fopen("IFCwithTimeDataScenario"+OptScenarioNum+".ifc",'w');
%     for l = 1:numel(lineofmainIFC{1})-3
%         fprintf(IFCwithTimeLine,'%s\n',lineofmainIFC{1}{l});
%     end
% 
%     templastlineNum= LastHashtagNumb;
%     TaskLineNumber=[];
%     for n= 1:NumTask
%         startdd=day(ZoneStartDate(n));
%         startmm=month(ZoneStartDate(n));
%         startyy=year(ZoneStartDate(n));
%         enddd=day(ZoneStartDate(n)+D(n)-1);
%         endmm=month(ZoneStartDate(n)+D(n)-1);
%         endyy=year(ZoneStartDate(n)+D(n)-1);
%         %start date
%         fprintf(IFCwithTimeLine,'#%d= IFCCALENDARDATE(%d,%d,%d);\n',templastlineNum+1,startdd,startmm,startyy);
%         fprintf(IFCwithTimeLine,'#%d= IFCLOCALTIME(8,0,$,$,$);\n',templastlineNum+2);
%         fprintf(IFCwithTimeLine,'#%d= IFCDATEANDTIME(#%d,#%d);\n',templastlineNum+3,templastlineNum+1,templastlineNum+2);
%         %end date
%         fprintf(IFCwithTimeLine,'#%d= IFCCALENDARDATE(%d,%d,%d);\n',templastlineNum+4,enddd,endmm,endyy);
%         fprintf(IFCwithTimeLine,'#%d= IFCLOCALTIME(17,0,$,$,$);\n',templastlineNum+5);
%         fprintf(IFCwithTimeLine,'#%d= IFCDATEANDTIME(#%d,#%d);\n',templastlineNum+6,templastlineNum+4,templastlineNum+5);
%         %define task
%         txtTask="'Construct Zone "+n+"'";
%         fprintf(IFCwithTimeLine,'#%d= IFCTASK($,$,%s,$,$,%s,$,$,.F.,$);\n',templastlineNum+7,txtTask,"'"+n+"'");
%         TaskLineNumber(n)=templastlineNum+7;
%         fprintf(IFCwithTimeLine,'#%d= IFCSCHEDULETIMECONTROL($,$,$,$,$,$,$,$,#%d,$,$,$,#%d,$,$,$,$,$,$,$,$,$,$);\n',templastlineNum+8,templastlineNum+3,templastlineNum+6);
% 
%         if Predecessors{n}{1}=="Nothing"
%             lenPred=0;
%         else
%             lenPred=numel(Predecessors{n});
%             for p=1:numel(Predecessors{n})
%                 temp=textscan(Predecessors{n}{p},'%s','Delimiter',',');
%                 taskID=str2num((temp{1}{1}));
%                 rel=temp{1}{2};
%                 lag=str2num(temp{1}{3});
%                 if rel=="FS"
%                     fprintf(IFCwithTimeLine,'#%d= IFCRELSEQUENCE($,$,$,$,#%d,#%d,%d,.FINISH_START.);\n',templastlineNum+8+p,TaskLineNumber(taskID),TaskLineNumber(n),lag*24*60*60);
%                 elseif rel=="SS"
%                     fprintf(IFCwithTimeLine,'#%d= IFCRELSEQUENCE($,$,$,$,#%d,#%d,%d,.START_START.);\n',templastlineNum+8+p,TaskLineNumber(taskID),TaskLineNumber(n),lag*24*60*60);
%                 elseif rel=="FF"
%                     fprintf(IFCwithTimeLine,'#%d= IFCRELSEQUENCE($,$,$,$,#%d,#%d,%d,.FINISH_FINISH.);\n',templastlineNum+8+p,TaskLineNumber(taskID),TaskLineNumber(n),lag*24*60*60);
%                 elseif rel=="SF"
%                     fprintf(IFCwithTimeLine,'#%d= IFCRELSEQUENCE($,$,$,$,#%d,#%d,%d,.START_FINISH.);\n',templastlineNum+8+p,TaskLineNumber(taskID),TaskLineNumber(n),lag*24*60*60);
%                 end
%             end
%         end
% 
%         fprintf(IFCwithTimeLine,'#%d= IFCRELASSIGNSTASKS($,$,$,$,(#%d),$,$,#%d);\n',templastlineNum+lenPred+9,TaskLineNumber(n),templastlineNum+8);
%         %define object to task
%         objectInZone="";
%         for i = 1:numel(ElementInZone{n})
%             if i == 1
%                 objectInZone=ElementInZone{n}{i};
%             else
%                 objectInZone=objectInZone+","+ElementInZone{n}{i};
%             end
%         end
%         fprintf(IFCwithTimeLine,'#%d= IFCRELASSIGNSTOPROCESS($,$,$,$,(%s),$,#%d,$);\n',templastlineNum+lenPred+10,objectInZone,TaskLineNumber(n));
%         templastlineNum = templastlineNum+lenPred+10;
%     end
%     for l = numel(lineofmainIFC{1})-2:numel(lineofmainIFC{1})
%         fprintf(IFCwithTimeLine,'%s\n',lineofmainIFC{1}{l});
%     end
%     fclose(IFCwithTimeLine);
% 
%     %%%%%%%%%%%%%%%%%%%%
%     
%     
%     %Mizane Kharid Mat m dar roze t 
%     DQ=zeros(NumMaterial,Duration);
%     BQ1=zeros(NumMaterial,Duration);
%     BQ2=zeros(NumMaterial,Duration);
%     for m = 1:NumMaterial
%         for t = 1:Duration
%             BQ1(m,t) = bestXBuy((((2*m)+1-3)*(Duration))+t)*1000*(bestXBuy((((2*m)+2-3)*(Duration))+t));
%             BQ2(m,t) = bestXBuy((((2*m)+1-3)*(Duration))+t)*1000*(1-bestXBuy((((2*m)+2-3)*(Duration))+t));
%         end   
%     end
%     
%     for m=1:NumMaterial
%         for t= 1:Duration
%             if t-MatPro{m}{4}>=0
%                 DQ(m,t)= DQ(m,t) + BQ1(m,t-MatPro{m}{4}+1) + BQ2(m,t-MatPro{m}{4}+1);
%             end
%         end
%     end
% 
%     MRP = zeros(NumMaterial,Duration);
%     Q=[];
%     for t = 1:Duration
%     % dar har roz yek matrix q ba tedad satre barabar ba material va sotone
%     % barabar ba tedad failat ha ijad mikonim ta mizane morede niaz material
%     % moshakhas shavad
%         Q{t}=zeros(NumMaterial,NumTask);
%         for n = 1:NumTask
%             if (bestXTime(n)<=t) && (t<=bestXTime(n)+D(n)-1)
%                 for m = 1:NumMaterial
%                     Q{t}(m,n) = Q{t}(m,n) + UQ(m,n)* MatPro{m}{9};
%                 end
%             end 
%         end
%         for m = 1:NumMaterial
%            for n = 1:NumTask
%                MRP(m,t) = MRP(m,t) + Q{t}(m,n);
%            end
%         end
%     end
%     SQ=zeros(NumMaterial,Duration);
%     
%     for m = 1:NumMaterial
%         for t = 1:Duration
%              if t==1
%                  SQ(m,t) = MatPro{m}{3} + (DQ(m,t)/ MatPro{m}{9});
%              else
%                  SQ(m,t) = SQ(m,t-1) + (DQ(m,t)/MatPro{m}{9}) - (MRP(m,t-1)/MatPro{m}{9});
%              end     
%         end
%     end
% 
%    
%     OC=zeros(NumMaterial,Duration);
%     
%     for t =1:Duration
%         for m = 1:NumMaterial
%             UnitPriceP1 = 0;
%             UnitPriceP1Find = 0;
%             UnitPriceP21 = 0;
%             UnitPriceP21Find = 0;
%             UnitPriceP22 = 0;
%             UnitPriceP22Find = 0;
%             RateAtT0 = 0;
%             RateAtDelta = 0;
% 
%             for i = 1:numel(MatCost{m})
%                 if (UnitPriceP1Find == 0)&&(MatCost{m}{i}{1} <= BQ1(m,t)) && (MatCost{m}{i}{2} >= BQ1(m,t))&& (BQ1(m,t)>0)
%                     UnitPriceP1 = MatCost{m}{i}{3}; 
%                     UnitPriceP1Find = 1;
%                 end
%                 if (UnitPriceP21Find == 0)&&(MatCost{m}{i}{1} <= BQ2(m,t)) && (MatCost{m}{i}{2} >= BQ2(m,t))&&(BQ2(m,t)>0)
%                     UnitPriceP21 = MatCost{m}{i}{4}; 
%                     RateAtT0 = MatCost{m}{i}{5};
%                     UnitPriceP21Find = 1;
%                 end
%            
%                 if (UnitPriceP22Find == 0)&&((t - MatPro{m}{5}) > 0) && (MatCost{m}{i}{1} <= BQ2(m,t- MatPro{m}{5})) && (MatCost{m}{i}{2} >= BQ2(m,t- MatPro{m}{5}))&&(BQ2(m,t- MatPro{m}{5})>0)
%                     UnitPriceP22 = MatCost{m}{i}{4};
%                     RateAtDelta = MatCost{m}{i}{6};
%                     UnitPriceP22Find = 1;
%                 end
%                 
%             end
%             if (t - MatPro{m}{5}) > 0
%                 OC(m,t)=(BQ2(m,t) * UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(t-1))) + (BQ2(m,t- MatPro{m}{5}) *  UnitPriceP22 * RateAtDelta * ((1+MatPro{m}{6})^(t-MatPro{m}{5}-1))) + (BQ1(m,t)  * UnitPriceP1 * ((1+MatPro{m}{6})^(t-1)));
%             else
%                 OC(m,t)=(BQ2(m,t) * UnitPriceP21 * RateAtT0 * ((1+MatPro{m}{6})^(t-1))) + (BQ1(m,t) * UnitPriceP1 * ((1+MatPro{m}{6})^(t-1))); 
%             end
% 
%         end
%     end
%     DC=zeros(NumMaterial,Duration);
%     for t =1:Duration
%         for m = 1:NumMaterial
%             if DQ(m,t) ~=0
%                 DeliveryCost = 0;
%                 for i = 1:numel( MatCost{m})
%                     if (MatCost{m}{i}{1} <= DQ(m,t)) && (MatCost{m}{i}{2} >= DQ(m,t))
%                         DeliveryCost = MatCost{m}{i}{7};  
%                     end
%                 end
%                 DC(m,t)= DeliveryCost * ((1+TFR)^(t));
%             end
%         end
%     end
% 
%     SC=zeros(NumMaterial,Duration);
%     for t =1:Duration
%         for m = 1:NumMaterial
%             if SQ(m,t)>0
%                 SC(m,t) = SQ(m,t) * MatPro{m}{7};
%             end
%         end
%     end
%     
%     if (bestXTime(NumTask)+D(NumTask)) >(days(DDPC-LDT)+1)
%         temp_dif_T = string(bestXTime(NumTask)+D(NumTask) - (days(DDPC-LDT)+1));
%         temp=textscan(temp_dif_T,'%f');
%         Diff = double(temp{1});
%         DFP = Diff * DPC;
%     else
%         DFP=0;
%     end
% 
%     %part5:mojidi mali
%     FI=[];
%     for t =1:Duration
%         Temp_total_cost_t = 0;
%         for m = 1:NumMaterial
%             Temp_total_cost_t = Temp_total_cost_t + OC(m,t) + DC(m,t) + SC(m,t) ;
%         end
%         if t == 1
%             FI(t) = B(t) - Temp_total_cost_t;
%         elseif t == Duration
%             FI(t) = (FI(t-1)*(1)) + B(t) - Temp_total_cost_t - DFP;
%         else
%             FI(t) = (FI(t-1)*(1)) + B(t) - Temp_total_cost_t;
%         end
%     end
%     
%     
%     conn= database('DataBase','admin','admin');
%     [r c]=size(BQ1);
%     for row = 1:r
%         for col = 1:c
%             if BQ1(row,col)~=0
%                 data = table([row],[datetime(LDT+days(col))],[BQ1(row,col)],["KG"],'VariableNames',{'IDMaterial','BuyDate','Quantity','Unit'});  
%                 coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
%                 sqlwrite(conn,"__BQ1_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);
% 
%             end
%         end
%     end
% 
%     
%     [r c]=size(BQ2);
%     for row = 1:r
%         for col = 1:c
%             if BQ2(row,col)~=0
%                 data = table([row],[datetime(LDT+days(col))],[BQ2(row,col)],["KG"],'VariableNames',{'IDMaterial','BuyDate','Quantity','Unit'});  
%                 coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
%                 sqlwrite(conn,"__BQ2_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);
% 
%             end
%         end
%     end
%     
%     
%     for n = 1:NumTask
%         data = table([n],[ZoneStartDate(n)],'VariableNames',{'IDZone','StartDate'});  
%         coltypes = ["INTEGER" "DATE"];
%         sqlwrite(conn,"__StartDateZones_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);
%     end
% 
% 
%     [r c]=size(DQ);
%     for row = 1:r
%         for col = 1:c
%             if DQ(row,col)~=0
%                 data = table([row],[datetime(LDT+days(col))],[DQ(row,col)],["KG"],'VariableNames',{'IDMaterial','DeliveryDate','Quantity','Unit'});  
%                 coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
%                 sqlwrite(conn,"__DQ_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);
% 
%             end
%         end
%     end
% 
%     [r c]=size(OC);
%     for row = 1:r
%         for col = 1:c
%             if OC(row,col)~=0
%                 data = table([row],[datetime(LDT+days(col))],[OC(row,col)],["Toman"],'VariableNames',{'IDMaterial','PaymentDate','Quantity','Unit'});  
%                 coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
%                 sqlwrite(conn,"__OC_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);
% 
%             end
%         end
%     end
% 
%     [r c]=size(DC);
%     for row = 1:r
%         for col = 1:c
%             if DC(row,col)~=0
%                 data = table([row],[datetime(LDT+days(col))],[DC(row,col)],["Toman"],'VariableNames',{'IDMaterial','PaymentDate','Quantity','Unit'});  
%                 coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
%                 sqlwrite(conn,"__DC_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);
% 
%             end
%         end
%     end
% 
%     [r c]=size(SC);
%     for row = 1:r
%         for col = 1:c
%             if SC(row,col)~=0
%                 data = table([row],[datetime(LDT+days(col))],[SC(row,col)],["Toman"],'VariableNames',{'IDMaterial','PaymentDate','Quantity','Unit'});  
%                 coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
%                 sqlwrite(conn,"__SC_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);
% 
%             end
%         end
%     end
%     
%     [r c]=size(SQ);
%     for row = 1:r
%         for col = 1:c
%                 data = table([row],[datetime(LDT+days(col)-1)],[SQ(row,col)],["Cubic_Metre"],'VariableNames',{'IDMaterial','DayDate','Quantity','Unit'});  
%                 coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
%                 sqlwrite(conn,"__SQ_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);
% 
%            
%         end
%     end
%     
%     [r c]=size(MRP);
%     for row = 1:r
%         for col = 1:c
%                 data = table([row],[datetime(LDT+days(col)-1)],[MRP(row,col)],["KG"],'VariableNames',{'IDMaterial','DayDate','Quantity','Unit'});  
%                 coltypes = ["DOUBLE" "DATE" "DOUBLE" "LONGTEXT" ];
%                 sqlwrite(conn,"__MRP_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);
% 
%            
%         end
%     end
%     
%     
%     for t =1:Duration
%         data = table([t],[datetime(LDT+days(t)-1)],[FI(t)],["TOMAN"],'VariableNames',{'ID','DayDate','FinancialBalance','Unit'});  
%         coltypes = ["INTEGER" "DATE" "DOUBLE" "LONGTEXT" ];
%         sqlwrite(conn,"__FI_Scenario"+OptScenarioNum+"__",data,'ColumnType',coltypes);
%     end
%     
% 
%     close(conn)
% 
% 
% end
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
